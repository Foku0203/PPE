import '../../shared/models/user_model.dart';

/// Route paths. Detail routes are pushed full-screen over the tab shell.
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const lock = '/lock';

  // Shell tabs
  static const home = '/home';
  static const catalog = '/catalog';
  static const requests = '/requests';
  static const approvals = '/approvals';
  static const store = '/store';
  static const inventory = '/inventory';
  static const profile = '/profile';

  // Pushed pages
  static String ppeItem(int id) => '/catalog/item/$id';
  static const manageCatalog = '/catalog/manage';
  static const newRequest = '/requests/new';
  static String request(int id, {String? qrToken}) => qrToken == null ? '/requests/$id' : '/requests/$id?qr=${Uri.encodeQueryComponent(qrToken)}';
  static String inventoryItem(int id) => '/inventory/item/$id';
  static const receiveStock = '/inventory/receive';
  static const purchaseRequests = '/inventory/purchase-requests';
  static const scan = '/scan';
  static const notifications = '/notifications';
  static const myPpe = '/profile/my-ppe';
  static const syncQueue = '/profile/sync';
  static const users = '/admin/users';
  static const audit = '/admin/audit';
  static const analytics = '/analytics';

  static const publicRoutes = {splash, login, register, lock};

  /// Role-based route guard (README §8: role-based access). The backend enforces the same rules.
  static bool canAccess(String location, UserRole role) {
    if (location.startsWith('/approvals')) return role.canApprove;
    if (location.startsWith('/store') || location.startsWith('/inventory') || location.startsWith(scan)) return role.isStore;
    if (location.startsWith(manageCatalog)) return role.canManageMasterData;
    if (location.startsWith(users)) return role.isAdmin;
    if (location.startsWith(audit)) return role.canViewAudit;
    if (location.startsWith(analytics)) return role != UserRole.worker;
    return true;
  }

  /// Bottom navigation tabs for each role.
  static List<String> tabsFor(UserRole role) => switch (role) {
        UserRole.worker => const [home, catalog, requests, profile],
        UserRole.supervisor => const [home, approvals, requests, catalog, profile],
        UserRole.storeKeeper => const [home, store, inventory, requests, profile],
        UserRole.ehs => const [home, approvals, inventory, catalog, profile],
        UserRole.admin => const [home, approvals, store, inventory, profile],
      };
}
