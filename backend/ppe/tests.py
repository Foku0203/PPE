from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .exceptions import BusinessRuleError
from .models import (
    ApprovalDecision,
    AuditLog,
    Notification,
    NotificationType,
    PpeItem,
    PpeTranslation,
    RequisitionStatus,
    Role,
    SerialStatus,
    StockLot,
    User,
)
from .services import approval_inbox, approve_requisition, create_requisition, issue_requisition, receive_stock, reserve_and_prepare


class BaseFixture(TestCase):
    def setUp(self):
        self.admin = User.objects.create_user(username='admin', password='pass', employee_id='ADM001', display_name='Admin', role=Role.ADMIN)
        self.supervisor = User.objects.create_user(username='sup', password='pass', employee_id='SUP001', display_name='Supervisor', role=Role.SUPERVISOR)
        self.other_supervisor = User.objects.create_user(username='sup2', password='pass', employee_id='SUP002', display_name='Other Supervisor', role=Role.SUPERVISOR)
        self.ehs = User.objects.create_user(username='ehs', password='pass', employee_id='EHS001', display_name='EHS', role=Role.EHS)
        self.store = User.objects.create_user(username='store', password='pass', employee_id='STO001', display_name='Store', role=Role.STORE_KEEPER)
        self.worker = User.objects.create_user(username='worker', password='pass', employee_id='EMP001', display_name='Worker', supervisor=self.supervisor)
        self.worker2 = User.objects.create_user(username='worker2', password='pass', employee_id='EMP002', display_name='Worker 2', supervisor=self.other_supervisor)
        self.item = PpeItem.objects.create(code='PPE-HAR', icon_key='harness', unit='set', quota=1, lifespan_days=365, reorder_point=2, requires_serial=True, is_returnable=True)
        for locale, name in [('TH', 'สายรัดนิรภัย'), ('EN', 'Safety Harness'), ('MY', 'ပြုတ်ကျမှုကာကွယ်ရေး ခါးပတ်')]:
            PpeTranslation.objects.create(ppe_item=self.item, locale=locale, name=name)
        self.lot = StockLot.objects.create(ppe_item=self.item, lot_number='LOT-01', serial_number='HAR-001', quantity=1, inspected_at=timezone.now())
        self.gloves = PpeItem.objects.create(code='PPE-GLV', icon_key='gloves', unit='pair', quota=4, lifespan_days=90, reorder_point=5, sizes='M,L')
        PpeTranslation.objects.create(ppe_item=self.gloves, locale='EN', name='Gloves')
        self.gloves_lot = StockLot.objects.create(ppe_item=self.gloves, lot_number='GLV-01', quantity=10)

    def client_for(self, user):
        client = APIClient()
        client.force_authenticate(user)
        return client

    def request(self, **kwargs):
        defaults = {'requester': self.worker, 'client_request_id': f'req-{timezone.now().timestamp()}',
                    'items': [{'ppe_item_id': self.item.id, 'quantity': 1, 'reason': 'DAMAGED'}]}
        defaults.update(kwargs)
        return create_requisition(**defaults)


