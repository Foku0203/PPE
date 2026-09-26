/// REST contract with the Django backend (`backend/ppe/urls.py`). Paths are relative to the base URL.
class ApiEndpoints {
  // Auth & profile
  static const login = '/auth/token/';
  static const refresh = '/auth/token/refresh/';
  static const register = '/auth/register/';
  static const logout = '/auth/logout/';
  static const me = '/me/';
  static const changePassword = '/me/password/';
  static const myIssuedItems = '/me/issued-items/';
  static const users = '/users/';
  static String user(int id) => '/users/$id/';
  static const deviceToken = '/devices/token/';

  // Notifications
  static const notifications = '/notifications/';
  static const notificationsReadAll = '/notifications/read-all/';
  static const notificationsUnreadCount = '/notifications/unread-count/';
  static String notificationRead(int id) => '/notifications/$id/read/';

  // Catalog
  static const catalog = '/catalog/ppe/';
  static String catalogItem(int id) => '/catalog/ppe/$id/';
  static String eligibility(int id) => '/catalog/ppe/$id/eligibility/';

  // Requisitions
  static const requisitions = '/requisitions/';
  static String requisition(int id) => '/requisitions/$id/';
  static String cancel(int id) => '/requisitions/$id/cancel/';
  static String approvals(int id) => '/requisitions/$id/approvals/';
  static String comments(int id) => '/requisitions/$id/comments/';
  static String pickupQr(int id) => '/requisitions/$id/pickup-qr/';
  static String prepare(int id) => '/requisitions/$id/prepare/';
  static String issue(int id) => '/requisitions/$id/issue/';
  static String returnItem(int lineId) => '/requisition-items/$lineId/return/';

  // Inventory
  static const lots = '/inventory/lots/';
  static String adjustLot(int id) => '/inventory/lots/$id/adjust/';
  static const inventorySummary = '/inventory/summary/';
  static const stockEvents = '/inventory/events/';
  static const qrResolve = '/inventory/scan/resolve/';
  static const purchaseRequests = '/purchase-requests/';
  static String purchaseRequestStatus(int id) => '/purchase-requests/$id/status/';

  // Dashboard & audit
  static const dashboard = '/dashboard/summary/';
  static const auditLogs = '/audit-logs/';
}
