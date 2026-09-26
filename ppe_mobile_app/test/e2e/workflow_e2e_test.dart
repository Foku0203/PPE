// End-to-end contract test: drives the real Dart repositories against a running Django backend.
//
//   cd backend
//   $env:DATABASE_URL="sqlite:///e2e.sqlite3"; python manage.py migrate; python manage.py seed_ppe --no-requests
//   $env:DATABASE_URL="sqlite:///e2e.sqlite3"; python manage.py runserver 8000
//   cd ../ppe_mobile_app
//   flutter test test/e2e --dart-define=E2E_BASE_URL=http://127.0.0.1:8000/api/v1
//
// Skipped when E2E_BASE_URL is not provided, so `flutter test` stays offline.
@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_mobile_app/core/errors/app_exceptions.dart';
import 'package:ppe_mobile_app/core/network/api_client.dart';
import 'package:ppe_mobile_app/core/network/dio_client.dart';
import 'package:ppe_mobile_app/core/storage/local_store.dart';
import 'package:ppe_mobile_app/core/storage/secure_storage_service.dart';
import 'package:ppe_mobile_app/features/admin/data/admin_repository.dart';
import 'package:ppe_mobile_app/features/auth/data/auth_repository.dart';
import 'package:ppe_mobile_app/features/catalog/data/catalog_repository.dart';
import 'package:ppe_mobile_app/features/inventory/data/inventory_repository.dart';
import 'package:ppe_mobile_app/features/notifications/data/notification_repository.dart';
import 'package:ppe_mobile_app/features/requisitions/data/requisition_repository.dart';
import 'package:ppe_mobile_app/shared/models/requisition_model.dart';
import 'package:ppe_mobile_app/shared/models/user_model.dart';

const baseUrl = String.fromEnvironment('E2E_BASE_URL');
const password = 'ChangeMe123!';

class Session {
  Session._(this.api, this.store);

  final ApiClient api;
  final LocalStore store;
  late AppUser user;

  static Future<Session> login(String employeeId) async {
    final tokens = MemoryTokenStorage();
    final store = MemoryLocalStore();
    final api = ApiClient(DioClient.create(baseUrl: () => baseUrl, tokens: tokens, locale: () => 'TH', onSessionExpired: () {}));
    final session = Session._(api, store);
    session.user = await AuthRepository(api, tokens, store).login(employeeId, password);
    return session;
  }

  RequisitionRepository get requisitions => RequisitionRepository(api);
  CatalogRepository get catalog => CatalogRepository(api, store);
  InventoryRepository get inventory => InventoryRepository(api);
  NotificationRepository get notifications => NotificationRepository(api);
  AdminRepository get admin => AdminRepository(api);
}

