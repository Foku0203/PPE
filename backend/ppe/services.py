import hashlib
import os
import secrets
from datetime import timedelta
from uuid import uuid4

from django.db import transaction
from django.db.models import F, Q, Sum
from django.db.models.functions import Coalesce
from django.utils import timezone

from .exceptions import BusinessRuleError
from .models import (
    Approval,
    ApprovalDecision,
    ApprovalKind,
    AuditLog,
    Notification,
    NotificationType,
    PpeItem,
    QRChallenge,
    Requisition,
    RequisitionComment,
    RequisitionItem,
    RequisitionStatus,
    Role,
    SerialStatus,
    StockEvent,
    StockEventType,
    StockLot,
    User,
)
from .push import send_push

ACTIVE_REQUEST_STATUSES = [RequisitionStatus.PENDING, RequisitionStatus.SPECIAL, RequisitionStatus.APPROVED, RequisitionStatus.READY, RequisitionStatus.ON_HOLD]
APPROVABLE_STATUSES = [RequisitionStatus.PENDING, RequisitionStatus.SPECIAL]
CLOSED_STATUSES = [RequisitionStatus.COMPLETED, RequisitionStatus.REJECTED, RequisitionStatus.CANCELLED]
APPROVER_ROLES = [Role.SUPERVISOR, Role.EHS, Role.ADMIN]
STORE_ROLES = [Role.STORE_KEEPER, Role.EHS, Role.ADMIN]
QR_PREFIX = 'PPE1:'


def approval_sla_hours() -> int:
    return int(os.getenv('APPROVAL_SLA_HOURS', '24'))


# ---------------------------------------------------------------------------
# Notifications & audit
# ---------------------------------------------------------------------------

def notify_users(*, users, notification_type: str, title: str, message: str, payload: dict | None = None) -> None:
    unique = {user.id: user for user in users if user is not None and user.is_active}
    created = Notification.objects.bulk_create([
        Notification(recipient=user, notification_type=notification_type, title=title, message=message, payload=payload or {})
        for user in unique.values()
    ])
    transaction.on_commit(lambda: send_push(created))


def audit(*, actor: User | None, action: str, entity: str, entity_id, before=None, after=None, request_id: str = '') -> None:
    AuditLog.objects.create(actor=actor, action=action, entity=entity, entity_id=str(entity_id), before=before, after=after, request_id=request_id or '')


def _users_with_roles(roles):
    return list(User.objects.filter(role__in=roles, is_active=True)[:200])


def _requisition_payload(requisition: Requisition) -> dict:
    return {'requisition_id': requisition.id, 'request_no': requisition.request_no, 'status': requisition.status}


# ---------------------------------------------------------------------------
# Stock helpers
# ---------------------------------------------------------------------------

def _usable_lots(ppe_item: PpeItem):
    now = timezone.now()
    return StockLot.objects.filter(ppe_item=ppe_item, serial_status=SerialStatus.AVAILABLE).filter(Q(expiry_at__isnull=True) | Q(expiry_at__gt=now))


def available_stock(ppe_item: PpeItem) -> int:
    return _usable_lots(ppe_item).aggregate(total=Coalesce(Sum(F('quantity') - F('reserved_quantity')), 0))['total']


def notify_reorder_if_needed(*, ppe_item: PpeItem) -> None:
    available = available_stock(ppe_item)
    if available <= ppe_item.reorder_point:
        notify_users(
            users=_users_with_roles(STORE_ROLES),
            notification_type=NotificationType.REORDER_POINT,
            title=f'Reorder alert: {ppe_item.code}',
            message=f'Available stock is {available}, at or below reorder point {ppe_item.reorder_point}.',
            payload={'ppe_item_id': ppe_item.id, 'code': ppe_item.code, 'available': available, 'reorder_point': ppe_item.reorder_point},
        )


# ---------------------------------------------------------------------------
# Eligibility (quota / lifespan / anti-duplicate)
# ---------------------------------------------------------------------------

def last_issue(requester: User, ppe_item: PpeItem):
    return StockEvent.objects.filter(receiver=requester, event_type=StockEventType.ISSUE, stock_lot__ppe_item=ppe_item).order_by('-created_at').first()


