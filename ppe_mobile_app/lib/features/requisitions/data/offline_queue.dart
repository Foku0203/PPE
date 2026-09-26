import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/requisition_model.dart';
import '../../../shared/providers/core_providers.dart';
import 'requisition_providers.dart';
import 'requisition_repository.dart';

enum SyncState { pending, syncing, failed }

/// A requisition submitted while offline. Re-sent with the same client_request_id,
/// so a retry after a lost response never creates a duplicate on the server.
class QueuedRequest {
  const QueuedRequest({
    required this.clientRequestId,
    required this.lines,
    required this.createdAt,
    this.specialReason = '',
    this.state = SyncState.pending,
    this.errorCode,
    this.errorMessage,
    this.attempts = 0,
  });

  final String clientRequestId;
  final List<CartLine> lines;
  final String specialReason;
  final DateTime createdAt;
  final SyncState state;
  final String? errorCode;
  final String? errorMessage;
  final int attempts;

  QueuedRequest copyWith({SyncState? state, String? errorCode, String? errorMessage, int? attempts, bool clearError = false}) => QueuedRequest(
        clientRequestId: clientRequestId,
        lines: lines,
        specialReason: specialReason,
        createdAt: createdAt,
        state: state ?? this.state,
        errorCode: clearError ? null : (errorCode ?? this.errorCode),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'client_request_id': clientRequestId,
        'lines': lines.map((l) => l.toJson()).toList(),
        'special_reason': specialReason,
        'created_at': createdAt.toIso8601String(),
        'state': state.name,
        'error_code': errorCode,
        'error_message': errorMessage,
        'attempts': attempts,
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        clientRequestId: asString(json['client_request_id']),
        lines: asMapList(json['lines']).map(CartLine.fromJson).toList(),
        specialReason: asString(json['special_reason']),
        createdAt: asDate(json['created_at']) ?? DateTime.now(),
        // A request stuck in "syncing" (app killed mid-send) goes back to pending.
        state: json['state'] == 'failed' ? SyncState.failed : SyncState.pending,
        errorCode: json['error_code'] as String?,
        errorMessage: json['error_message'] as String?,
        attempts: asInt(json['attempts']),
      );
}

class SyncResult {
  const SyncResult({this.sent = 0, this.failed = 0, this.stillOffline = false});

  final int sent;
  final int failed;
  final bool stillOffline;
}

class OfflineQueueController extends Notifier<List<QueuedRequest>> {
  bool _syncing = false;

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  List<QueuedRequest> build() {
    final raw = ref.watch(localStoreProvider).getJson(StoreKeys.offlineQueue);
    return asMapList(raw).map(QueuedRequest.fromJson).toList();
  }

  int get pendingCount => state.where((q) => q.state != SyncState.failed).length;

  Future<void> _persist() => _store.putJson(StoreKeys.offlineQueue, state.map((q) => q.toJson()).toList());

  Future<void> enqueue(QueuedRequest request) async {
    state = [...state, request];
    await _persist();
  }

  Future<void> remove(String clientRequestId) async {
    state = state.where((q) => q.clientRequestId != clientRequestId).toList();
    await _persist();
  }

  Future<void> retry(String clientRequestId) async {
    state = [for (final q in state) q.clientRequestId == clientRequestId ? q.copyWith(state: SyncState.pending, clearError: true) : q];
    await _persist();
    await syncAll();
  }

  void _update(String id, QueuedRequest Function(QueuedRequest) change) {
    state = [for (final q in state) q.clientRequestId == id ? change(q) : q];
  }

  /// Sends every pending request. Business-rule rejections become `failed` (user must edit/remove);
  /// network failures stay `pending` for the next attempt.
  Future<SyncResult> syncAll() async {
    if (_syncing) return const SyncResult();
    _syncing = true;
    var sent = 0, failed = 0;
    var offline = false;
    try {
      final repo = ref.read(requisitionRepositoryProvider);
      for (final item in state.where((q) => q.state == SyncState.pending).toList()) {
        _update(item.clientRequestId, (q) => q.copyWith(state: SyncState.syncing, attempts: q.attempts + 1));
        try {
          await repo.create(lines: item.lines, clientRequestId: item.clientRequestId, specialReason: item.specialReason);
          state = state.where((q) => q.clientRequestId != item.clientRequestId).toList();
          sent++;
        } on AppException catch (e) {
          if (e.isNetworkFailure) {
            _update(item.clientRequestId, (q) => q.copyWith(state: SyncState.pending));
            offline = true;
            break;
          }
          _update(item.clientRequestId, (q) => q.copyWith(state: SyncState.failed, errorCode: e.code, errorMessage: e.message));
          failed++;
        }
      }
      await _persist();
      if (sent > 0) ref.read(dataRevisionProvider.notifier).bump();
    } finally {
      _syncing = false;
    }
    return SyncResult(sent: sent, failed: failed, stillOffline: offline);
  }
}

final offlineQueueProvider = NotifierProvider<OfflineQueueController, List<QueuedRequest>>(OfflineQueueController.new);
