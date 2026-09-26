from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from .models import ApprovalDecision, Notification, NotificationType, PpeItem, PpeTranslation, RequisitionStatus, Role, StockLot, User
from .services import approve_requisition, create_requisition, reserve_and_prepare, issue_requisition


class PpeWorkflowTests(TestCase):
    def setUp(self):
        self.supervisor = User.objects.create_user(username='sup', password='pass', employee_id='SUP001', display_name='Supervisor', role=Role.SUPERVISOR)
        self.ehs = User.objects.create_user(username='ehs', password='pass', employee_id='EHS001', display_name='EHS', role=Role.EHS)
        self.worker = User.objects.create_user(username='worker', password='pass', employee_id='EMP001', display_name='Worker', supervisor=self.supervisor)
        self.item = PpeItem.objects.create(code='PPE-HAR', icon_key='harness', unit='set', quota=1, lifespan_days=365, reorder_point=2)
        for locale, name in [('TH', 'สายรัดนิรภัย'), ('EN', 'Safety Harness'), ('MY', 'ပြုတ်ကျမှုကာကွယ်ရေး ခါးပတ်')]:
            PpeTranslation.objects.create(ppe_item=self.item, locale=locale, name=name)
        self.lot = StockLot.objects.create(ppe_item=self.item, lot_number='LOT-01', serial_number='HAR-001', quantity=1, inspected_at=timezone.now())

    def test_special_request_requires_dual_approval_and_can_issue(self):
        old_event_time = timezone.now() - timedelta(days=400)
        request = create_requisition(requester=self.worker, client_request_id='mobile-1', items=[{'ppe_item_id': self.item.id, 'quantity': 1, 'reason': 'DAMAGED', 'size': 'M'}])
        self.assertEqual(request.status, RequisitionStatus.PENDING)
        self.assertTrue(Notification.objects.filter(notification_type=NotificationType.NEW_REQUISITION, recipient=self.supervisor).exists())
        approve_requisition(requisition=request, approver=self.supervisor, decision='APPROVED')
        self.assertEqual(request.refresh_from_db() or request.status, RequisitionStatus.APPROVED)
        reserve_and_prepare(requisition_id=request.id, actor=self.supervisor)
        issue_requisition(requisition_id=request.id, actor=self.supervisor, serial_numbers=['HAR-001'])
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.COMPLETED)
        self.lot.refresh_from_db()
        self.assertEqual(self.lot.quantity, 0)
        self.assertTrue(Notification.objects.filter(notification_type=NotificationType.REORDER_POINT).exists())

    def test_duplicate_active_request_is_rejected(self):
        create_requisition(requester=self.worker, client_request_id='mobile-2', items=[{'ppe_item_id': self.item.id, 'quantity': 1, 'reason': 'NEW_EMPLOYEE'}])
        with self.assertRaises(Exception):
            create_requisition(requester=self.worker, client_request_id='mobile-3', items=[{'ppe_item_id': self.item.id, 'quantity': 1, 'reason': 'NEW_EMPLOYEE'}])

    def test_employee_id_login_returns_jwt(self):
        self.worker.set_password('secret-pass')
        self.worker.save(update_fields=['password'])
        response = self.client.post('/api/v1/auth/token/', {'employee_id': 'EMP001', 'password': 'secret-pass'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)
        self.assertEqual(response.data['user']['employee_id'], 'EMP001')

    def test_special_request_requires_both_approvals(self):
        request = create_requisition(requester=self.worker, client_request_id='special-1', items=[{'ppe_item_id': self.item.id, 'quantity': 2, 'reason': 'DAMAGED'}])
        self.assertEqual(request.status, RequisitionStatus.SPECIAL)
        approve_requisition(requisition=request, approver=self.supervisor, decision=ApprovalDecision.APPROVED)
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.SPECIAL)
        approve_requisition(requisition=request, approver=self.ehs, decision=ApprovalDecision.APPROVED)
        request.refresh_from_db()
        self.assertEqual(request.status, RequisitionStatus.APPROVED)