def evaluate_line(requester: User, ppe_item: PpeItem, quantity: int, now=None) -> dict:
    now = now or timezone.now()
    if not ppe_item.active:
        return {'allowed': False, 'special_approval_required': False, 'reason': 'ITEM_INACTIVE', 'eligible_at': None}
    if Requisition.objects.filter(requester=requester, status__in=ACTIVE_REQUEST_STATUSES, items__ppe_item=ppe_item).exists():
        return {'allowed': False, 'special_approval_required': False, 'reason': 'ACTIVE_REQUEST_EXISTS', 'eligible_at': None}
    previous = last_issue(requester, ppe_item)
    eligible_at = previous.created_at + timedelta(days=ppe_item.lifespan_days) if previous and ppe_item.lifespan_days else None
    lifespan_blocked = bool(eligible_at and eligible_at > now)
    quota_blocked = ppe_item.quota is not None and quantity > ppe_item.quota
    return {
        'allowed': not lifespan_blocked and not quota_blocked,
        'special_approval_required': lifespan_blocked or quota_blocked,
        'eligible_at': eligible_at,
        'last_issued_at': previous.created_at if previous else None,
        'reason': 'LIFESPAN_NOT_EXPIRED' if lifespan_blocked else 'QUOTA_EXCEEDED' if quota_blocked else None,
    }


# ---------------------------------------------------------------------------
# Requisition lifecycle
# ---------------------------------------------------------------------------

def create_requisition(*, requester: User, client_request_id: str, items: list[dict], special_reason: str = '') -> Requisition:
    with transaction.atomic():
        existing = Requisition.objects.filter(requester=requester, client_request_id=client_request_id).first()
        if existing:
            return existing
        seen = set()
        checked = []
        for item in items:
            if item['ppe_item_id'] in seen:
                raise BusinessRuleError('DUPLICATE_LINE', 'The same PPE item appears more than once.', 400)
            seen.add(item['ppe_item_id'])
            ppe_item = PpeItem.objects.select_for_update().filter(pk=item['ppe_item_id']).first()
            if ppe_item is None:
                raise BusinessRuleError('ITEM_NOT_FOUND', 'PPE item not found.', 404)
            allowed_sizes = [size.strip() for size in ppe_item.sizes.split(',') if size.strip()]
            if allowed_sizes and item.get('size', '') not in allowed_sizes:
                raise BusinessRuleError('SIZE_REQUIRED', f'Select a valid size for {ppe_item.code}.', 400, {'ppe_item_id': ppe_item.id, 'sizes': allowed_sizes})
            result = evaluate_line(requester, ppe_item, item['quantity'])
            if result['reason'] in ('ACTIVE_REQUEST_EXISTS', 'ITEM_INACTIVE'):
                message = f'Active request already exists for {ppe_item.code}.' if result['reason'] == 'ACTIVE_REQUEST_EXISTS' else f'{ppe_item.code} is inactive.'
                raise BusinessRuleError(result['reason'], message, 409, {'ppe_item_id': ppe_item.id})
            checked.append((item, ppe_item, result))
        special = any(result['special_approval_required'] for _, _, result in checked)
        if special and not special_reason.strip():
            raise BusinessRuleError('SPECIAL_REASON_REQUIRED', 'A justification is required for early replacement or quantity above quota.', 400,
                                    {'lines': [{'ppe_item_id': p.id, 'reason': r['reason']} for _, p, r in checked if r['special_approval_required']]})
        requisition = Requisition.objects.create(
            request_no=f'PR-{timezone.now():%y%m%d}-{uuid4().hex[:6].upper()}', requester=requester,
            client_request_id=client_request_id, special_approval_needed=special, special_reason=special_reason.strip() if special else '',
            status=RequisitionStatus.SPECIAL if special else RequisitionStatus.PENDING,
        )
        for item, ppe_item, result in checked:
            requisition.items.create(ppe_item=ppe_item, size=item.get('size', ''), quantity=item['quantity'], reason=item['reason'], eligible_at=result.get('eligible_at'))
        audit(actor=requester, action='CREATE', entity='Requisition', entity_id=requisition.pk, after={'status': requisition.status, 'items': len(checked)}, request_id=client_request_id)
        recipients = [requester.supervisor] if requester.supervisor_id else []
        if special or not requester.supervisor_id:
            recipients += _users_with_roles([Role.EHS, Role.ADMIN])
        notify_users(users=recipients, notification_type=NotificationType.NEW_REQUISITION, title=f'New requisition {requisition.request_no}',
                     message=f'{requester.display_name} submitted a PPE requisition.', payload=_requisition_payload(requisition))
        return requisition