class PpeWorkflowTests(BaseFixture):
    def test_normal_request_full_flow_issue_and_reorder_alert(self):
        request = self.request(client_request_id='mobile-1')
        self.assertEqual(request.status, RequisitionStatus.PENDING)
        self.assertTrue(Notification.objects.filter(notification_type=NotificationType.NEW_REQUISITION, recipient=self.supervisor).exists())
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.APPROVED)
        reserve_and_prepare(requisition_id=request.id, actor=self.store)
        issue_requisition(requisition_id=request.id, actor=self.store, serial_numbers=['HAR-001'])
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.COMPLETED)
        self.lot.refresh_from_db()
        self.assertEqual((self.lot.quantity, self.lot.reserved_quantity, self.lot.serial_status), (0, 0, SerialStatus.ISSUED))
        self.assertTrue(Notification.objects.filter(notification_type=NotificationType.REORDER_POINT).exists())
        self.assertTrue(AuditLog.objects.filter(action='ISSUE', entity_id=str(request.id)).exists())

    def test_duplicate_active_request_is_rejected(self):
        self.request(client_request_id='mobile-2')
        with self.assertRaises(BusinessRuleError) as ctx:
            self.request(client_request_id='mobile-3')
        self.assertEqual(ctx.exception.error_code, 'ACTIVE_REQUEST_EXISTS')

    def test_idempotent_client_request_id_returns_same_requisition(self):
        first = self.request(client_request_id='same-key')
        second = self.request(client_request_id='same-key')
        self.assertEqual(first.pk, second.pk)

    def test_special_request_requires_reason_and_both_approvals(self):
        items = [{'ppe_item_id': self.item.id, 'quantity': 2, 'reason': 'DAMAGED'}]
        with self.assertRaises(BusinessRuleError) as ctx:
            self.request(client_request_id='special-0', items=items)
        self.assertEqual(ctx.exception.error_code, 'SPECIAL_REASON_REQUIRED')
        request = self.request(client_request_id='special-1', items=items, special_reason='Lost during rescue drill')
        self.assertEqual(request.status, RequisitionStatus.SPECIAL)
        with self.assertRaises(BusinessRuleError):  # EHS waits for the supervisor step
            approve_requisition(requisition=request, approver=self.ehs, decision=ApprovalDecision.APPROVED)
        self.assertFalse(approval_inbox(self.ehs).filter(pk=request.pk).exists())
        approve_requisition(requisition=request, approver=self.supervisor, decision=ApprovalDecision.APPROVED)
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.SPECIAL)
        self.assertTrue(approval_inbox(self.ehs).filter(pk=request.pk).exists())
        approve_requisition(requisition=request, approver=self.ehs, decision=ApprovalDecision.APPROVED)
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.APPROVED)

    def test_always_special_item_needs_special_approval_for_any_role(self):
        self.item.always_special_approval = True
        self.item.save()
        with self.assertRaises(BusinessRuleError) as ctx:
            self.request(client_request_id='fall-0')
        self.assertEqual(ctx.exception.error_code, 'SPECIAL_REASON_REQUIRED')
        for requester in [self.worker, self.supervisor, self.ehs, self.store]:
            request = self.request(requester=requester, client_request_id=f'fall-{requester.pk}', special_reason='Work at height')
            self.assertEqual((request.status, request.special_approval_needed), (RequisitionStatus.SPECIAL, True))
        gloves = self.request(client_request_id='fall-glv', items=[{'ppe_item_id': self.gloves.id, 'quantity': 1, 'reason': 'DAMAGED', 'size': 'M'}])
        self.assertEqual(gloves.status, RequisitionStatus.PENDING)

    def test_lifespan_blocks_early_replacement(self):
        request = self.request(client_request_id='life-1')
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        reserve_and_prepare(requisition_id=request.id, actor=self.store)
        issue_requisition(requisition_id=request.id, actor=self.store)
        receive_stock(ppe_item=self.item, actor=self.store, quantity=1, serial_numbers=['HAR-002'])
        with self.assertRaises(BusinessRuleError):
            self.request(client_request_id='life-2')
        early = self.request(client_request_id='life-3', special_reason='Harness failed inspection')
        self.assertTrue(early.special_approval_needed)
        self.assertIsNotNone(early.items.first().eligible_at)

    def test_supervisor_cannot_approve_other_team_or_self(self):
        request = self.request(requester=self.worker2, client_request_id='team-1')
        with self.assertRaises(BusinessRuleError) as ctx:
            approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        self.assertEqual(ctx.exception.error_code, 'NOT_ALLOWED_TO_APPROVE')
        own = self.request(requester=self.supervisor, client_request_id='own-1', items=[{'ppe_item_id': self.gloves.id, 'quantity': 1, 'reason': 'LOST', 'size': 'M'}])
        with self.assertRaises(BusinessRuleError):
            approve_requisition(requisition=own, approver=self.supervisor, decision='APPROVED')

    def test_reject_requires_reason(self):
        request = self.request(client_request_id='rej-1')
        with self.assertRaises(BusinessRuleError):
            approve_requisition(requisition=request, approver=self.supervisor, decision='REJECTED')
        approve_requisition(requisition=request, approver=self.supervisor, decision='REJECTED', reason='Not needed')
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.REJECTED)

    def test_insufficient_stock_puts_request_on_hold_then_resumes(self):
        request = self.request(client_request_id='hold-1', items=[{'ppe_item_id': self.gloves.id, 'quantity': 4, 'reason': 'DAMAGED', 'size': 'L'}])
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        self.gloves_lot.quantity = 2
        self.gloves_lot.save()
        result = reserve_and_prepare(requisition_id=request.id, actor=self.store)
        self.assertEqual(result.status, RequisitionStatus.ON_HOLD)
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.ON_HOLD)  # persisted, not rolled back
        receive_stock(ppe_item=self.gloves, actor=self.store, quantity=10)
        result = reserve_and_prepare(requisition_id=request.id, actor=self.store)
        self.assertEqual(result.status, RequisitionStatus.READY)

    def test_expired_lots_are_not_reserved(self):
        self.gloves_lot.expiry_at = timezone.now() - timedelta(days=1)
        self.gloves_lot.save()
        request = self.request(client_request_id='exp-1', items=[{'ppe_item_id': self.gloves.id, 'quantity': 1, 'reason': 'DAMAGED', 'size': 'M'}])
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        self.assertEqual(reserve_and_prepare(requisition_id=request.id, actor=self.store).status, RequisitionStatus.ON_HOLD)

    def test_size_is_required_when_item_has_sizes(self):
        with self.assertRaises(BusinessRuleError) as ctx:
            self.request(client_request_id='size-1', items=[{'ppe_item_id': self.gloves.id, 'quantity': 1, 'reason': 'DAMAGED'}])
        self.assertEqual(ctx.exception.error_code, 'SIZE_REQUIRED')

    def test_serial_mismatch_blocks_issue(self):
        request = self.request(client_request_id='serial-1')
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        reserve_and_prepare(requisition_id=request.id, actor=self.store)
        with self.assertRaises(BusinessRuleError) as ctx:
            issue_requisition(requisition_id=request.id, actor=self.store, serial_numbers=['WRONG'])
        self.assertEqual(ctx.exception.error_code, 'SERIAL_MISMATCH')


