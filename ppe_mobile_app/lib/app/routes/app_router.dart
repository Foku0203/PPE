import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/audit_log_screen.dart';
import '../../features/admin/presentation/users_screen.dart';
import '../../features/app_shell/presentation/screens/app_shell.dart';
import '../../features/approval/presentation/screens/approval_screen.dart';
import '../../features/auth/presentation/screens/auth_provider.dart';
import '../../features/auth/presentation/screens/lock_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/catalog/presentation/manage_catalog_screen.dart';
import '../../features/catalog/presentation/ppe_detail_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/inventory/presentation/screens/inventory_item_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/presentation/screens/purchase_requests_screen.dart';
import '../../features/inventory/presentation/screens/qr_scanner_screen.dart';
import '../../features/inventory/presentation/screens/stock_input_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/my_ppe_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/sync_queue_screen.dart';
import '../../features/requisitions/presentation/screens/request_create_screen.dart';
import '../../features/requisitions/presentation/screens/request_detail_screen.dart';
import '../../features/requisitions/presentation/screens/requests_screen.dart';
import '../../features/store/presentation/store_queue_screen.dart';
import 'app_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Re-runs the router redirect whenever authentication state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.status != next.status || previous?.locked != next.locked || previous?.user?.role != next.user?.role) notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  GoRoute pushed(String path, Widget Function(GoRouterState s) builder) =>
      GoRoute(path: path, parentNavigatorKey: rootNavigatorKey, builder: (_, s) => builder(s));

  NoTransitionPage<void> tab(Widget child) => NoTransitionPage(child: child);

  int idParam(GoRouterState s) => int.tryParse(s.pathParameters['id'] ?? '') ?? 0;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isPublic = AppRoutes.publicRoutes.contains(location);
      switch (auth.status) {
        case AuthStatus.unknown:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.unauthenticated:
          return location == AppRoutes.login || location == AppRoutes.register ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          if (auth.locked) return location == AppRoutes.lock ? null : AppRoutes.lock;
          if (isPublic) return AppRoutes.home;
          if (!AppRoutes.canAccess(location, auth.role)) return AppRoutes.home;
          return null;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.lock, builder: (_, _) => const LockScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AppRoutes.home, pageBuilder: (_, _) => tab(const HomeScreen())),
          GoRoute(
            path: AppRoutes.catalog,
            pageBuilder: (_, _) => tab(const CatalogScreen()),
            routes: [
              pushed('manage', (_) => const ManageCatalogScreen()),
              pushed('item/:id', (s) => PpeDetailScreen(itemId: idParam(s))),
            ],
          ),
          GoRoute(
            path: AppRoutes.requests,
            pageBuilder: (_, _) => tab(const RequestsScreen()),
            routes: [
              pushed('new', (_) => const RequestCreateScreen()),
              pushed(':id', (s) => RequestDetailScreen(requisitionId: idParam(s), qrToken: s.uri.queryParameters['qr'])),
            ],
          ),
          GoRoute(path: AppRoutes.approvals, pageBuilder: (_, _) => tab(const ApprovalScreen())),
          GoRoute(path: AppRoutes.store, pageBuilder: (_, _) => tab(const StoreQueueScreen())),
          GoRoute(
            path: AppRoutes.inventory,
            pageBuilder: (_, _) => tab(const InventoryScreen()),
            routes: [
              pushed('receive', (s) => StockInputScreen(
                    ppeItemId: int.tryParse(s.uri.queryParameters['item'] ?? ''),
                    purchaseRequestId: int.tryParse(s.uri.queryParameters['pr'] ?? ''),
                    quantity: int.tryParse(s.uri.queryParameters['qty'] ?? ''),
                  )),
              pushed('purchase-requests', (_) => const PurchaseRequestsScreen()),
              pushed('item/:id', (s) => InventoryItemScreen(itemId: idParam(s))),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (_, _) => tab(const ProfileScreen()),
            routes: [
              pushed('my-ppe', (_) => const MyPpeScreen()),
              pushed('sync', (_) => const SyncQueueScreen()),
            ],
          ),
        ],
      ),
      pushed(AppRoutes.scan, (_) => const QrScannerScreen()),
      pushed(AppRoutes.notifications, (_) => const NotificationsScreen()),
      pushed(AppRoutes.users, (_) => const UsersScreen()),
      pushed(AppRoutes.audit, (_) => const AuditLogScreen()),
      pushed(AppRoutes.analytics, (_) => const DashboardScreen()),
    ],
  );
});