def approval_kind_for(requisition: Requisition, approver: User) -> str | None:
    """Returns the approval slot this user may fill for the requisition, or None."""
    if requisition.status not in APPROVABLE_STATUSES or approver.id == requisition.requester_id:
        return None
    if approver.role not in APPROVER_ROLES:
        return None
    is_team_supervisor = approver.role == Role.SUPERVISOR and requisition.requester.supervisor_id == approver.id
    if approver.role == Role.SUPERVISOR and not is_team_supervisor:
        return None
    approvals = {a.kind: a for a in requisition.approvals.all() if a.decision == ApprovalDecision.APPROVED}
    if not requisition.special_approval_needed:
        return ApprovalKind.NORMAL
    if approver.role == Role.SUPERVISOR:
        return None if ApprovalKind.SPECIAL_SUPERVISOR in approvals else ApprovalKind.SPECIAL_SUPERVISOR
    if ApprovalKind.SPECIAL_EHS not in approvals:
        return ApprovalKind.SPECIAL_EHS
    # An Admin may fill the supervisor slot (e.g. requester without supervisor) but never both slots.
    if approver.role == Role.ADMIN and ApprovalKind.SPECIAL_SUPERVISOR not in approvals and approvals[ApprovalKind.SPECIAL_EHS].approver_id != approver.id:
        return ApprovalKind.SPECIAL_SUPERVISOR
    return None


def approve_requisition(*, requisition: Requisition, approver: User, decision: str, reason: str = '') -> Requisition:
    with transaction.atomic():
        requisition = Requisition.objects.select_for_update().select_related('requester').get(pk=requisition.pk)
        if decision not in ApprovalDecision.values:
            raise BusinessRuleError('INVALID_DECISION', 'Decision must be APPROVED or REJECTED.', 400)
        if requisition.status not in APPROVABLE_STATUSES:
            raise BusinessRuleError('INVALID_STATUS', 'This requisition is not waiting for approval.')
        kind = approval_kind_for(requisition, approver)
        if kind is None:
            raise BusinessRuleError('NOT_ALLOWED_TO_APPROVE', 'You are not an approver for this requisition at its current step.', 403)
        if decision == ApprovalDecision.REJECTED and not reason.strip():
            raise BusinessRuleError('REASON_REQUIRED', 'A reason is required when rejecting.', 400)
        before = requisition.status
        Approval.objects.update_or_create(requisition=requisition, kind=kind, defaults={'approver': approver, 'decision': decision, 'reason': reason})
        if decision == ApprovalDecision.REJECTED:
            requisition.status = RequisitionStatus.REJECTED
        elif requisition.special_approval_needed:
            approved_kinds = set(requisition.approvals.filter(decision=ApprovalDecision.APPROVED).values_list('kind', flat=True))
            if {ApprovalKind.SPECIAL_SUPERVISOR, ApprovalKind.SPECIAL_EHS}.issubset(approved_kinds):
                requisition.status = RequisitionStatus.APPROVED
        else:
            requisition.status = RequisitionStatus.APPROVED
        requisition.save(update_fields=['status', 'updated_at'])
        audit(actor=approver, action='APPROVE' if decision == ApprovalDecision.APPROVED else 'REJECT', entity='Requisition', entity_id=requisition.pk,
              before={'status': before}, after={'status': requisition.status, 'kind': kind, 'reason': reason})
        notify_users(users=[requisition.requester], notification_type=NotificationType.APPROVAL_RESULT, title=f'Requisition {requisition.request_no} updated',
                     message=f'The requisition status is now {requisition.status}.', payload=_requisition_payload(requisition))
        if requisition.status == RequisitionStatus.APPROVED:
            notify_users(users=_users_with_roles([Role.STORE_KEEPER]), notification_type=NotificationType.APPROVAL_RESULT,
                         title=f'{requisition.request_no} ready to prepare', message='An approved requisition is waiting for store preparation.',
                         payload=_requisition_payload(requisition))
        elif requisition.status == RequisitionStatus.SPECIAL and kind == ApprovalKind.SPECIAL_SUPERVISOR:
            notify_users(users=_users_with_roles([Role.EHS]), notification_type=NotificationType.NEW_REQUISITION,
                         title=f'{requisition.request_no} needs EHS approval', message='Supervisor approved a special requisition.', payload=_requisition_payload(requisition))
        return requisition


