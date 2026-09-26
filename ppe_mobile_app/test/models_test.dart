import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_mobile_app/shared/models/notification_model.dart';
import 'package:ppe_mobile_app/shared/models/ppe_item_model.dart';
import 'package:ppe_mobile_app/shared/models/requisition_model.dart';
import 'package:ppe_mobile_app/shared/models/user_model.dart';

void main() {
  group('Requisition.fromJson', () {
    final json = {
      'id': 7,
      'request_no': 'PR-260926-ABC123',
      'requester': 3,
      'requester_name': 'Somchai',
      'requester_employee_id': 'EMP001',
      'status': 'SPECIAL_APPROVAL_REQUIRED',
      'special_approval_needed': true,
      'special_reason': 'Torn strap',
      'items': [
        {'id': 1, 'ppe_item': 4, 'ppe_item_code': 'PPE-HAR', 'ppe_item_name': 'Harness', 'size': '', 'quantity': 1, 'reason': 'DAMAGED', 'requires_serial': true},
      ],
      'approvals': [
        {'kind': 'SPECIAL_SUPERVISOR', 'decision': 'APPROVED', 'approver_name': 'Sup', 'created_at': '2026-09-26T03:00:00Z'},
      ],
      'actions': {'can_approve': true, 'can_cancel': false},
      'is_overdue': true,
      'created_at': '2026-09-25T10:00:00Z',
    };

    test('parses nested lines, approvals and server-computed actions', () {
      final r = Requisition.fromJson(json);
      expect(r.status, RequisitionStatus.special);
      expect(r.items.single.requiresSerial, isTrue);
      expect(r.items.single.reason, RequestReason.damaged);
      expect(r.approvals.single.approved, isTrue);
      expect(r.actions.canApprove, isTrue);
      expect(r.actions.canCancel, isFalse);
      expect(r.isOverdue, isTrue);
      expect(r.totalQuantity, 1);
    });

    test('unknown status falls back safely', () {
      expect(RequisitionStatus.fromApi('SOMETHING_NEW'), RequisitionStatus.pending);
    });
  });

  test('status flow index drives the progress indicator', () {
    expect(RequisitionStatus.pending.flowIndex, 0);
    expect(RequisitionStatus.special.flowIndex, 0);
    expect(RequisitionStatus.onHold.flowIndex, 1);
    expect(RequisitionStatus.ready.flowIndex, 2);
    expect(RequisitionStatus.completed.flowIndex, 3);
    expect(RequisitionStatus.rejected.flowIndex, -1);
    expect(RequisitionStatus.cancelled.isClosed, isTrue);
  });

  test('PpeItem resolves names per locale with fallback', () {
    final item = PpeItem.fromJson({
      'id': 1,
      'code': 'PPE-HLM',
      'name': 'Safety Helmet',
      'category': 'HEAD',
      'sizes': 'S, M ,L',
      'stock': 3,
      'reorder_point': 5,
      'translations': [
        {'locale': 'TH', 'name': 'หมวกนิรภัย'},
        {'locale': 'MY', 'name': 'ဘေးကင်းရေး ဦးထုပ်'},
        {'locale': 'ZH', 'name': '安全帽'},
      ],
    });
    expect(item.nameFor('ZH'), '安全帽');
    expect(item.nameFor('TH'), 'หมวกนิรภัย');
    expect(item.nameFor('MY'), 'ဘေးကင်းရေး ဦးထုပ်');
    expect(item.nameFor('EN'), 'Safety Helmet');
    expect(item.sizes, ['S', 'M', 'L']);
    expect(item.category, PpeCategory.head);
    expect(item.isLowStock, isTrue);
  });

  test('Eligibility flags blocking vs special approval', () {
    final dup = Eligibility.fromJson({'allowed': false, 'special_approval_required': false, 'reason': 'ACTIVE_REQUEST_EXISTS'});
    final early = Eligibility.fromJson({'allowed': false, 'special_approval_required': true, 'reason': 'LIFESPAN_NOT_EXPIRED', 'eligible_at': '2027-01-01T00:00:00Z'});
    expect(dup.isBlocked, isTrue);
    expect(early.isBlocked, isFalse);
    expect(early.eligibleAt, isNotNull);
  });

  test('CartLine serializes to the API contract', () {
    const line = CartLine(itemId: 9, code: 'PPE-GLV', name: 'Gloves', size: 'L', quantity: 2, reason: RequestReason.lost);
    expect(line.toApi(), {'ppe_item_id': 9, 'quantity': 2, 'reason': 'LOST', 'size': 'L'});
    expect(CartLine.fromJson(line.toJson()).reason, RequestReason.lost);
  });

  test('UserRole capabilities mirror backend permissions', () {
    expect(UserRole.worker.canApprove, isFalse);
    expect(UserRole.supervisor.canApprove, isTrue);
    expect(UserRole.supervisor.isStore, isFalse);
    expect(UserRole.storeKeeper.isStore, isTrue);
    expect(UserRole.storeKeeper.canApprove, isFalse);
    expect(UserRole.ehs.canManageMasterData, isTrue);
    expect(UserRole.admin.isAdmin, isTrue);
    expect(AppUser.fromJson({'id': 1, 'display_name': 'Aung Kyaw', 'role': 'EHS'}).initials, 'AK');
  });

  test('notification payload helpers', () {
    final n = AppNotification.fromJson({
      'id': 1,
      'notification_type': 'READY_FOR_PICKUP',
      'title': 'x',
      'message': 'y',
      'payload': {'requisition_id': 5, 'request_no': 'PR-1'},
    });
    expect(n.kind, NotificationKind.readyForPickup);
    expect(n.requisitionId, 5);
    expect(n.isRead, isFalse);
  });
}
