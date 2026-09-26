import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../../notifications/data/notification_repository.dart';

/// Bottom-navigation shell. Tabs depend on the user's role (README §16: features per role).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((s) => s.role));
    final tabs = AppRoutes.tabsFor(role);
    final index = tabs.indexWhere((t) => location.startsWith(t));
    final selected = index < 0 ? 0 : index;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: scheme.outlineVariant) : null,
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  flex: i == selected ? 5 : 3,
                  child: _PillTab(tab: _tabInfo(context, tabs[i]), selected: i == selected, onTap: () => context.go(tabs[i])),
                ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, IconData, String) _tabInfo(BuildContext context, String tab) {
    final l = context.l10n;
    return switch (tab) {
      AppRoutes.home => (Icons.home_outlined, Icons.home_rounded, l.navHome),
      AppRoutes.catalog => (Icons.inventory_2_outlined, Icons.inventory_2_rounded, l.navCatalog),
      AppRoutes.requests => (Icons.receipt_long_outlined, Icons.receipt_long_rounded, l.navRequests),
      AppRoutes.approvals => (Icons.fact_check_outlined, Icons.fact_check_rounded, l.navApprovals),
      AppRoutes.store => (Icons.local_shipping_outlined, Icons.local_shipping_rounded, l.navStore),
      AppRoutes.inventory => (Icons.warehouse_outlined, Icons.warehouse_rounded, l.navInventory),
      _ => (Icons.person_outline_rounded, Icons.person_rounded, l.navProfile),
    };
  }
}

/// One bottom-nav slot: icon only when idle, navy pill with icon + label when active.
class _PillTab extends StatelessWidget {
  const _PillTab({required this.tab, required this.selected, required this.onTap});

  final (IconData, IconData, String) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, selectedIcon, label) = tab;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(color: selected ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(26)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? selectedIcon : icon, size: 22, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App-bar bell with unread badge.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return IconButton(
      tooltip: context.l10n.notificationsTitle,
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(isLabelVisible: unread > 0, label: Text(unread > 99 ? '99+' : '$unread'), child: const Icon(Icons.notifications_outlined)),
    );
  }
}
