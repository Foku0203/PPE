import hashlib
import os
import secrets
from datetime import timedelta
from uuid import uuid4

from django.conf import settings
from django.db import transaction
from django.db.models import F, Q, Sum
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from .models import Approval, ApprovalDecision, ApprovalKind, AuditLog, DevicePlatform, DeviceToken, Notification, NotificationType, PpeItem, QRChallenge, Requisition, RequisitionStatus, StockEvent, StockEventType, StockLot, SerialStatus, User, Role

ACTIVE_REQUEST_STATUSES = [RequisitionStatus.PENDING, RequisitionStatus.SPECIAL, RequisitionStatus.APPROVED, RequisitionStatus.READY]


def notify_users(*, users, notification_type: str, title: str, message: str, payload: dict | None = None) -> None:
    Notification.objects.bulk_create([
        Notification(recipient=user, notification_type=notification_type, title=title, message=message, payload=payload or {})
        for user in users
    ])


def notify_reorder_if_needed(*, ppe_item: PpeItem) -> None:
    available = StockLot.objects.filter(ppe_item=ppe_item).aggregate(total=Sum(F('quantity') - F('reserved_quantity')))['total'] or 0
    if available <= ppe_item.reorder_point:
        recipients = User.objects.filter(role__in=[Role.STORE_KEEPER, Role.EHS, Role.ADMIN], is_active=True)
        notify_users(notification_type=NotificationType.REORDER_POINT, title=f'Reorder alert: {ppe_item.code}', message=f'Available stock is {available}, at or below reorder point {ppe_item.reorder_point}.', payload={'ppe_item_id': ppe_item.id, 'available': available, 'reorder_point': ppe_item.reorder_point}, users=recipients)


def _last_issue(requester: User, ppe_item: PpeItem):
    return StockEvent.objects.filter(receiver=requester, event_type=StockEventType.ISSUE, stock_lot__ppe_item=ppe_item).order_by('-created_at').first()


def evaluate_line(requester: User, ppe_item: PpeItem, quantity: int, now=None) -> dict:
    now = now or timezone.now()
    if Requisition.objects.filter(requester=requester, status__in=ACTIVE_REQUEST_STATUSES, items__ppe_item=ppe_item).exists():
        return {'allowed': False, 'special_approval_required': False, 'reason': 'ACTIVE_REQUEST_EXISTS'}
    last_issue = _last_issue(requester, ppe_item)
    eligible_at = None
    if last_issue and ppe_item.lifespan_days:
        eligible_at = last_issue.created_at + timedelta(days=ppe_item.lifespan_days)
    lifespan_blocked = bool(eligible_at and eligible_at > now)
    quota_blocked = ppe_item.quota is not None and quantity > ppe_item.quota
    return {
        'allowed': not lifespan_blocked and not quota_blocked,
        'special_approval_required': lifespan_blocked or quota_blocked,
        'eligible_at': eligible_at,
        'reason': 'LIFESPAN_NOT_EXPIRED' if lifespan_blocked else 'QUOTA_EXCEEDED' if quota_blocked else None,
    }


def create_requisition(*, requester: User, client_request_id: str, items: list[dict]) -> Requisition:
    with transaction.atomic():
        existing = Requisition.objects.filter(requester=requester, client_request_id=client_request_id).first()
        if existing:
            return existing
        checked = []
        for item in items:
            ppe_item = PpeItem.objects.select_for_update().get(pk=item['ppe_item_id'], active=True)
            result = evaluate_line(requester, ppe_item, item['quantity'])
            if result['reason'] == 'ACTIVE_REQUEST_EXISTS':
                raise ValidationError({'items': f'Active request already exists for {ppe_item.code}.'})
            checked.append((item, ppe_item, result))
        special = any(result['special_approval_required'] for _, _, result in checked)
        requisition = Requisition.objects.create(
            request_no=f'PR-{timezone.now():%y%m%d}-{uuid4().hex[:6].upper()}', requester=requester,
            client_request_id=client_request_id, special_approval_needed=special,
            status=RequisitionStatus.SPECIAL if special else RequisitionStatus.PENDING,
        )
        for item, ppe_item, result in checked:
            requisition.items.create(ppe_item=ppe_item, size=item.get('size', ''), quantity=item['quantity'], reason=item['reason'], eligible_at=result.get('eligible_at'))
        AuditLog.objects.create(actor=requester, action='CREATE', entity='Requisition', entity_id=str(requisition.pk), after={'status': requisition.status})
        recipients = list(User.objects.filter(Q(role__in=[Role.EHS, Role.ADMIN], is_active=True))[:100])
        if requester.supervisor_id:
            recipients.append(requester.supervisor)
        notify_users(users={user.id: user for user in recipients}.values(), notification_type=NotificationType.NEW_REQUISITION, title=f'New requisition {requisition.request_no}', message=f'{requester.display_name} submitted a PPE requisition.', payload={'requisition_id': requisition.id, 'status': requisition.status})
        return requisition