def add_comment(*, requisition: Requisition, author: User, message: str, info_request: bool = False) -> RequisitionComment:
    if not message.strip():
        raise BusinessRuleError('MESSAGE_REQUIRED', 'Message is required.', 400)
    if info_request and approval_kind_for(requisition, author) is None:
        raise BusinessRuleError('NOT_ALLOWED_TO_APPROVE', 'Only the current approver can request more information.', 403)
    comment = RequisitionComment.objects.create(requisition=requisition, author=author, message=message.strip(), is_info_request=info_request)
    audit(actor=author, action='REQUEST_INFO' if info_request else 'COMMENT', entity='Requisition', entity_id=requisition.pk, after={'message': message.strip()})
    if author.id == requisition.requester_id:
        recipients = {c.author for c in requisition.comments.select_related('author').exclude(author=author)}
        if requisition.requester.supervisor_id:
            recipients.add(requisition.requester.supervisor)
        notify_users(users=recipients, notification_type=NotificationType.INFO_REQUESTED, title=f'Reply on {requisition.request_no}', message=message.strip()[:200],
                     payload=_requisition_payload(requisition))
    else:
        notify_users(users=[requisition.requester], notification_type=NotificationType.INFO_REQUESTED,
                     title=f'More information requested for {requisition.request_no}' if info_request else f'New comment on {requisition.request_no}',
                     message=message.strip()[:200], payload=_requisition_payload(requisition))
    return comment


def _release_reservations(requisition: Requisition, actor: User) -> None:
    for event in requisition.stock_events.filter(event_type=StockEventType.RESERVE):
        StockLot.objects.filter(pk=event.stock_lot_id).update(reserved_quantity=F('reserved_quantity') - event.quantity)
        StockEvent.objects.create(requisition=requisition, stock_lot=event.stock_lot, event_type=StockEventType.ADJUSTMENT, quantity=0, issuer=actor,
                                  metadata={'release': True, 'released_quantity': event.quantity})


def cancel_requisition(*, requisition: Requisition, actor: User) -> Requisition:
    with transaction.atomic():
        requisition = Requisition.objects.select_for_update().get(pk=requisition.pk)
        if requisition.status in CLOSED_STATUSES:
            raise BusinessRuleError('INVALID_STATUS', 'Cannot cancel requisition in current status.')
        if actor.id != requisition.requester_id and actor.role not in STORE_ROLES:
            raise BusinessRuleError('FORBIDDEN', 'Only the requester or store can cancel this requisition.', 403)
        before = requisition.status
        if before == RequisitionStatus.READY:
            _release_reservations(requisition, actor)
        requisition.status = RequisitionStatus.CANCELLED
        requisition.save(update_fields=['status', 'updated_at'])
        audit(actor=actor, action='CANCEL', entity='Requisition', entity_id=requisition.pk, before={'status': before}, after={'status': requisition.status})
        if actor.id != requisition.requester_id:
            notify_users(users=[requisition.requester], notification_type=NotificationType.APPROVAL_RESULT, title=f'{requisition.request_no} cancelled',
                         message='Your requisition was cancelled by the store.', payload=_requisition_payload(requisition))
        return requisition


