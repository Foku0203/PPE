import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(tabs[i]),
        destinations: [for (final tab in tabs) _destination(context, tab)],
      ),
    );
  }

  NavigationDestination _destination(BuildContext context, String tab) {
    final l = context.l10n;
    final (IconData icon, IconData selected, String label) = switch (tab) {
      AppRoutes.home => (Icons.home_outlined, Icons.home, l.navHome),
      AppRoutes.catalog => (Icons.inventory_2_outlined, Icons.inventory_2, l.navCatalog),
      AppRoutes.requests => (Icons.receipt_long_outlined, Icons.receipt_long, l.navRequests),
      AppRoutes.approvals => (Icons.fact_check_outlined, Icons.fact_check, l.navApprovals),
      AppRoutes.store => (Icons.local_shipping_outlined, Icons.local_shipping, l.navStore),
      AppRoutes.inventory => (Icons.warehouse_outlined, Icons.warehouse, l.navInventory),
      _ => (Icons.person_outline, Icons.person, l.navProfile),
    };
    return NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label);
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
