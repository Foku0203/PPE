import '../../core/utils/json.dart';
import 'requisition_model.dart';

class LowStockEntry {
  const LowStockEntry({required this.ppeItemId, required this.code, required this.available, required this.reorderPoint});

  final int ppeItemId;
  final String code;
  final int available;
  final int reorderPoint;

  factory LowStockEntry.fromJson(Map<String, dynamic> json) => LowStockEntry(
        ppeItemId: asInt(json['ppe_item_id']),
        code: asString(json['code']),
        available: asInt(json['available']),
        reorderPoint: asInt(json['reorder_point']),
      );
}

class ReplacementDue {
  const ReplacementDue({required this.ppeItemId, required this.code, this.dueAt});

  final int ppeItemId;
  final String code;
  final DateTime? dueAt;

  factory ReplacementDue.fromJson(Map<String, dynamic> json) =>
      ReplacementDue(ppeItemId: asInt(json['ppe_item_id']), code: asString(json['code']), dueAt: asDate(json['due_at']));
}

class ComplianceSummary {
  const ComplianceSummary({required this.workers, required this.workersReplacementDue, required this.rate});

  final int workers;
  final int workersReplacementDue;
  final double rate;

  factory ComplianceSummary.fromJson(Map<String, dynamic> json) => ComplianceSummary(
        workers: asInt(json['workers']),
        workersReplacementDue: asInt(json['workers_replacement_due']),
        rate: asDouble(json['rate'], 100),
      );
}

/// Role-scoped KPIs from `GET /dashboard/summary/`.
class DashboardSummary {
  const DashboardSummary({
    this.myOpen = 0,
    this.myReady = 0,
    this.myCompleted = 0,
    this.replacementDue = const [],
    this.pendingApproval = 0,
    this.overdueApproval = 0,
    this.toPrepare = 0,
    this.onHold = 0,
    this.readyForPickup = 0,
    this.completedToday = 0,
    this.openRequisitions = 0,
    this.lowStockItems = 0,
    this.lowStock = const [],
    this.compliance,
    this.recent = const [],
  });

  final int myOpen;
  final int myReady;
  final int myCompleted;
  final List<ReplacementDue> replacementDue;
  final int pendingApproval;
  final int overdueApproval;
  final int toPrepare;
  final int onHold;
  final int readyForPickup;
  final int completedToday;
  final int openRequisitions;
  final int lowStockItems;
  final List<LowStockEntry> lowStock;
  final ComplianceSummary? compliance;
  final List<Requisition> recent;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        myOpen: asInt(json['my_open']),
        myReady: asInt(json['my_ready']),
        myCompleted: asInt(json['my_completed']),
        replacementDue: asMapList(json['replacement_due']).map(ReplacementDue.fromJson).toList(),
        pendingApproval: asInt(json['pending_approval']),
        overdueApproval: asInt(json['overdue_approval']),
        toPrepare: asInt(json['to_prepare']),
        onHold: asInt(json['on_hold']),
        readyForPickup: asInt(json['ready_for_pickup']),
        completedToday: asInt(json['completed_today']),
        openRequisitions: asInt(json['open_requisitions']),
        lowStockItems: asInt(json['low_stock_items']),
        lowStock: asMapList(json['low_stock']).map(LowStockEntry.fromJson).toList(),
        compliance: json['compliance'] is Map ? ComplianceSummary.fromJson(asMap(json['compliance'])) : null,
        recent: asMapList(json['recent']).map(Requisition.fromJson).toList(),
      );
}