def reserve_and_prepare(*, requisition_id: int, actor: User) -> Requisition:
    """Reserve stock FEFO for every line. Insufficient stock puts the request ON_HOLD_STOCK (not an error)."""
    with transaction.atomic():
        requisition = Requisition.objects.select_for_update().select_related('requester').prefetch_related('items__ppe_item').get(pk=requisition_id)
        if requisition.status not in [RequisitionStatus.APPROVED, RequisitionStatus.ON_HOLD]:
            raise BusinessRuleError('INVALID_STATUS', 'Only approved or on-hold requisitions can be prepared.')
        lines = list(requisition.items.all())
        short = [line for line in lines if available_stock(line.ppe_item) < line.quantity]
        if short:
            requisition.status = RequisitionStatus.ON_HOLD
            requisition.save(update_fields=['status', 'updated_at'])
            codes = ', '.join(line.ppe_item.code for line in short)
            audit(actor=actor, action='ON_HOLD', entity='Requisition', entity_id=requisition.pk, after={'status': requisition.status, 'short': codes})
            notify_users(users=[requisition.requester], notification_type=NotificationType.ON_HOLD, title=f'{requisition.request_no} is on hold',
                         message=f'Waiting for stock: {codes}.', payload=_requisition_payload(requisition))
            for line in short:
                notify_reorder_if_needed(ppe_item=line.ppe_item)
            return requisition
        for line in lines:
            remaining = line.quantity
            for lot in _usable_lots(line.ppe_item).select_for_update().order_by(F('expiry_at').asc(nulls_last=True), 'id'):
                take = min(remaining, lot.quantity - lot.reserved_quantity)
                if take <= 0:
                    continue
                StockLot.objects.filter(pk=lot.pk).update(reserved_quantity=F('reserved_quantity') + take)
                StockEvent.objects.create(requisition=requisition, stock_lot=lot, event_type=StockEventType.RESERVE, quantity=take, issuer=actor,
                                          metadata={'lot': lot.lot_number, 'serial': lot.serial_number or ''})
                remaining -= take
                if remaining == 0:
                    break
        requisition.status = RequisitionStatus.READY
        requisition.save(update_fields=['status', 'updated_at'])
        audit(actor=actor, action='PREPARE', entity='Requisition', entity_id=requisition.pk, after={'status': requisition.status})
        notify_users(users=[requisition.requester], notification_type=NotificationType.READY_FOR_PICKUP, title=f'{requisition.request_no} is ready',
                     message='Your PPE is ready for pickup.', payload=_requisition_payload(requisition))
        return requisition


def issue_requisition(*, requisition_id: int, actor: User, serial_numbers: list[str] | None = None, method: str = 'MANUAL') -> Requisition:
    """Converts this requisition's reservations into ISSUE events and deducts stock."""
    with transaction.atomic():
        requisition = Requisition.objects.select_for_update().select_related('requester').get(pk=requisition_id)
        if requisition.status != RequisitionStatus.READY:
            raise BusinessRuleError('INVALID_STATUS', 'Only ready requisitions can be issued.')
        reservations = list(requisition.stock_events.select_related('stock_lot__ppe_item').filter(event_type=StockEventType.RESERVE))
        serial_numbers = [s.strip() for s in (serial_numbers or []) if s.strip()]
        reserved_serials = [e.stock_lot.serial_number for e in reservations if e.stock_lot.serial_number]
        if serial_numbers and sorted(serial_numbers) != sorted(reserved_serials):
            raise BusinessRuleError('SERIAL_MISMATCH', 'Scanned serial numbers do not match the reserved units.', 409, {'expected': reserved_serials})
        touched_items = set()
        for event in reservations:
            lot = StockLot.objects.select_for_update().get(pk=event.stock_lot_id)
            if lot.reserved_quantity < event.quantity or lot.quantity < event.quantity:
                raise BusinessRuleError('INSUFFICIENT_STOCK', f'Reserved stock is no longer available for {lot.ppe_item.code}.')
            updates = {'quantity': F('quantity') - event.quantity, 'reserved_quantity': F('reserved_quantity') - event.quantity}
            if lot.serial_number:
                updates['serial_status'] = SerialStatus.ISSUED
            StockLot.objects.filter(pk=lot.pk).update(**updates)
            StockEvent.objects.create(requisition=requisition, stock_lot=lot, event_type=StockEventType.ISSUE, quantity=event.quantity, issuer=actor,
                                      receiver=requisition.requester, metadata={'serial': lot.serial_number or '', 'lot': lot.lot_number, 'method': method})
            touched_items.add(lot.ppe_item)
        now = timezone.now()
        for line in requisition.items.select_related('ppe_item'):
            if line.ppe_item.is_returnable and line.ppe_item.lifespan_days:
                line.return_due_date = now + timedelta(days=line.ppe_item.lifespan_days)
                line.save(update_fields=['return_due_date'])
        requisition.status = RequisitionStatus.COMPLETED
        requisition.save(update_fields=['status', 'updated_at'])
        audit(actor=actor, action='ISSUE', entity='Requisition', entity_id=requisition.pk, after={'status': requisition.status, 'method': method})
        recipients = [requisition.requester]
        if requisition.requester.supervisor_id:
            recipients.append(requisition.requester.supervisor)
        notify_users(users=recipients, notification_type=NotificationType.ISSUED, title=f'{requisition.request_no} issued',
                     message='PPE has been handed over and recorded.', payload=_requisition_payload(requisition))
        for ppe_item in touched_items:
            notify_reorder_if_needed(ppe_item=ppe_item)
        return requisition


