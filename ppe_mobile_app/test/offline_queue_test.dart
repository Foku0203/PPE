import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ppe_mobile_app/core/errors/app_exceptions.dart';
import 'package:ppe_mobile_app/core/storage/local_store.dart';
import 'package:ppe_mobile_app/features/requisitions/data/offline_queue.dart';
import 'package:ppe_mobile_app/features/requisitions/data/requisition_repository.dart';
import 'package:ppe_mobile_app/shared/models/requisition_model.dart';
import 'package:ppe_mobile_app/shared/providers/core_providers.dart';

class MockRepo extends Mock implements RequisitionRepository {}

QueuedRequest queued(String id) => QueuedRequest(
      clientRequestId: id,
      createdAt: DateTime(2026, 9, 26),
      lines: const [CartLine(itemId: 1, code: 'PPE-HLM', name: 'Helmet')],
    );

void main() {
  late MockRepo repo;
  late MemoryLocalStore store;
  late ProviderContainer container;

  setUp(() {
    repo = MockRepo();
    store = MemoryLocalStore();
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      requisitionRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  void stubCreate(Future<Requisition> Function(String id) answer) {
    when(() => repo.create(lines: any(named: 'lines'), clientRequestId: any(named: 'clientRequestId'), specialReason: any(named: 'specialReason')))
        .thenAnswer((inv) => answer(inv.namedArguments[#clientRequestId] as String));
  }

  test('queued requests persist and survive a restart', () async {
    await container.read(offlineQueueProvider.notifier).enqueue(queued('a'));
    final restarted = ProviderContainer(overrides: [localStoreProvider.overrideWithValue(store), requisitionRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(restarted.dispose);
    expect(restarted.read(offlineQueueProvider).single.clientRequestId, 'a');
  });

  test('successful sync removes items and reuses the client_request_id', () async {
    final sent = <String>[];
    stubCreate((id) async {
      sent.add(id);
      return Requisition(id: 1, requestNo: 'PR-1', status: RequisitionStatus.pending, requesterName: 'x');
    });
    final queue = container.read(offlineQueueProvider.notifier);
    await queue.enqueue(queued('a'));
    await queue.enqueue(queued('b'));

    final result = await queue.syncAll();

    expect(result.sent, 2);
    expect(sent, ['a', 'b']);
    expect(container.read(offlineQueueProvider), isEmpty);
  });

  test('network failure keeps the request pending for the next attempt', () async {
    stubCreate((_) async => throw const NoInternetException());
    final queue = container.read(offlineQueueProvider.notifier);
    await queue.enqueue(queued('a'));

    final result = await queue.syncAll();

    expect(result.stillOffline, isTrue);
    expect(container.read(offlineQueueProvider).single.state, SyncState.pending);
    expect(container.read(offlineQueueProvider).single.attempts, 1);
  });

  test('business rejection marks the request failed with the error code', () async {
    stubCreate((_) async => throw const ApiException('dup', code: 'ACTIVE_REQUEST_EXISTS', statusCode: 409));
    final queue = container.read(offlineQueueProvider.notifier);
    await queue.enqueue(queued('a'));

    await queue.syncAll();

    final item = container.read(offlineQueueProvider).single;
    expect(item.state, SyncState.failed);
    expect(item.errorCode, 'ACTIVE_REQUEST_EXISTS');

    await queue.remove('a');
    expect(container.read(offlineQueueProvider), isEmpty);
  });

  test('stale "syncing" state is recovered as pending after restart', () {
    final json = queued('x').copyWith(state: SyncState.syncing).toJson();
    expect(QueuedRequest.fromJson(json).state, SyncState.pending);
  });
}
