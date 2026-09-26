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

typedef _Kpi = ({String label, int value, IconData icon, Color color, String route});

/// Role-aware home: headline task, KPI overview, quick access, alerts and recent requests.
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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            await ref.read(offlineQueueProvider.notifier).syncAll();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _Header(user: user),
              const SizedBox(height: 20),
              if (auth.offline) ...[InfoBanner(message: l.offlineBanner, color: AppColors.warning, icon: Icons.wifi_off_rounded), const SizedBox(height: 12)],
              if (queue.isNotEmpty) ...[
                InfoBanner(
                  message: l.pendingSyncBanner('${queue.length}'),
                  color: AppColors.info,
                  icon: Icons.cloud_upload_outlined,
                  action: l.syncNow,
                  onAction: () => context.push(AppRoutes.syncQueue),
                ),
                const SizedBox(height: 12),
              ],
              AsyncValueView(
                value: summary,
                onRetry: () => ref.invalidate(dashboardProvider),
                data: (data) => _HomeBody(user: user, data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.ink,
          child: Text(
            user.initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l.greeting('').trim(), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Pill(label: l.roleName(user.role), color: AppColors.brand, dense: true),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CircleSurface(child: const NotificationBell()),
      ],
    );
  }
}

/// White circle with a soft shadow, for header icon buttons.
class _CircleSurface extends StatelessWidget {
  const _CircleSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        shape: BoxShape.circle,
        boxShadow: AppTheme.softShadow(context),
        border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: Theme.of(context).colorScheme.outlineVariant) : null,
      ),
      child: child,
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
    final kpis = _kpis(context, role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.replacementDue.isNotEmpty) ...[
          InfoBanner(
            message: l.replacementDueBody('${data.replacementDue.length}', data.replacementDue.map((r) => r.code).join(', ')),
            color: AppColors.warning,
            icon: Icons.autorenew_rounded,
            action: l.actionNewRequest,
            onAction: () => context.push(AppRoutes.newRequest),
          ),
          const SizedBox(height: 12),
        ],
        _HeroCard(kpi: kpis.first),
        if (kpis.length > 1) ...[const SizedBox(height: 14), _OverviewCard(title: l.actionAnalytics, kpis: kpis.skip(1).toList())],
        SectionHeader(l.quickActions),
        _QuickAccess(role: role),
        const SizedBox(height: 20),
        const PromoCarousel(),
        if (role.isStore && data.lowStock.isNotEmpty) ...[
          SectionHeader(l.lowStockTitle, action: l.seeAll, onAction: () => context.go(AppRoutes.inventory)),
          Card(
            child: Column(
              children: [
                for (final row in data.lowStock)
                  ListTile(
                    leading: PpeImage(code: row.code, size: 40, radius: 12),
                    title: Text(row.code, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(l.availableOfReorder('${row.available}', '${row.reorderPoint}')),
                    trailing: Icon(Icons.warning_amber_rounded, color: row.available == 0 ? AppColors.danger : AppColors.warning),
                    onTap: () => context.push(AppRoutes.inventoryItem(row.ppeItemId)),
                  ),
              ],
            ),
          ),
        ],
        if (data.compliance != null) ...[SectionHeader(l.complianceTitle), _ComplianceCard(compliance: data.compliance!)],
        SectionHeader(l.recentRequests, action: l.seeAll, onAction: () => context.go(AppRoutes.requests)),
        if (data.recent.isEmpty)
          EmptyState(icon: Icons.receipt_long_outlined, message: l.noRecentRequests)
        else
          for (final r in data.recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RequisitionCard(requisition: r, showRequester: role != UserRole.worker, onTap: () => context.push(AppRoutes.request(r.id))),
            ),
      ],
    );
  }

  /// First entry is the role's headline task (hero card); the rest go to the overview card.
  List<_Kpi> _kpis(BuildContext context, UserRole role) {
    final l = context.l10n;
    _Kpi kpi(String label, int value, IconData icon, Color color, String route) => (label: label, value: value, icon: icon, color: color, route: route);
    final myOpen = kpi(l.kpiMyOpen, data.myOpen, Icons.pending_actions_rounded, AppColors.info, AppRoutes.requests);
    final pending = kpi(l.kpiPendingApproval, data.pendingApproval, Icons.fact_check_rounded, AppColors.special, AppRoutes.approvals);
    final overdue = kpi(l.kpiOverdue, data.overdueApproval, Icons.timer_off_rounded, AppColors.danger, AppRoutes.approvals);
    final toPrepare = kpi(l.kpiToPrepare, data.toPrepare, Icons.inventory_rounded, AppColors.brand, AppRoutes.store);
    final onHold = kpi(l.kpiOnHold, data.onHold, Icons.pause_circle_outline_rounded, AppColors.warning, role.isStore ? AppRoutes.store : AppRoutes.requests);
    final ready = kpi(
      l.kpiReadyForPickup,
      role == UserRole.worker ? data.myReady : data.readyForPickup,
      Icons.local_shipping_rounded,
      AppColors.success,
      role.isStore ? AppRoutes.store : AppRoutes.requests,
    );
    final lowStock = kpi(l.kpiLowStock, data.lowStockItems, Icons.warning_amber_rounded, AppColors.warning, AppRoutes.inventory);
    final today = kpi(l.kpiCompletedToday, data.completedToday, Icons.task_alt_rounded, AppColors.success, AppRoutes.requests);
    return switch (role) {
      UserRole.worker => [ready, myOpen, kpi(l.kpiMyCompleted, data.myCompleted, Icons.verified_rounded, AppColors.neutral, AppRoutes.requests)],
      UserRole.supervisor => [
        pending,
        overdue,
        kpi(l.kpiOpenRequests, data.openRequisitions, Icons.groups_rounded, AppColors.info, AppRoutes.requests),
        myOpen,
      ],
      UserRole.storeKeeper => [toPrepare, ready, onHold, lowStock, today],
      UserRole.ehs => [pending, overdue, lowStock, onHold],
      UserRole.admin => [pending, toPrepare, ready, lowStock, overdue, today],
    };
  }
}