def return_item(*, requisition_item: RequisitionItem, actor: User, condition: str = 'GOOD', note: str = '') -> RequisitionItem:
    with transaction.atomic():
        line = RequisitionItem.objects.select_for_update().select_related('requisition__requester', 'ppe_item').get(pk=requisition_item.pk)
        if line.requisition.status != RequisitionStatus.COMPLETED:
            raise BusinessRuleError('INVALID_STATUS', 'Only issued items can be returned.')
        if line.is_returned:
            raise BusinessRuleError('ALREADY_RETURNED', 'This item has already been returned.')
        if condition not in ('GOOD', 'DAMAGED'):
            raise BusinessRuleError('INVALID_CONDITION', 'Condition must be GOOD or DAMAGED.', 400)
        now = timezone.now()
        issues = list(line.requisition.stock_events.select_related('stock_lot').filter(event_type=StockEventType.ISSUE, stock_lot__ppe_item=line.ppe_item))
        for issue in issues:
            lot = issue.stock_lot
            if condition == 'GOOD':
                updates = {'quantity': F('quantity') + issue.quantity}
                if lot.serial_number:
                    updates['serial_status'] = SerialStatus.AVAILABLE
                StockLot.objects.filter(pk=lot.pk).update(**updates)
                event_type = StockEventType.RETURN
            else:
                if lot.serial_number:
                    StockLot.objects.filter(pk=lot.pk).update(serial_status=SerialStatus.DAMAGED)
                event_type = StockEventType.DAMAGE
            StockEvent.objects.create(requisition=line.requisition, stock_lot=lot, event_type=event_type, quantity=issue.quantity, issuer=actor,
                                      receiver=line.requisition.requester, metadata={'condition': condition, 'note': note, 'serial': lot.serial_number or ''})
        line.is_returned = True
        line.returned_at = now
        line.save(update_fields=['is_returned', 'returned_at'])
        audit(actor=actor, action='RETURN', entity='RequisitionItem', entity_id=line.pk, after={'condition': condition, 'note': note})
        return line


def receive_stock(*, ppe_item: PpeItem, actor: User, quantity: int, lot_number: str = '', supplier: str = '', serial_numbers: list[str] | None = None,
                  expiry_at=None, manufactured_at=None, inspected_at=None, purchase_request=None) -> list[StockLot]:
    serial_numbers = [s.strip() for s in (serial_numbers or []) if s.strip()]
    if ppe_item.requires_serial and len(serial_numbers) != quantity:
        raise BusinessRuleError('SERIAL_REQUIRED', f'{ppe_item.code} requires one serial number per unit.', 400)
    if quantity < 1:
        raise BusinessRuleError('INVALID_QUANTITY', 'Quantity must be at least 1.', 400)
    if expiry_at and expiry_at <= timezone.now():
        raise BusinessRuleError('EXPIRED_STOCK', 'Cannot receive stock that is already expired.', 400)
    if serial_numbers and StockLot.objects.filter(serial_number__in=serial_numbers).exists():
        raise BusinessRuleError('SERIAL_EXISTS', 'One or more serial numbers already exist.', 409)
    common = {'ppe_item': ppe_item, 'lot_number': lot_number, 'supplier': supplier, 'expiry_at': expiry_at, 'manufactured_at': manufactured_at,
              'inspected_at': inspected_at or (timezone.now() if ppe_item.requires_serial else None)}
    with transaction.atomic():
        lots = [StockLot.objects.create(serial_number=serial, quantity=1, **common) for serial in serial_numbers] if serial_numbers else [
            StockLot.objects.create(serial_number=None, quantity=quantity, **common)]
        for lot in lots:
            StockEvent.objects.create(stock_lot=lot, event_type=StockEventType.RECEIPT, quantity=lot.quantity, issuer=actor,
                                      metadata={'supplier': supplier, 'purchase_request': purchase_request.request_no if purchase_request else ''})
        audit(actor=actor, action='RECEIVE', entity='PpeItem', entity_id=ppe_item.pk, after={'quantity': quantity, 'lot': lot_number, 'serials': serial_numbers})
        return lots


