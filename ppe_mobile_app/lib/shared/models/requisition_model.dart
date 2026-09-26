import '../../core/utils/json.dart';

enum RequisitionStatus {
  pending('PENDING_APPROVAL'),
  special('SPECIAL_APPROVAL_REQUIRED'),
  approved('APPROVED'),
  onHold('ON_HOLD_STOCK'),
  ready('READY_FOR_PICKUP'),
  completed('COMPLETED'),
  rejected('REJECTED'),
  cancelled('CANCELLED');

  const RequisitionStatus(this.apiValue);
  final String apiValue;

  static RequisitionStatus fromApi(String? value) =>
      RequisitionStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => RequisitionStatus.pending);

  bool get isOpen => !isClosed;
  bool get isClosed => this == completed || this == rejected || this == cancelled;
  bool get awaitingApproval => this == pending || this == special;

  /// Ordered steps for the progress indicator.
  static const flow = [pending, approved, ready, completed];

  int get flowIndex => switch (this) {
        pending || special => 0,
        approved || onHold => 1,
        ready => 2,
        completed => 3,
        rejected || cancelled => -1,
      };
}

enum RequestReason {
  damaged('DAMAGED'),
  lifespanExpired('LIFESPAN_EXPIRED'),
  newEmployee('NEW_EMPLOYEE'),
  lost('LOST'),
  returnScheduled('RETURN_SCHEDULED'),
  other('OTHER');

  const RequestReason(this.apiValue);
  final String apiValue;

  static RequestReason fromApi(String? value) => RequestReason.values.firstWhere((r) => r.apiValue == value, orElse: () => RequestReason.other);
}

class RequisitionLine {
  const RequisitionLine({
    required this.id,
    required this.ppeItemId,
    required this.code,
    required this.name,
    required this.quantity,
    required this.reason,
    this.iconKey = 'shield',
    this.imageUrl = '',
    this.unit = '',
    this.size = '',
    this.eligibleAt,
    this.returnDueDate,
    this.returnedAt,
    this.isReturned = false,
    this.isReturnable = false,
    this.requiresSerial = false,
    this.requestNo,
    this.requisitionId,
    this.issuedAt,
    this.replaceAt,
  });

  final int id;
  final int ppeItemId;
  final String code;
  final String name;
  final String iconKey;
  final String imageUrl;
  final String unit;
  final String size;
  final int quantity;
  final RequestReason reason;
  final DateTime? eligibleAt;
  final DateTime? returnDueDate;
  final DateTime? returnedAt;
  final bool isReturned;
  final bool isReturnable;
  final bool requiresSerial;

  // Only present on `/me/issued-items/`.
  final String? requestNo;
  final int? requisitionId;
  final DateTime? issuedAt;
  final DateTime? replaceAt;

  bool get replacementDue => replaceAt != null && replaceAt!.isBefore(DateTime.now());

  factory RequisitionLine.fromJson(Map<String, dynamic> json) => RequisitionLine(
        id: asInt(json['id']),
        ppeItemId: asInt(json['ppe_item']),
        code: asString(json['ppe_item_code']),
        name: asString(json['ppe_item_name'], asString(json['ppe_item_code'])),
        iconKey: asString(json['ppe_icon_key'], 'shield'),
        imageUrl: asString(json['ppe_image_url']),
        unit: asString(json['unit']),
        size: asString(json['size']),
        quantity: asInt(json['quantity'], 1),
        reason: RequestReason.fromApi(json['reason'] as String?),
        eligibleAt: asDate(json['eligible_at']),
        returnDueDate: asDate(json['return_due_date']),
        returnedAt: asDate(json['returned_at']),
        isReturned: asBool(json['is_returned']),
        isReturnable: asBool(json['is_returnable']),
        requiresSerial: asBool(json['requires_serial']),
        requestNo: json['request_no'] as String?,
        requisitionId: asIntOrNull(json['requisition_id']),
        issuedAt: asDate(json['issued_at']),
        replaceAt: asDate(json['replace_at']),
      );
}

class ApprovalRecord {
  const ApprovalRecord({required this.kind, required this.decision, required this.approverName, this.approverRole = '', this.reason = '', this.createdAt});

  final String kind;
  final String decision;
  final String approverName;
  final String approverRole;
  final String reason;
  final DateTime? createdAt;

  bool get approved => decision == 'APPROVED';

  factory ApprovalRecord.fromJson(Map<String, dynamic> json) => ApprovalRecord(
        kind: asString(json['kind']),
        decision: asString(json['decision']),
        approverName: asString(json['approver_name']),
        approverRole: asString(json['approver_role']),
        reason: asString(json['reason']),
        createdAt: asDate(json['created_at']),
      );
}

class RequisitionComment {
  const RequisitionComment({required this.id, required this.authorName, required this.message, this.authorRole = '', this.isInfoRequest = false, this.createdAt});

  final int id;
  final String authorName;
  final String authorRole;
  final String message;
  final bool isInfoRequest;
  final DateTime? createdAt;

  factory RequisitionComment.fromJson(Map<String, dynamic> json) => RequisitionComment(
        id: asInt(json['id']),
        authorName: asString(json['author_name']),
        authorRole: asString(json['author_role']),
        message: asString(json['message']),
        isInfoRequest: asBool(json['is_info_request']),
        createdAt: asDate(json['created_at']),
      );
}

