import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/inventory_models.dart';
import '../../../shared/models/ppe_item_model.dart';
import '../../../shared/models/requisition_model.dart';
import '../../../shared/providers/core_providers.dart';
import '../../requisitions/data/requisition_providers.dart';

class ReceiveStockInput {
  const ReceiveStockInput({
    required this.ppeItemId,
    required this.quantity,
    this.lotNumber = '',
    this.supplier = '',
    this.serialNumbers = const [],
    this.expiryAt,
    this.manufacturedAt,
    this.inspectedAt,
    this.purchaseRequestId,
  });

  final int ppeItemId;
  final int quantity;
  final String lotNumber;
  final String supplier;
  final List<String> serialNumbers;
  final DateTime? expiryAt;
  final DateTime? manufacturedAt;
  final DateTime? inspectedAt;
  final int? purchaseRequestId;

  Map<String, dynamic> toJson() => {
        'ppe_item_id': ppeItemId,
        'quantity': quantity,
        'lot_number': lotNumber,
        'supplier': supplier,
        'serial_numbers': serialNumbers,
        'expiry_at': expiryAt?.toUtc().toIso8601String(),
        'manufactured_at': manufacturedAt?.toUtc().toIso8601String(),
        'inspected_at': inspectedAt?.toUtc().toIso8601String(),
        'purchase_request_id': purchaseRequestId,
      };
}

class InventoryRepository {
  InventoryRepository(this._api);

  final ApiClient _api;

  Future<List<PpeItem>> summary(String locale) async =>
      (await _api.getList(ApiEndpoints.inventorySummary, query: {'locale': locale})).map(PpeItem.fromJson).toList();

  Future<List<StockLot>> lots({int? ppeItemId, bool inStockOnly = false, String? search}) async => (await _api.getList(ApiEndpoints.lots, query: {
        'ppe_item': ppeItemId,
        'in_stock': inStockOnly ? '1' : null,
        'search': search,
        'page_size': AppConfig.pageSize,
      }))
          .map(StockLot.fromJson)
          .toList();

  Future<List<StockLot>> receive(ReceiveStockInput input) async =>
      ApiClient.unwrapList(await _api.post(ApiEndpoints.lots, data: input.toJson())).map(StockLot.fromJson).toList();

  /// [eventType] ADJUSTMENT (+/-) or DAMAGE (write-off).
  Future<StockLot> adjust(int lotId, {required int delta, required String reason, String eventType = 'ADJUSTMENT'}) async => StockLot.fromJson(
        Map<String, dynamic>.from(await _api.post(ApiEndpoints.adjustLot(lotId), data: {'delta': delta, 'reason': reason, 'event_type': eventType}) as Map),
      );

  Future<List<StockEventRecord>> events({int? ppeItemId}) async =>
      (await _api.getList(ApiEndpoints.stockEvents, query: {'ppe_item': ppeItemId, 'page_size': AppConfig.pageSize})).map(StockEventRecord.fromJson).toList();

  /// Verifies a scanned QR without consuming it (it is consumed when issuing).
  Future<QrResolution> resolveQr(String token) async =>
      QrResolution.fromJson(token, Map<String, dynamic>.from(await _api.post(ApiEndpoints.qrResolve, data: {'token': token}) as Map));

  Future<List<PurchaseRequest>> purchaseRequests({String? status}) async =>
      (await _api.getList(ApiEndpoints.purchaseRequests, query: {'status': status, 'page_size': AppConfig.pageSize})).map(PurchaseRequest.fromJson).toList();

  Future<PurchaseRequest> createPurchaseRequest({required int ppeItemId, required int quantity, required String reason}) async => PurchaseRequest.fromJson(
        Map<String, dynamic>.from(
          await _api.post(ApiEndpoints.purchaseRequests, data: {'ppe_item': ppeItemId, 'requested_quantity': quantity, 'reason': reason}) as Map,
        ),
      );

  Future<PurchaseRequest> setPurchaseStatus(int id, String status) async =>
      PurchaseRequest.fromJson(Map<String, dynamic>.from(await _api.post(ApiEndpoints.purchaseRequestStatus(id), data: {'status': status}) as Map));
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) => InventoryRepository(ref.watch(apiClientProvider)));

final inventorySummaryProvider = FutureProvider.autoDispose<List<PpeItem>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(inventoryRepositoryProvider).summary(ref.watch(localeCodeProvider));
});

final lotsForItemProvider = FutureProvider.autoDispose.family<List<StockLot>, int>((ref, itemId) {
  ref.watch(dataRevisionProvider);
  return ref.watch(inventoryRepositoryProvider).lots(ppeItemId: itemId);
});

final stockEventsProvider = FutureProvider.autoDispose.family<List<StockEventRecord>, int?>((ref, itemId) {
  ref.watch(dataRevisionProvider);
  return ref.watch(inventoryRepositoryProvider).events(ppeItemId: itemId);
});

final purchaseRequestsProvider = FutureProvider.autoDispose<List<PurchaseRequest>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(inventoryRepositoryProvider).purchaseRequests();
});
