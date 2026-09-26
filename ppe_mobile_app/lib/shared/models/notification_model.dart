import '../../core/utils/json.dart';

enum NotificationKind {
  newRequisition('NEW_REQUISITION'),
  approvalResult('APPROVAL_RESULT'),
  readyForPickup('READY_FOR_PICKUP'),
  reorderPoint('REORDER_POINT'),
  infoRequested('INFO_REQUESTED'),
  issued('ISSUED'),
  onHold('ON_HOLD'),
  other('');

  const NotificationKind(this.apiValue);
  final String apiValue;

  static NotificationKind fromApi(String? value) => NotificationKind.values.firstWhere((k) => k.apiValue == value, orElse: () => NotificationKind.other);
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    this.payload = const {},
    this.readAt,
    this.createdAt,
  });

  final int id;
  final NotificationKind kind;
  final String title;
  final String message;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;
  int? get requisitionId => asIntOrNull(payload['requisition_id']);
  int? get ppeItemId => asIntOrNull(payload['ppe_item_id']);
  String? get requestNo => payload['request_no'] as String?;
  String? get status => payload['status'] as String?;

  AppNotification copyWith({DateTime? readAt, bool clearRead = false}) => AppNotification(
        id: id,
        kind: kind,
        title: title,
        message: message,
        payload: payload,
        readAt: clearRead ? null : (readAt ?? this.readAt),
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: asInt(json['id']),
        kind: NotificationKind.fromApi(json['notification_type'] as String?),
        title: asString(json['title']),
        message: asString(json['message']),
        payload: asMap(json['payload']),
        readAt: asDate(json['read_at']),
        createdAt: asDate(json['created_at']),
      );
}