class StockEventRecord {
  const StockEventRecord({
    required this.id,
    required this.eventType,
    required this.quantity,
    this.ppeCode = '',
    this.lotNumber = '',
    this.serialNumber,
    this.issuerName,
    this.receiverName,
    this.requestNo,
    this.metadata = const {},
    this.createdAt,
  });

  final int id;
  final String eventType;
  final int quantity;
  final String ppeCode;
  final String lotNumber;
  final String? serialNumber;
  final String? issuerName;
  final String? receiverName;
  final String? requestNo;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory StockEventRecord.fromJson(Map<String, dynamic> json) => StockEventRecord(
        id: asInt(json['id']),
        eventType: asString(json['event_type']),
        quantity: asInt(json['quantity']),
        ppeCode: asString(json['ppe_code']),
        lotNumber: asString(json['lot_number']),
        serialNumber: json['serial_number'] as String?,
        issuerName: json['issuer_name'] as String?,
        receiverName: json['receiver_name'] as String?,
        requestNo: json['request_no'] as String?,
        metadata: asMap(json['metadata']),
        createdAt: asDate(json['created_at']),
      );
}

/// What the current user may do, computed by the backend (single source of truth for RBAC).
class RequisitionActions {
  const RequisitionActions({
    this.canApprove = false,
    this.canRequestInfo = false,
    this.canCancel = false,
    this.canPrepare = false,
    this.canIssue = false,
    this.canShowPickupQr = false,
    this.canReturn = false,
    this.canComment = false,
  });

  final bool canApprove;
  final bool canRequestInfo;
  final bool canCancel;
  final bool canPrepare;
  final bool canIssue;
  final bool canShowPickupQr;
  final bool canReturn;
  final bool canComment;

  factory RequisitionActions.fromJson(Map<String, dynamic> json) => RequisitionActions(
        canApprove: asBool(json['can_approve']),
        canRequestInfo: asBool(json['can_request_info']),
        canCancel: asBool(json['can_cancel']),
        canPrepare: asBool(json['can_prepare']),
        canIssue: asBool(json['can_issue']),
        canShowPickupQr: asBool(json['can_show_pickup_qr']),
        canReturn: asBool(json['can_return']),
        canComment: asBool(json['can_comment']),
      );
}

class Requisition {
  const Requisition({
    required this.id,
    required this.requestNo,
    required this.status,
    required this.requesterName,
    this.requesterId = 0,
    this.requesterEmployeeId = '',
    this.requesterDepartment = '',
    this.specialApprovalNeeded = false,
    this.specialReason = '',
    this.items = const [],
    this.approvals = const [],
    this.comments = const [],
    this.stockEvents = const [],
    this.ageHours = 0,
    this.isOverdue = false,
    this.actions = const RequisitionActions(),
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String requestNo;
  final RequisitionStatus status;
  final int requesterId;
  final String requesterName;
  final String requesterEmployeeId;
  final String requesterDepartment;
  final bool specialApprovalNeeded;
  final String specialReason;
  final List<RequisitionLine> items;
  final List<ApprovalRecord> approvals;
  final List<RequisitionComment> comments;
  final List<StockEventRecord> stockEvents;
  final double ageHours;
  final bool isOverdue;
  final RequisitionActions actions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get totalQuantity => items.fold(0, (sum, line) => sum + line.quantity);

  factory Requisition.fromJson(Map<String, dynamic> json) => Requisition(
        id: asInt(json['id']),
        requestNo: asString(json['request_no']),
        status: RequisitionStatus.fromApi(json['status'] as String?),
        requesterId: asInt(json['requester']),
        requesterName: asString(json['requester_name']),
        requesterEmployeeId: asString(json['requester_employee_id']),
        requesterDepartment: asString(json['requester_department']),
        specialApprovalNeeded: asBool(json['special_approval_needed']),
        specialReason: asString(json['special_reason']),
        items: asMapList(json['items']).map(RequisitionLine.fromJson).toList(),
        approvals: asMapList(json['approvals']).map(ApprovalRecord.fromJson).toList(),
        comments: asMapList(json['comments']).map(RequisitionComment.fromJson).toList(),
        stockEvents: asMapList(json['stock_events']).map(StockEventRecord.fromJson).toList(),
        ageHours: asDouble(json['age_hours']),
        isOverdue: asBool(json['is_overdue']),
        actions: RequisitionActions.fromJson(asMap(json['actions'])),
        createdAt: asDate(json['created_at']),
        updatedAt: asDate(json['updated_at']),
      );
}

/// One line in the "create request" cart (also persisted as a draft / offline payload).
class CartLine {
  const CartLine({required this.itemId, required this.code, required this.name, this.size = '', this.quantity = 1, this.reason = RequestReason.damaged});

  final int itemId;
  final String code;
  final String name;
  final String size;
  final int quantity;
  final RequestReason reason;

  CartLine copyWith({String? size, int? quantity, RequestReason? reason}) =>
      CartLine(itemId: itemId, code: code, name: name, size: size ?? this.size, quantity: quantity ?? this.quantity, reason: reason ?? this.reason);

  Map<String, dynamic> toApi() => {'ppe_item_id': itemId, 'quantity': quantity, 'reason': reason.apiValue, 'size': size};

  Map<String, dynamic> toJson() => {...toApi(), 'code': code, 'name': name};

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        itemId: asInt(json['ppe_item_id']),
        code: asString(json['code']),
        name: asString(json['name']),
        size: asString(json['size']),
        quantity: asInt(json['quantity'], 1),
        reason: RequestReason.fromApi(json['reason'] as String?),
      );
}
