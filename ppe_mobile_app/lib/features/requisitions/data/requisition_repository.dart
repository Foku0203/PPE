import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/dashboard_model.dart';
import '../../../shared/models/inventory_models.dart';
import '../../../shared/models/requisition_model.dart';
import '../../../shared/providers/core_providers.dart';

/// `scope` values understood by `GET /requisitions/`.
class RequisitionScope {
  static const visible = 'visible';
  static const mine = 'mine';
  static const team = 'team';
  static const inbox = 'inbox';
  static const store = 'store';
}

class IssuedItems {
  const IssuedItems(this.items, this.replacementDue);

  final List<RequisitionLine> items;
  final List<ReplacementDue> replacementDue;
}

class RequisitionRepository {
  RequisitionRepository(this._api);

  final ApiClient _api;

  Future<List<Requisition>> list({String scope = RequisitionScope.visible, List<String>? statuses, String? search}) async {
    final rows = await _api.getList(ApiEndpoints.requisitions, query: {
      'scope': scope,
      'status': statuses?.join(','),
      'search': search,
      'page_size': AppConfig.pageSize,
    });
    return rows.map(Requisition.fromJson).toList();
  }

  Future<Requisition> detail(int id) async => _parse(await _api.get(ApiEndpoints.requisition(id)));

  /// Submits a request. [clientRequestId] makes retries idempotent (safe for the offline queue).
  Future<Requisition> create({required List<CartLine> lines, required String clientRequestId, String specialReason = ''}) async => _parse(
        await _api.post(
          ApiEndpoints.requisitions,
          data: {'client_request_id': clientRequestId, 'special_reason': specialReason, 'items': lines.map((l) => l.toApi()).toList()},
          idempotencyKey: clientRequestId,
        ),
      );

  Future<Requisition> cancel(int id) async => _parse(await _api.post(ApiEndpoints.cancel(id)));

  /// [decision] is APPROVED, REJECTED or REQUEST_INFO.
  Future<Requisition> decide(int id, String decision, {String reason = ''}) async =>
      _parse(await _api.post(ApiEndpoints.approvals(id), data: {'decision': decision, 'reason': reason}));

  Future<Requisition> comment(int id, String message) async => _parse(await _api.post(ApiEndpoints.comments(id), data: {'message': message}));

  Future<PickupQr> pickupQr(int id) async => PickupQr.fromJson(Map<String, dynamic>.from(await _api.post(ApiEndpoints.pickupQr(id)) as Map));

  Future<Requisition> prepare(int id) async => _parse(await _api.post(ApiEndpoints.prepare(id)));

  Future<Requisition> issue(int id, {List<String> serialNumbers = const [], String? qrToken}) async =>
      _parse(await _api.post(ApiEndpoints.issue(id), data: {'serial_numbers': serialNumbers, 'qr_token': qrToken ?? ''}));

  Future<Requisition> returnLine(int lineId, {required String condition, String note = ''}) async =>
      _parse(await _api.post(ApiEndpoints.returnItem(lineId), data: {'condition': condition, 'note': note}));

  Future<IssuedItems> myIssuedItems() async {
    final data = Map<String, dynamic>.from(await _api.get(ApiEndpoints.myIssuedItems) as Map);
    return IssuedItems(
      ApiClient.unwrapList(data['items']).map(RequisitionLine.fromJson).toList(),
      ApiClient.unwrapList(data['replacement_due']).map(ReplacementDue.fromJson).toList(),
    );
  }

  Requisition _parse(dynamic data) => Requisition.fromJson(Map<String, dynamic>.from(data as Map));
}

final requisitionRepositoryProvider = Provider<RequisitionRepository>((ref) => RequisitionRepository(ref.watch(apiClientProvider)));
