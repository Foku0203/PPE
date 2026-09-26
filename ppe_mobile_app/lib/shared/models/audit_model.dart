import '../../core/utils/json.dart';

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.entityId,
    this.actorName,
    this.actorEmployeeId,
    this.before,
    this.after,
    this.createdAt,
  });

  final int id;
  final String action;
  final String entity;
  final String entityId;
  final String? actorName;
  final String? actorEmployeeId;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime? createdAt;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: asInt(json['id']),
        action: asString(json['action']),
        entity: asString(json['entity']),
        entityId: asString(json['entity_id']),
        actorName: json['actor_name'] as String?,
        actorEmployeeId: json['actor_employee_id'] as String?,
        before: json['before'] is Map ? asMap(json['before']) : null,
        after: json['after'] is Map ? asMap(json['after']) : null,
        createdAt: asDate(json['created_at']),
      );
}
