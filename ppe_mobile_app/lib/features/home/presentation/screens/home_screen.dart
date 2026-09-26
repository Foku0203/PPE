import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/dashboard_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../../shared/widgets/requisition_card.dart';
import '../../../app_shell/presentation/screens/app_shell.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../../dashboard/presentation/screens/dashboard_provider.dart';
import '../../../requisitions/data/offline_queue.dart';
import '../widgets/promo_carousel.dart';

/// Role-aware home: KPIs, alerts, quick actions and recent requests.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user!;
    final summary = ref.watch(dashboardProvider);
    final queue = ref.watch(offlineQueueProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          CircleAvatar(radius: 18, child: Text(user.initials, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.greeting(user.displayName), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(l.roleName(user.role), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          await ref.read(offlineQueueProvider.notifier).syncAll();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const PromoCarousel(),
            const SizedBox(height: 12),
            if (auth.offline) ...[
              InfoBanner(message: l.offlineBanner, color: AppColors.warning, icon: Icons.wifi_off),
              const SizedBox(height: 8),
            ],
            if (queue.isNotEmpty) ...[
              InfoBanner(
                message: l.pendingSyncBanner('${queue.length}'),
                color: AppColors.info,
                icon: Icons.cloud_upload_outlined,
                action: l.syncNow,
                onAction: () => context.push(AppRoutes.syncQueue),
              ),
              const SizedBox(height: 8),
            ],
            AsyncValueView(
              value: summary,
              onRetry: () => ref.invalidate(dashboardProvider),
              data: (data) => _HomeBody(user: user, data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.user, required this.data});

  final AppUser user;
  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = user.role;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (data.replacementDue.isNotEmpty) ...[
        InfoBanner(
          message: l.replacementDueBody('${data.replacementDue.length}', data.replacementDue.map((r) => r.code).join(', ')),
          color: AppColors.warning,
          icon: Icons.autorenew,
          action: l.actionNewRequest,
          onAction: () => context.push(AppRoutes.newRequest),
        ),
        const SizedBox(height: 8),
      ],
      _KpiGrid(cards: _kpis(context, role)),
      SectionHeader(l.quickActions),
      _QuickActions(role: role),
      if (role.isStore && data.lowStock.isNotEmpty) ...[
        SectionHeader(l.lowStockTitle, action: l.seeAll, onAction: () => context.go(AppRoutes.inventory)),
        Card(
          child: Column(children: [
            for (final row in data.lowStock)
              ListTile(
                dense: true,
                leading: PpeImage(code: row.code, size: 36, radius: 8),
                title: Text(row.code),
                subtitle: Text(l.availableOfReorder('${row.available}', '${row.reorderPoint}')),
                trailing: Icon(Icons.warning_amber_rounded, color: row.available == 0 ? AppColors.danger : AppColors.warning),
                onTap: () => context.push(AppRoutes.inventoryItem(row.ppeItemId)),
              ),
          ]),
        ),
      ],
      if (data.compliance != null) ...[
        SectionHeader(l.complianceTitle),
        _ComplianceCard(compliance: data.compliance!),
      ],
      SectionHeader(l.recentRequests, action: l.seeAll, onAction: () => context.go(AppRoutes.requests)),
      if (data.recent.isEmpty)
        EmptyState(icon: Icons.receipt_long_outlined, message: l.noRecentRequests)
      else
        for (final r in data.recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RequisitionCard(requisition: r, showRequester: role != UserRole.worker, onTap: () => context.push(AppRoutes.request(r.id))),
          ),
    ]);
  }

  List<Widget> _kpis(BuildContext context, UserRole role) {
    final l = context.l10n;
    KpiCard card(String label, int value, IconData icon, Color color, String route) =>
        KpiCard(label: label, value: '$value', icon: icon, color: color, onTap: () => context.go(route));
    final myOpen = card(l.kpiMyOpen, data.myOpen, Icons.pending_actions, AppColors.info, AppRoutes.requests);
    final pending = card(l.kpiPendingApproval, data.pendingApproval, Icons.fact_check, AppColors.special, AppRoutes.approvals);
    final overdue = card(l.kpiOverdue, data.overdueApproval, Icons.timer_off_outlined, AppColors.danger, AppRoutes.approvals);
    final toPrepare = card(l.kpiToPrepare, data.toPrepare, Icons.inventory, AppColors.brand, AppRoutes.store);
    final onHold = card(l.kpiOnHold, data.onHold, Icons.pause_circle_outline, AppColors.warning, role.isStore ? AppRoutes.store : AppRoutes.requests);
    final ready = card(l.kpiReadyForPickup, role == UserRole.worker ? data.myReady : data.readyForPickup, Icons.local_shipping, AppColors.success,
        role.isStore ? AppRoutes.store : AppRoutes.requests);
    final lowStock = card(l.kpiLowStock, data.lowStockItems, Icons.warning_amber_rounded, AppColors.warning, AppRoutes.inventory);
    final today = card(l.kpiCompletedToday, data.completedToday, Icons.task_alt, AppColors.success, AppRoutes.requests);
    return switch (role) {
      UserRole.worker => [myOpen, ready, card(l.kpiMyCompleted, data.myCompleted, Icons.verified, AppColors.neutral, AppRoutes.requests)],
      UserRole.supervisor => [pending, overdue, card(l.kpiOpenRequests, data.openRequisitions, Icons.groups, AppColors.info, AppRoutes.requests), myOpen],
      UserRole.storeKeeper => [toPrepare, ready, onHold, lowStock, today],
      UserRole.ehs => [pending, overdue, lowStock, onHold],
      UserRole.admin => [pending, toPrepare, ready, lowStock, overdue, today],
    };
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 700 ? 4 : (constraints.maxWidth > 420 ? 3 : 2);
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(spacing: gap, runSpacing: gap, children: [for (final c in cards) SizedBox(width: width, child: c)]);
    });
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.add_shopping_cart, l.actionNewRequest, () => context.push(AppRoutes.newRequest)),
      (Icons.inventory_2_outlined, l.navCatalog, () => context.go(AppRoutes.catalog)),
      if (role == UserRole.worker || role == UserRole.supervisor) (Icons.backpack_outlined, l.actionMyPpe, () => context.push(AppRoutes.myPpe)),
      if (role.canApprove) (Icons.fact_check_outlined, l.navApprovals, () => context.go(AppRoutes.approvals)),
      if (role.isStore) (Icons.qr_code_scanner, l.actionScanQr, () => context.push(AppRoutes.scan)),
      if (role.isStore) (Icons.move_to_inbox_outlined, l.actionReceiveStock, () => context.push(AppRoutes.receiveStock)),
      if (role.isStore) (Icons.shopping_bag_outlined, l.actionPurchaseRequests, () => context.push(AppRoutes.purchaseRequests)),
      if (role != UserRole.worker) (Icons.insights_outlined, l.actionAnalytics, () => context.push(AppRoutes.analytics)),
      if (role.canViewAudit) (Icons.history_edu_outlined, l.actionAuditLog, () => context.push(AppRoutes.audit)),
      if (role.isAdmin) (Icons.manage_accounts_outlined, l.actionUsers, () => context.push(AppRoutes.users)),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final (icon, label, onTap) in actions) ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: onTap),
    ]);
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.compliance});

  final ComplianceSummary compliance;

  @override
  Widget build(BuildContext context) {
    final ok = compliance.workers - compliance.workersReplacementDue;
    final color = compliance.rate >= 90 ? AppColors.success : (compliance.rate >= 70 ? AppColors.warning : AppColors.danger);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(value: compliance.rate / 100, strokeWidth: 7, color: color, backgroundColor: color.withValues(alpha: 0.15)),
              Center(child: Text('${compliance.rate.round()}%', style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(context.l10n.complianceBody('$ok', '${compliance.workers}'))),
        ]),
      ),
    );
  }
}