def approve_requisition(*, requisition: Requisition, approver: User, decision: str, reason: str = '') -> Requisition:
    with transaction.atomic():
        requisition = Requisition.objects.select_for_update().select_related('requester').get(pk=requisition.pk)
        if decision not in ApprovalDecision.values:
            raise ValidationError({'decision': 'Decision must be APPROVED or REJECTED.'})
        if requisition.status in [RequisitionStatus.COMPLETED, RequisitionStatus.REJECTED, RequisitionStatus.CANCELLED]:
            raise ValidationError({'status': 'This requisition can no longer be approved.'})
        if requisition.special_approval_needed:
            if approver.role == Role.SUPERVISOR:
                kind = ApprovalKind.SPECIAL_SUPERVISOR
            elif approver.role in [Role.EHS, Role.ADMIN]:
                kind = ApprovalKind.SPECIAL_EHS
            else:
                raise ValidationError({'approver': 'Special approval requires Supervisor and EHS/Admin.'})
        else:
            if approver.role != Role.SUPERVISOR and approver.role not in [Role.EHS, Role.ADMIN]:
                raise ValidationError({'approver': 'Supervisor, EHS or Admin approval is required.'})
            kind = ApprovalKind.NORMAL
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
        AuditLog.objects.create(actor=approver, action='APPROVE' if decision == ApprovalDecision.APPROVED else 'REJECT', entity='Requisition', entity_id=str(requisition.pk), after={'status': requisition.status, 'kind': kind})
        notify_users(users=[requisition.requester], notification_type=NotificationType.APPROVAL_RESULT, title=f'Requisition {requisition.request_no} updated', message=f'The requisition status is now {requisition.status}.', payload={'requisition_id': requisition.id, 'status': requisition.status})
        return requisition


def reserve_and_prepare(*, requisition_id: int, actor: User) -> Requisition:
    with transaction.atomic():
        requisition = Requisition.objects.select_for_update().prefetch_related('items').get(pk=requisition_id)
        if requisition.status != RequisitionStatus.APPROVED:
            raise ValidationError({'status': 'Only approved requisitions can be prepared.'})
        for item in requisition.items.all():
            available = StockLot.objects.filter(ppe_item=item.ppe_item, serial_status=SerialStatus.AVAILABLE).aggregate(total=Sum(F('quantity') - F('reserved_quantity')))['total'] or 0
            if available < item.quantity:
                requisition.status = RequisitionStatus.ON_HOLD
                requisition.save(update_fields=['status', 'updated_at'])
                raise ValidationError({'stock': f'Insufficient stock for {item.ppe_item.code}.'})
            remaining = item.quantity
            for lot in StockLot.objects.select_for_update().filter(ppe_item=item.ppe_item, serial_status=SerialStatus.AVAILABLE).order_by('expiry_at', 'id'):
                take = min(remaining, lot.available_quantity)
                if take:
                    StockLot.objects.filter(pk=lot.pk).update(reserved_quantity=F('reserved_quantity') + take)
                    StockEvent.objects.create(requisition=requisition, stock_lot=lot, event_type=StockEventType.RESERVE, quantity=take, issuer=actor)
                    remaining -= take
                if remaining == 0:
                    break
        requisition.status = RequisitionStatus.READY
        requisition.save(update_fields=['status', 'updated_at'])
        notify_users(users=[requisition.requester], notification_type=NotificationType.READY_FOR_PICKUP, title=f'{requisition.request_no} is ready', message='Your PPE is ready for pickup.', payload={'requisition_id': requisition.id, 'status': requisition.status})
        return requisition


def issue_requisition(*, requisition_id: int, actor: User, serial_numbers: list[str] | None = None) -> Requisition:
    with transaction.atomic():
        requisition = Requisition.objects.select_for_update().prefetch_related('items').get(pk=requisition_id)
        if requisition.status != RequisitionStatus.READY:
            raise ValidationError({'status': 'Only ready requisitions can be issued.'})
        serial_numbers = serial_numbers or []
        serial_index = 0
        for item in requisition.items.all():
            lots = list(StockLot.objects.select_for_update().filter(ppe_item=item.ppe_item, reserved_quantity__gt=0, serial_status__in=[SerialStatus.AVAILABLE, SerialStatus.RESERVED]).order_by('expiry_at', 'id'))
            remaining = item.quantity
            for lot in lots:
                if lot.serial_number and serial_numbers and lot.serial_number not in serial_numbers:
                    continue
                take = 1 if lot.serial_number else min(remaining, lot.reserved_quantity)
                if take:
                    StockLot.objects.filter(pk=lot.pk).update(quantity=F('quantity') - take, reserved_quantity=F('reserved_quantity') - take, serial_status=SerialStatus.ISSUED if lot.serial_number else F('serial_status'))
                    StockEvent.objects.create(requisition=requisition, stock_lot=lot, event_type=StockEventType.ISSUE, quantity=take, issuer=actor, receiver=requisition.requester, metadata={'serial': lot.serial_number, 'lot': lot.lot_number})
                    notify_reorder_if_needed(ppe_item=item.ppe_item)
                    remaining -= take
                if remaining == 0:
                    break
            if remaining:
                raise ValidationError({'stock': f'Could not issue all units for {item.ppe_item.code}.'})
        requisition.status = RequisitionStatus.COMPLETED
        requisition.save(update_fields=['status', 'updated_at'])
        AuditLog.objects.create(actor=actor, action='ISSUE', entity='Requisition', entity_id=str(requisition.pk), after={'status': requisition.status})
        return requisition


def create_qr_challenge(*, purpose: str, user: User | None = None, requisition: Requisition | None = None) -> tuple[str, QRChallenge]:
    raw_token = secrets.token_urlsafe(32)
    challenge = QRChallenge.objects.create(token_hash=hashlib.sha256(raw_token.encode()).hexdigest(), purpose=purpose, user=user, requisition=requisition, expires_at=timezone.now() + timedelta(minutes=int(os.getenv('QR_TOKEN_MINUTES', '5'))))
    return raw_token, challenge