def adjust_lot(*, lot: StockLot, actor: User, delta: int, reason: str, event_type: str = StockEventType.ADJUSTMENT) -> StockLot:
    if not reason.strip():
        raise BusinessRuleError('REASON_REQUIRED', 'A reason is required for stock adjustments.', 400)
    if event_type not in (StockEventType.ADJUSTMENT, StockEventType.DAMAGE):
        raise BusinessRuleError('INVALID_EVENT', 'Event must be ADJUSTMENT or DAMAGE.', 400)
    with transaction.atomic():
        lot = StockLot.objects.select_for_update().get(pk=lot.pk)
        if event_type == StockEventType.DAMAGE and delta > 0:
            delta = -delta
        new_quantity = lot.quantity + delta
        if new_quantity < lot.reserved_quantity or new_quantity < 0:
            raise BusinessRuleError('NEGATIVE_STOCK', 'Adjustment would make stock negative or below reserved quantity.')
        before = lot.quantity
        lot.quantity = new_quantity
        fields = ['quantity']
        if lot.serial_number and event_type == StockEventType.DAMAGE:
            lot.serial_status = SerialStatus.DAMAGED
            fields.append('serial_status')
        lot.save(update_fields=fields)
        StockEvent.objects.create(stock_lot=lot, event_type=event_type, quantity=delta, issuer=actor, metadata={'reason': reason})
        audit(actor=actor, action=event_type, entity='StockLot', entity_id=lot.pk, before={'quantity': before}, after={'quantity': new_quantity, 'reason': reason})
    notify_reorder_if_needed(ppe_item=lot.ppe_item)
    return lot


# ---------------------------------------------------------------------------
# QR challenge (pickup confirmation with replay protection)
# ---------------------------------------------------------------------------