void main() {
  final skip = baseUrl.isEmpty ? 'Set --dart-define=E2E_BASE_URL to run against a live backend' : null;

  test('full requisition lifecycle across all roles', () async {
    final worker = await Session.login('EMP001');
    final supervisor = await Session.login('SUP001');
    final store = await Session.login('STORE001');
    final ehs = await Session.login('EHS001');
    final admin = await Session.login('ADMIN001');
    expect(worker.user.role, UserRole.worker);
    expect(store.user.role, UserRole.storeKeeper);

    // Catalog in Thai with images/stock.
    final catalog = (await worker.catalog.fetchCatalog('TH')).items;
    expect(catalog.length, greaterThanOrEqualTo(13));
    final helmet = catalog.firstWhere((i) => i.code == 'PPE-HLM');
    final harness = catalog.firstWhere((i) => i.code == 'PPE-HAR');
    expect(helmet.name, 'หมวกนิรภัย');
    final zhCatalog = (await worker.catalog.fetchCatalog('ZH')).items;
    expect(zhCatalog.firstWhere((i) => i.code == 'PPE-HLM').name, '安全帽');

    // Eligibility + normal request.
    expect((await worker.catalog.checkEligibility(helmet.id, 1)).allowed, isTrue);
    final created = await worker.requisitions.create(
      lines: [CartLine(itemId: helmet.id, code: helmet.code, name: helmet.name, reason: RequestReason.newEmployee)],
      clientRequestId: 'e2e-${DateTime.now().microsecondsSinceEpoch}',
    );
    expect(created.status, RequisitionStatus.pending);
    expect(created.actions.canCancel, isTrue);

    // Duplicate is blocked with a stable error code.
    await expectLater(
      worker.requisitions.create(lines: [CartLine(itemId: helmet.id, code: helmet.code, name: '')], clientRequestId: 'e2e-dup-${DateTime.now().microsecondsSinceEpoch}'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'ACTIVE_REQUEST_EXISTS')),
    );

    // Supervisor inbox → ask for info → worker replies → approve.
    final inbox = await supervisor.requisitions.list(scope: RequisitionScope.inbox);
    expect(inbox.map((r) => r.id), contains(created.id));
    await supervisor.requisitions.decide(created.id, 'REQUEST_INFO', reason: 'Which area?');
    await worker.requisitions.comment(created.id, 'Welding bay 2');
    final approved = await supervisor.requisitions.decide(created.id, 'APPROVED');
    expect(approved.status, RequisitionStatus.approved);
    expect(approved.comments.length, 2);

    // Store prepares → worker shows QR → store verifies → issues with QR.
    final storeQueue = await store.requisitions.list(scope: RequisitionScope.store, statuses: ['APPROVED']);
    expect(storeQueue.map((r) => r.id), contains(created.id));
    final ready = await store.requisitions.prepare(created.id);
    expect(ready.status, RequisitionStatus.ready);
    expect(ready.actions.canIssue, isTrue);
    final qr = await worker.requisitions.pickupQr(created.id);
    final resolved = await store.inventory.resolveQr(qr.token);
    expect(resolved.requisitionId, created.id);
    final done = await store.requisitions.issue(created.id, qrToken: qr.token);
    expect(done.status, RequisitionStatus.completed);
    expect(done.stockEvents.any((e) => e.eventType == 'ISSUE'), isTrue);
    await expectLater(store.inventory.resolveQr(qr.token), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'QR_INVALID')));

    // Worker sees the PPE and a notification; early replacement now needs special approval.
    final issued = await worker.requisitions.myIssuedItems();
    expect(issued.items.map((i) => i.code), contains('PPE-HLM'));
    expect((await worker.notifications.list()).any((n) => n.requisitionId == created.id), isTrue);
    expect((await worker.catalog.checkEligibility(helmet.id, 1)).reason, 'LIFESPAN_NOT_EXPIRED');

    // Special request (harness above quota) needs Supervisor + EHS.
    final special = await worker.requisitions.create(
      lines: [CartLine(itemId: harness.id, code: harness.code, name: harness.name, quantity: 2)],
      clientRequestId: 'e2e-special-${DateTime.now().microsecondsSinceEpoch}',
      specialReason: 'Rescue team kit',
    );
    expect(special.status, RequisitionStatus.special);
    await supervisor.requisitions.decide(special.id, 'APPROVED');
    final afterEhs = await ehs.requisitions.decide(special.id, 'APPROVED');
    expect(afterEhs.status, RequisitionStatus.approved);
    // Serial-controlled issue with the reserved serial numbers, then return one unit.
    final prepared = await store.requisitions.prepare(special.id);
    final serials = prepared.stockEvents.where((e) => e.eventType == 'RESERVE').map((e) => e.serialNumber!).toList();
    expect(serials.length, 2);
    final issuedSpecial = await store.requisitions.issue(special.id, serialNumbers: serials);
    expect(issuedSpecial.status, RequisitionStatus.completed);
    final returned = await store.requisitions.returnLine(issuedSpecial.items.single.id, condition: 'GOOD');
    expect(returned.items.single.isReturned, isTrue);

    // Inventory: summary, receive, adjust, purchase request.
    final summary = await store.inventory.summary('EN');
    expect(summary.firstWhere((i) => i.code == 'PPE-EAR-M').isLowStock, isTrue);
    final lots = await store.inventory.receive(ReceiveStockInput(ppeItemId: helmet.id, quantity: 10, lotNumber: 'E2E-LOT'));
    final adjusted = await store.inventory.adjust(lots.single.id, delta: -1, reason: 'count', eventType: 'ADJUSTMENT');
    expect(adjusted.quantity, 9);
    final pr = await ehs.inventory.createPurchaseRequest(ppeItemId: helmet.id, quantity: 20, reason: 'Stock up');
    expect((await store.inventory.setPurchaseStatus(pr.id, 'APPROVED')).status, 'APPROVED');

    // Admin: users & audit.
    expect((await admin.admin.users()).length, greaterThanOrEqualTo(6));
    expect((await admin.admin.auditLogs()).any((a) => a.action == 'ISSUE'), isTrue);

    // Role enforcement on the server.
    await expectLater(worker.inventory.summary('EN'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