/// Deep-navy headline card: the one number this role should act on first.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final radius = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x330E1B3D), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.inkLight]),
            ),
            child: InkWell(
              onTap: () => context.go(kpi.route),
              child: Stack(
                children: [
                  // Oversized faded icon as the card's illustration.
                  Positioned(right: -18, top: -10, child: Icon(kpi.icon, size: 150, color: Colors.white.withValues(alpha: 0.07))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                              child: Icon(kpi.icon, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                kpi.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${kpi.value}',
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, height: 1.05),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(l.seeAll, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.ink, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft-blue card with the remaining KPIs in columns separated by hairlines.
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.title, required this.kpis});

  final String title;
  final List<_Kpi> kpis;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final divider = dark ? scheme.outlineVariant : Colors.white.withValues(alpha: 0.9);
    // 4 → 2×2 reads better than 3+1; otherwise up to three per row.
    final perRow = kpis.length == 4 ? 2 : 3;
    final rows = [for (var i = 0; i < kpis.length; i += perRow) kpis.sublist(i, (i + perRow).clamp(0, kpis.length))];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark ? const [Color(0xFF1B2A47), Color(0xFF151E31)] : const [AppColors.sky, AppColors.skyLight],
        ),
        borderRadius: BorderRadius.circular(24),
        border: dark ? Border.all(color: scheme.outlineVariant) : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) Divider(color: divider, height: 1),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A short last row stretches its cells instead of leaving empty slots.
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) VerticalDivider(color: divider, width: 1, thickness: 1),
                    Expanded(child: _OverviewStat(kpi: rows[r][i])),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go(kpi.route),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 34,
              child: Text(kpi.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(height: 1.3)),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('${kpi.value}', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26))),
                Icon(kpi.icon, size: 18, color: AppColors.readable(context, kpi.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Round icon buttons with labels underneath, four per row.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.add_shopping_cart_rounded, l.actionNewRequest, () => context.push(AppRoutes.newRequest)),
      (Icons.inventory_2_outlined, l.navCatalog, () => context.go(AppRoutes.catalog)),
      if (role == UserRole.worker || role == UserRole.supervisor) (Icons.backpack_outlined, l.actionMyPpe, () => context.push(AppRoutes.myPpe)),
      if (role.canApprove) (Icons.fact_check_outlined, l.navApprovals, () => context.go(AppRoutes.approvals)),
      if (role.isStore) (Icons.qr_code_scanner_rounded, l.actionScanQr, () => context.push(AppRoutes.scan)),
      if (role.isStore) (Icons.move_to_inbox_outlined, l.actionReceiveStock, () => context.push(AppRoutes.receiveStock)),
      if (role.isStore) (Icons.shopping_bag_outlined, l.actionPurchaseRequests, () => context.push(AppRoutes.purchaseRequests)),
      if (role != UserRole.worker) (Icons.insights_rounded, l.actionAnalytics, () => context.push(AppRoutes.analytics)),
      if (role.canViewAudit) (Icons.history_edu_outlined, l.actionAuditLog, () => context.push(AppRoutes.audit)),
      if (role.isAdmin) (Icons.manage_accounts_outlined, l.actionUsers, () => context.push(AppRoutes.users)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 560 ? 6 : 4;
            final width = constraints.maxWidth / columns;
            return Wrap(
              runSpacing: 16,
              children: [
                for (var i = 0; i < actions.length; i++)
                  SizedBox(
                    width: width,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: actions[i].$3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(color: i == 0 ? scheme.primaryContainer : scheme.surfaceContainer, shape: BoxShape.circle),
                              child: Icon(actions[i].$1, size: 24, color: i == 0 ? scheme.onPrimaryContainer : scheme.onSurface),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              actions[i].$2,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
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
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: compliance.rate / 100,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                  Center(
                    child: Text('${compliance.rate.round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(context.l10n.complianceBody('$ok', '${compliance.workers}'))),
          ],
        ),
      ),
    );
  }
}