def _hash(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


def create_qr_challenge(*, purpose: str, user: User | None = None, requisition: Requisition | None = None) -> tuple[str, QRChallenge]:
    raw_token = secrets.token_urlsafe(32)
    if requisition is not None:
        QRChallenge.objects.filter(requisition=requisition, purpose=purpose, used_at__isnull=True).update(expires_at=timezone.now())
    challenge = QRChallenge.objects.create(token_hash=_hash(raw_token), purpose=purpose, user=user, requisition=requisition,
                                           expires_at=timezone.now() + timedelta(minutes=int(os.getenv('QR_TOKEN_MINUTES', '5'))))
    return QR_PREFIX + raw_token, challenge


def resolve_qr(*, token: str) -> QRChallenge:
    raw = token.strip().removeprefix(QR_PREFIX)
    with transaction.atomic():
        challenge = QRChallenge.objects.select_for_update().select_related('requisition__requester', 'user').filter(token_hash=_hash(raw)).first()
        if not challenge or not challenge.is_usable:
            raise BusinessRuleError('QR_INVALID', 'QR token is invalid, expired, or already used.', 400)
        challenge.used_at = timezone.now()
        challenge.save(update_fields=['used_at'])
        return challenge


# ---------------------------------------------------------------------------
# Visibility & dashboard
# ---------------------------------------------------------------------------

def visible_requisitions(user: User):
    queryset = Requisition.objects.select_related('requester', 'requester__supervisor')
    if user.role == Role.WORKER:
        return queryset.filter(requester=user)
    if user.role == Role.SUPERVISOR:
        return queryset.filter(Q(requester=user) | Q(requester__supervisor=user))
    return queryset


def approval_inbox(user: User):
    base = visible_requisitions(user).filter(status__in=APPROVABLE_STATUSES).exclude(requester=user)
    if user.role == Role.SUPERVISOR:
        return base.filter(requester__supervisor=user).exclude(approvals__kind=ApprovalKind.SPECIAL_SUPERVISOR, approvals__decision=ApprovalDecision.APPROVED)
    if user.role == Role.EHS:
        return base.filter(Q(special_approval_needed=True) | Q(requester__supervisor__isnull=True)).exclude(
            approvals__kind=ApprovalKind.SPECIAL_EHS, approvals__decision=ApprovalDecision.APPROVED)
    if user.role == Role.ADMIN:
        return base
    return base.none()


def replacement_due(user: User) -> list[dict]:
    """PPE the user holds whose lifespan has elapsed and that has no open request."""
    now = timezone.now()
    result = []
    item_ids = StockEvent.objects.filter(receiver=user, event_type=StockEventType.ISSUE).values_list('stock_lot__ppe_item', flat=True).distinct()
    for ppe_item in PpeItem.objects.filter(pk__in=item_ids, active=True, lifespan_days__isnull=False):
        previous = last_issue(user, ppe_item)
        due_at = previous.created_at + timedelta(days=ppe_item.lifespan_days)
        if due_at <= now and not Requisition.objects.filter(requester=user, status__in=ACTIVE_REQUEST_STATUSES, items__ppe_item=ppe_item).exists():
            result.append({'ppe_item_id': ppe_item.id, 'code': ppe_item.code, 'due_at': due_at})
    return result


def low_stock_items(limit: int | None = None) -> list[dict]:
    now = timezone.now()
    usable = Q(stock_lots__serial_status=SerialStatus.AVAILABLE) & (Q(stock_lots__expiry_at__isnull=True) | Q(stock_lots__expiry_at__gt=now))
    rows = (PpeItem.objects.filter(active=True)
            .annotate(available=Coalesce(Sum(F('stock_lots__quantity') - F('stock_lots__reserved_quantity'), filter=usable), 0))
            .filter(available__lte=F('reorder_point')).order_by('available'))
    rows = rows[:limit] if limit else rows
    return [{'ppe_item_id': r.id, 'code': r.code, 'available': r.available, 'reorder_point': r.reorder_point} for r in rows]


def dashboard_summary(user: User) -> dict:
    now = timezone.now()
    scope = visible_requisitions(user)
    mine = Requisition.objects.filter(requester=user)
    inbox = approval_inbox(user)
    sla_cutoff = now - timedelta(hours=approval_sla_hours())
    data = {
        'role': user.role,
        'my_open': mine.filter(status__in=ACTIVE_REQUEST_STATUSES).count(),
        'my_ready': mine.filter(status=RequisitionStatus.READY).count(),
        'my_completed': mine.filter(status=RequisitionStatus.COMPLETED).count(),
        'replacement_due': replacement_due(user),
        'pending_approval': inbox.count(),
        'overdue_approval': inbox.filter(created_at__lt=sla_cutoff).count(),
        'to_prepare': scope.filter(status=RequisitionStatus.APPROVED).count() if user.role in STORE_ROLES else 0,
        'on_hold': scope.filter(status=RequisitionStatus.ON_HOLD).count(),
        'ready_for_pickup': scope.filter(status=RequisitionStatus.READY).count(),
        'completed_today': scope.filter(status=RequisitionStatus.COMPLETED, updated_at__date=timezone.localdate()).count(),
        'open_requisitions': scope.filter(status__in=ACTIVE_REQUEST_STATUSES).count(),
        'low_stock': low_stock_items(5) if user.role in STORE_ROLES else [],
    }
    data['low_stock_items'] = len(low_stock_items()) if user.role in STORE_ROLES else 0
    if user.role in [Role.SUPERVISOR, Role.EHS, Role.ADMIN]:
        workers = User.objects.filter(is_active=True, role=Role.WORKER)
        if user.role == Role.SUPERVISOR:
            workers = workers.filter(supervisor=user)
        workers = list(workers)
        overdue = sum(1 for worker in workers if replacement_due(worker))
        data['compliance'] = {'workers': len(workers), 'workers_replacement_due': overdue,
                              'rate': round(100 * (len(workers) - overdue) / len(workers), 1) if workers else 100.0}
    return data
