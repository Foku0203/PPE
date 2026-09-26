import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/dashboard_model.dart';
import '../../../../shared/models/requisition_model.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../../inventory/data/inventory_repository.dart';
import 'dashboard_provider.dart';

/// Analytics dashboard (README Phase 3) for supervisors, store, EHS and admins.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final summary = ref.watch(dashboardProvider);
    final isStore = ref.watch(authControllerProvider.select((s) => s.role.isStore));
    return Scaffold(
      appBar: AppBar(title: Text(l.analyticsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          if (isStore) ref.invalidate(inventorySummaryProvider);
        },
        child: AsyncValueView(
          value: summary,
          onRetry: () => ref.invalidate(dashboardProvider),
          data: (data) => ListView(padding: const EdgeInsets.all(16), children: [
            SectionHeader(l.requestPipeline),
            _PipelineChart(data: data),
            if (data.compliance != null) ...[
              SectionHeader(l.complianceTitle),
              _BarRow(
                label: l.complianceBody('${data.compliance!.workers - data.compliance!.workersReplacementDue}', '${data.compliance!.workers}'),
                value: data.compliance!.rate / 100,
                color: data.compliance!.rate >= 90 ? AppColors.success : AppColors.warning,
                trailing: '${data.compliance!.rate.round()}%',
              ),
            ],
            if (isStore) ...[SectionHeader(l.stockHealth), const _StockHealth()],
          ]),
        ),
      ),
    );
  }
}

class _PipelineChart extends StatelessWidget {
  const _PipelineChart({required this.data});

  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = [
      (l.status(RequisitionStatus.pending), data.pendingApproval, AppColors.status(RequisitionStatus.pending)),
      (l.kpiOverdue, data.overdueApproval, AppColors.danger),
      (l.status(RequisitionStatus.approved), data.toPrepare, AppColors.status(RequisitionStatus.approved)),
      (l.status(RequisitionStatus.onHold), data.onHold, AppColors.status(RequisitionStatus.onHold)),
      (l.status(RequisitionStatus.ready), data.readyForPickup, AppColors.status(RequisitionStatus.ready)),
      (l.kpiCompletedToday, data.completedToday, AppColors.neutral),
    ];
    final max = rows.map((r) => r.$2).fold<int>(1, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          for (final (label, value, color) in rows) _BarRow(label: label, value: value / max, color: color, trailing: '$value'),
        ]),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.color, required this.trailing});

  final String label;
  final double value;
  final Color color;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(trailing, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 10,
          color: color,
          backgroundColor: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
      ]),
    );
  }
}

class _StockHealth extends ConsumerWidget {
  const _StockHealth();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final summary = ref.watch(inventorySummaryProvider);
    return AsyncValueView(
      value: summary,
      onRetry: () => ref.invalidate(inventorySummaryProvider),
      data: (items) {
        final low = items.where((i) => i.isLowStock).length;
        final maxIssued = items.map((i) => i.issued30d).fold<int>(1, (a, b) => a > b ? a : b);
        final top = [...items]..sort((a, b) => b.issued30d.compareTo(a.issued30d));
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.stockHealthBody('$low', '${items.length}')),
              const SizedBox(height: 12),
              Text(l.issued30d, style: const TextStyle(fontWeight: FontWeight.w700)),
              for (final item in top.take(6))
                _BarRow(label: item.code, value: item.issued30d / maxIssued, color: item.isLowStock ? AppColors.warning : AppColors.brand, trailing: '${item.issued30d}'),
            ]),
          ),
        );
      },
    );
  }
}
