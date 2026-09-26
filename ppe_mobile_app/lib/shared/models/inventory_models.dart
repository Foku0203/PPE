import '../../core/utils/json.dart';

class StockLot {
  const StockLot({
    required this.id,
    required this.ppeItemId,
    required this.ppeCode,
    this.ppeName = '',
    this.lotNumber = '',
    this.serialNumber,
    this.supplier = '',
    this.quantity = 0,
    this.reservedQuantity = 0,
    this.availableQuantity = 0,
    this.expiryAt,
    this.manufacturedAt,
    this.inspectedAt,
    this.serialStatus = 'AVAILABLE',
    this.isExpired = false,
  });

  final int id;
  final int ppeItemId;
  final String ppeCode;
  final String ppeName;
  final String lotNumber;
  final String? serialNumber;
  final String supplier;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final DateTime? expiryAt;
  final DateTime? manufacturedAt;
  final DateTime? inspectedAt;
  final String serialStatus;
  final bool isExpired;

  bool get expiresSoon => !isExpired && expiryAt != null && expiryAt!.difference(DateTime.now()).inDays <= 30;

  factory StockLot.fromJson(Map<String, dynamic> json) => StockLot(
        id: asInt(json['id']),
        ppeItemId: asInt(json['ppe_item']),
        ppeCode: asString(json['ppe_code']),
        ppeName: asString(json['ppe_name']),
        lotNumber: asString(json['lot_number']),
        serialNumber: json['serial_number'] as String?,
        supplier: asString(json['supplier']),
        quantity: asInt(json['quantity']),
        reservedQuantity: asInt(json['reserved_quantity']),
        availableQuantity: asInt(json['available_quantity']),
        expiryAt: asDate(json['expiry_at']),
        manufacturedAt: asDate(json['manufactured_at']),
        inspectedAt: asDate(json['inspected_at']),
        serialStatus: asString(json['serial_status'], 'AVAILABLE'),
        isExpired: asBool(json['is_expired']),
      );
}

class PurchaseRequest {
  const PurchaseRequest({
    required this.id,
    required this.requestNo,
    required this.ppeItemId,
    required this.ppeCode,
    required this.quantity,
    required this.status,
    this.ppeName = '',
    this.requesterName = '',
    this.reason = '',
    this.createdAt,
  });

  final int id;
  final String requestNo;
  final int ppeItemId;
  final String ppeCode;
  final String ppeName;
  final String requesterName;
  final int quantity;
  final String reason;

  /// PENDING | APPROVED | ORDERED | RECEIVED | REJECTED
  final String status;
  final DateTime? createdAt;

  List<String> get nextStatuses => switch (status) {
        'PENDING' => const ['APPROVED', 'REJECTED'],
        'APPROVED' => const ['ORDERED', 'REJECTED'],
        _ => const [],
      };

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) => PurchaseRequest(
        id: asInt(json['id']),
        requestNo: asString(json['request_no']),
        ppeItemId: asInt(json['ppe_item']),
        ppeCode: asString(json['ppe_item_code']),
        ppeName: asString(json['ppe_item_name']),
        requesterName: asString(json['requester_name']),
        quantity: asInt(json['requested_quantity']),
        reason: asString(json['reason']),
        status: asString(json['status']),
        createdAt: asDate(json['created_at']),
      );
}

/// Result of scanning a QR at the store (`/inventory/scan/resolve/`).
class QrResolution {
  const QrResolution({required this.token, this.purpose = '', this.requisitionId, this.requestNo, this.status, this.requesterName, this.expiresAt});

  final String token;
  final String purpose;
  final int? requisitionId;
  final String? requestNo;
  final String? status;
  final String? requesterName;
  final DateTime? expiresAt;

  factory QrResolution.fromJson(String token, Map<String, dynamic> json) => QrResolution(
        token: token,
        purpose: asString(json['purpose']),
        requisitionId: asIntOrNull(json['requisition_id']),
        requestNo: json['request_no'] as String?,
        status: json['status'] as String?,
        requesterName: json['requester_name'] as String?,
        expiresAt: asDate(json['expires_at']),
      );
}

class PickupQr {
  const PickupQr({required this.token, required this.expiresAt, required this.requestNo});

  final String token;
  final DateTime expiresAt;
  final String requestNo;

  factory PickupQr.fromJson(Map<String, dynamic> json) => PickupQr(
        token: asString(json['token']),
        expiresAt: asDate(json['expires_at']) ?? DateTime.now().add(const Duration(minutes: 5)),
        requestNo: asString(json['request_no']),
      );
}