class ApiTests(BaseFixture):
    def test_employee_id_login_returns_jwt_and_error_envelope(self):
        self.worker.set_password('secret-pass')
        self.worker.save(update_fields=['password'])
        response = APIClient().post('/api/v1/auth/token/', {'employee_id': 'emp001', 'password': 'secret-pass'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)
        self.assertEqual(response.data['user']['employee_id'], 'EMP001')
        bad = APIClient().post('/api/v1/auth/token/', {'employee_id': 'EMP001', 'password': 'nope'}, format='json')
        self.assertEqual(bad.status_code, 401)
        self.assertFalse(bad.data['success'])
        self.assertEqual(bad.data['error']['code'], 'INVALID_CREDENTIALS')

    def test_register_creates_worker_and_refresh_logout(self):
        client = APIClient()
        response = client.post('/api/v1/auth/register/', {'employee_id': 'emp100', 'display_name': 'New', 'password': 'longpassword',
                                                          'supervisor_employee_id': 'SUP001', 'locale': 'MY'}, format='json')
        self.assertEqual(response.status_code, 201, response.data)
        user = User.objects.get(employee_id='EMP100')
        self.assertEqual((user.role, user.supervisor, user.locale), (Role.WORKER, self.supervisor, 'MY'))
        refresh = response.data['refresh']
        rotated = client.post('/api/v1/auth/token/refresh/', {'refresh': refresh}, format='json')
        self.assertEqual(rotated.status_code, 200)
        client.credentials(HTTP_AUTHORIZATION='Bearer ' + rotated.data['access'])
        self.assertEqual(client.post('/api/v1/auth/logout/', {'refresh': rotated.data['refresh']}, format='json').status_code, 200)
        client.credentials()
        self.assertEqual(client.post('/api/v1/auth/token/refresh/', {'refresh': rotated.data['refresh']}, format='json').status_code, 401)
        duplicate = client.post('/api/v1/auth/register/', {'employee_id': 'EMP100', 'display_name': 'X', 'password': 'longpassword'}, format='json')
        self.assertEqual(duplicate.status_code, 400)

    def test_admin_transfers_team_before_supervisor_leaves(self):
        admin = self.client_for(self.admin)
        request = self.request(client_request_id='move-1')
        blocked = admin.patch(f'/api/v1/users/{self.supervisor.id}/', {'is_active': False}, format='json')
        self.assertEqual(blocked.status_code, 400)
        self.assertEqual(admin.patch(f'/api/v1/users/{self.supervisor.id}/', {'role': 'WORKER'}, format='json').status_code, 400)
        self.assertEqual(self.client_for(self.ehs).post(f'/api/v1/users/{self.supervisor.id}/transfer-team/', {'to_supervisor': self.other_supervisor.id}).status_code, 403)
        self.assertEqual(admin.post(f'/api/v1/users/{self.supervisor.id}/transfer-team/', {'to_supervisor': self.ehs.id}).status_code, 400)
        moved = admin.post(f'/api/v1/users/{self.supervisor.id}/transfer-team/', {'to_supervisor': self.other_supervisor.id}, format='json')
        self.assertEqual(moved.data['moved'], 1)
        self.worker.refresh_from_db()
        self.assertEqual(self.worker.supervisor, self.other_supervisor)
        self.assertTrue(approval_inbox(self.other_supervisor).filter(pk=request.pk).exists())
        self.assertEqual(admin.patch(f'/api/v1/users/{self.supervisor.id}/', {'is_active': False}, format='json').status_code, 200)

    def test_supervisor_sees_issued_items_of_own_team_only(self):
        url = '/api/v1/me/issued-items/?user_id={}'
        self.assertEqual(self.client_for(self.supervisor).get(url.format(self.worker.id)).status_code, 200)
        self.assertEqual(self.client_for(self.supervisor).get(url.format(self.worker2.id)).status_code, 404)
        self.assertEqual(self.client_for(self.store).get(url.format(self.worker2.id)).status_code, 200)

    def test_register_requires_supervisor_from_public_list(self):
        client = APIClient()
        options = client.get('/api/v1/auth/supervisors/')
        self.assertEqual(options.status_code, 200)
        self.assertIn('SUP001', [o['employee_id'] for o in options.data])
        self.assertNotIn('EHS001', [o['employee_id'] for o in options.data])
        missing = client.post('/api/v1/auth/register/', {'employee_id': 'EMP200', 'display_name': 'N', 'password': 'longpassword'}, format='json')
        self.assertEqual(missing.status_code, 400)
        not_supervisor = client.post('/api/v1/auth/register/', {'employee_id': 'EMP200', 'display_name': 'N', 'password': 'longpassword',
                                                               'supervisor_employee_id': self.ehs.employee_id}, format='json')
        self.assertEqual(not_supervisor.status_code, 400)

    def test_catalog_localized_and_eligibility(self):
        response = self.client_for(self.worker).get('/api/v1/catalog/ppe/?locale=TH')
        self.assertEqual(response.status_code, 200)
        harness = next(i for i in response.data if i['code'] == 'PPE-HAR')
        self.assertEqual(harness['name'], 'สายรัดนิรภัย')
        self.assertEqual(harness['stock'], 1)
        eligibility = self.client_for(self.worker).get(f'/api/v1/catalog/ppe/{self.item.id}/eligibility/?quantity=2')
        self.assertTrue(eligibility.data['special_approval_required'])
        self.assertEqual(eligibility.data['reason'], 'QUOTA_EXCEEDED')

    def test_catalog_write_requires_master_data_permission_and_reason(self):
        url = f'/api/v1/catalog/ppe/{self.gloves.id}/'
        self.assertEqual(self.client_for(self.worker).patch(url, {'quota': 9}, format='json').status_code, 403)
        self.assertEqual(self.client_for(self.ehs).patch(url, {'quota': 9}, format='json').status_code, 400)
        response = self.client_for(self.ehs).patch(url, {'quota': 9, 'change_reason': 'Policy update'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['quota'], 9)
        self.assertTrue(AuditLog.objects.filter(entity='PpeItem', action='UPDATE').exists())

    def test_worker_cannot_see_other_requests_or_approve(self):
        other = self.request(requester=self.worker2, client_request_id='priv-1')
        client = self.client_for(self.worker)
        self.assertEqual(client.get(f'/api/v1/requisitions/{other.id}/').status_code, 404)
        self.assertEqual(client.post(f'/api/v1/requisitions/{other.id}/approvals/', {'decision': 'APPROVED'}, format='json').status_code, 403)
        self.assertEqual(client.get('/api/v1/inventory/lots/').status_code, 403)
        self.assertEqual(client.get('/api/v1/audit-logs/').status_code, 403)

    def test_create_via_api_uses_idempotency_header(self):
        client = self.client_for(self.worker)
        body = {'items': [{'ppe_item_id': self.gloves.id, 'quantity': 2, 'reason': 'DAMAGED', 'size': 'M'}]}
        first = client.post('/api/v1/requisitions/', body, format='json', HTTP_IDEMPOTENCY_KEY='abc-123')
        second = client.post('/api/v1/requisitions/', body, format='json', HTTP_IDEMPOTENCY_KEY='abc-123')
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(first.data['id'], second.data['id'])
        self.assertTrue(first.data['actions']['can_cancel'])
        dup = client.post('/api/v1/requisitions/', body, format='json', HTTP_IDEMPOTENCY_KEY='other-key')
        self.assertEqual(dup.status_code, 409)
        self.assertEqual(dup.data['error']['code'], 'ACTIVE_REQUEST_EXISTS')

    def test_inbox_request_info_and_approval_via_api(self):
        request = self.request(client_request_id='inbox-1')
        sup = self.client_for(self.supervisor)
        inbox = sup.get('/api/v1/requisitions/?scope=inbox')
        self.assertEqual([r['id'] for r in inbox.data['results']], [request.id])
        self.assertTrue(inbox.data['results'][0]['actions']['can_approve'])
        self.assertEqual(self.client_for(self.other_supervisor).get('/api/v1/requisitions/?scope=inbox').data['count'], 0)
        info = sup.post(f'/api/v1/requisitions/{request.id}/approvals/', {'decision': 'REQUEST_INFO', 'reason': 'Photo of damage?'}, format='json')
        self.assertEqual(info.status_code, 200)
        self.assertEqual(len(info.data['comments']), 1)
        reply = self.client_for(self.worker).post(f'/api/v1/requisitions/{request.id}/comments/', {'message': 'Strap torn'}, format='json')
        self.assertEqual(len(reply.data['comments']), 2)
        approved = sup.post(f'/api/v1/requisitions/{request.id}/approvals/', {'decision': 'APPROVED'}, format='json')
        self.assertEqual(approved.data['status'], RequisitionStatus.APPROVED)

    def test_store_prepare_pickup_qr_issue_and_return(self):
        request = self.request(client_request_id='qr-1')
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        store = self.client_for(self.store)
        self.assertEqual(store.post(f'/api/v1/requisitions/{request.id}/prepare/').data['status'], RequisitionStatus.READY)
        self.assertEqual(self.client_for(self.worker).post(f'/api/v1/requisitions/{request.id}/prepare/').status_code, 403)
        qr = self.client_for(self.worker).post(f'/api/v1/requisitions/{request.id}/pickup-qr/')
        token = qr.data['token']
        self.assertTrue(token.startswith('PPE1:'))
        resolved = store.post('/api/v1/inventory/scan/resolve/', {'token': token}, format='json')
        self.assertEqual(resolved.data['requisition_id'], request.id)
        wrong = store.post(f'/api/v1/requisitions/{request.id}/issue/', {'qr_token': token, 'serial_numbers': ['WRONG']}, format='json')
        self.assertEqual(wrong.data['error']['code'], 'SERIAL_MISMATCH')  # QR must survive a failed issue
        issued = store.post(f'/api/v1/requisitions/{request.id}/issue/', {'qr_token': token, 'serial_numbers': ['HAR-001']}, format='json')
        self.assertEqual(issued.status_code, 200, issued.data)
        self.assertEqual(issued.data['status'], RequisitionStatus.COMPLETED)
        replay = store.post('/api/v1/inventory/scan/resolve/', {'token': token}, format='json')
        self.assertEqual(replay.data['error']['code'], 'QR_INVALID')
        line_id = issued.data['items'][0]['id']
        returned = store.post(f'/api/v1/requisition-items/{line_id}/return/', {'condition': 'GOOD'}, format='json')
        self.assertTrue(returned.data['items'][0]['is_returned'])
        self.lot.refresh_from_db()
        self.assertEqual((self.lot.quantity, self.lot.serial_status), (1, SerialStatus.AVAILABLE))

    def test_cancel_ready_request_releases_reservation(self):
        request = self.request(client_request_id='cancel-1')
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        reserve_and_prepare(requisition_id=request.id, actor=self.store)
        self.lot.refresh_from_db()
        self.assertEqual(self.lot.reserved_quantity, 1)
        response = self.client_for(self.worker).post(f'/api/v1/requisitions/{request.id}/cancel/')
        self.assertEqual(response.data['status'], RequisitionStatus.CANCELLED)
        self.lot.refresh_from_db()
        self.assertEqual(self.lot.reserved_quantity, 0)

    def test_receive_adjust_and_summary(self):
        store = self.client_for(self.store)
        response = store.post('/api/v1/inventory/lots/', {'ppe_item_id': self.item.id, 'quantity': 2, 'serial_numbers': ['HAR-010']}, format='json')
        self.assertEqual(response.data['error']['code'], 'SERIAL_REQUIRED')
        response = store.post('/api/v1/inventory/lots/', {'ppe_item_id': self.gloves.id, 'quantity': 20, 'lot_number': 'GLV-02'}, format='json')
        self.assertEqual(response.status_code, 201)
        lot_id = response.data[0]['id']
        bad = store.post(f'/api/v1/inventory/lots/{lot_id}/adjust/', {'delta': -50, 'reason': 'count'}, format='json')
        self.assertEqual(bad.data['error']['code'], 'NEGATIVE_STOCK')
        ok = store.post(f'/api/v1/inventory/lots/{lot_id}/adjust/', {'delta': 3, 'reason': 'damaged', 'event_type': 'DAMAGE'}, format='json')
        self.assertEqual(ok.data['quantity'], 17)
        summary = store.get('/api/v1/inventory/summary/')
        gloves = next(r for r in summary.data if r['code'] == 'PPE-GLV')
        self.assertEqual(gloves['stock'], 27)

    def test_purchase_request_lifecycle(self):
        ehs = self.client_for(self.ehs)
        created = ehs.post('/api/v1/purchase-requests/', {'ppe_item': self.gloves.id, 'requested_quantity': 50, 'reason': 'Low stock'}, format='json')
        self.assertEqual(created.status_code, 201, created.data)
        pr_id = created.data['id']
        store = self.client_for(self.store)
        self.assertEqual(store.post(f'/api/v1/purchase-requests/{pr_id}/status/', {'status': 'RECEIVED'}, format='json').status_code, 409)
        for step in ['APPROVED', 'ORDERED']:
            self.assertEqual(store.post(f'/api/v1/purchase-requests/{pr_id}/status/', {'status': step}, format='json').data['status'], step)
        store.post('/api/v1/inventory/lots/', {'ppe_item_id': self.gloves.id, 'quantity': 50, 'purchase_request_id': pr_id}, format='json')
        self.assertEqual(store.get('/api/v1/purchase-requests/').data['results'][0]['status'], 'RECEIVED')

    def test_dashboard_is_role_scoped(self):
        self.request(client_request_id='dash-1')
        self.request(requester=self.worker2, client_request_id='dash-2')
        self.assertEqual(self.client_for(self.supervisor).get('/api/v1/dashboard/summary/').data['pending_approval'], 1)
        self.assertEqual(self.client_for(self.admin).get('/api/v1/dashboard/summary/').data['pending_approval'], 2)
        worker = self.client_for(self.worker).get('/api/v1/dashboard/summary/').data
        self.assertEqual(worker['my_open'], 1)
        self.assertEqual(len(worker['recent']), 1)

    def test_notifications_read_all_and_admin_user_update(self):
        self.request(client_request_id='notif-1')
        sup = self.client_for(self.supervisor)
        listed = sup.get('/api/v1/notifications/')
        self.assertEqual(listed.data['unread_count'], 1)
        sup.post('/api/v1/notifications/read-all/')
        self.assertEqual(sup.get('/api/v1/notifications/unread-count/').data['unread_count'], 0)
        self.assertEqual(sup.patch(f'/api/v1/users/{self.worker.id}/', {'role': 'ADMIN'}, format='json').status_code, 403)
        response = self.client_for(self.admin).patch(f'/api/v1/users/{self.worker.id}/', {'role': 'STORE_KEEPER'}, format='json')
        self.assertEqual(response.data['role'], 'STORE_KEEPER')
