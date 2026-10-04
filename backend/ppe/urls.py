from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    # Auth & profile
    path('auth/token/', views.EmployeeIdTokenView.as_view(), name='auth_token'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', views.RegisterView.as_view(), name='auth_register'),
    path('auth/supervisors/', views.SupervisorOptionsView.as_view(), name='auth_supervisors'),
    path('auth/logout/', views.LogoutView.as_view(), name='auth_logout'),
    path('me/', views.UserMeView.as_view(), name='user_me'),
    path('me/password/', views.ChangePasswordView.as_view(), name='user_password'),
    path('me/issued-items/', views.MyIssuedItemsView.as_view(), name='user_issued_items'),
    path('users/', views.UserListView.as_view(), name='user_list'),
    path('users/<int:pk>/', views.UserDetailView.as_view(), name='user_detail'),
    path('users/<int:pk>/transfer-team/', views.UserTeamTransferView.as_view(), name='user_transfer_team'),
    path('devices/token/', views.DeviceTokenView.as_view(), name='device_token'),
    # Notifications
    path('notifications/', views.NotificationListView.as_view(), name='notification_list'),
    path('notifications/read-all/', views.NotificationReadAllView.as_view(), name='notification_read_all'),
    path('notifications/unread-count/', views.NotificationUnreadCountView.as_view(), name='notification_unread_count'),
    path('notifications/<int:pk>/read/', views.NotificationReadView.as_view(), name='notification_read'),
    # Catalog
    path('catalog/ppe/', views.PpeCatalogView.as_view(), name='ppe_catalog'),
    path('catalog/ppe/<int:pk>/', views.PpeItemDetailView.as_view(), name='ppe_detail'),
    path('catalog/ppe/<int:pk>/eligibility/', views.PpeEligibilityView.as_view(), name='ppe_eligibility'),
    # Requisitions
    path('requisitions/', views.RequisitionListCreateView.as_view(), name='requisition_list_create'),
    path('requisitions/<int:pk>/', views.RequisitionDetailView.as_view(), name='requisition_detail'),
    path('requisitions/<int:pk>/cancel/', views.RequisitionCancelView.as_view(), name='requisition_cancel'),
    path('requisitions/<int:pk>/approvals/', views.ApprovalView.as_view(), name='requisition_approval'),
    path('requisitions/<int:pk>/comments/', views.RequisitionCommentView.as_view(), name='requisition_comments'),
    path('requisitions/<int:pk>/pickup-qr/', views.RequisitionPickupQRView.as_view(), name='requisition_pickup_qr'),
    path('requisitions/<int:pk>/prepare/', views.InventoryPrepareView.as_view(), name='inventory_prepare'),
    path('requisitions/<int:pk>/issue/', views.InventoryIssueView.as_view(), name='inventory_issue'),
    path('requisition-items/<int:pk>/return/', views.InventoryReturnView.as_view(), name='inventory_return'),
    # Inventory
    path('inventory/lots/', views.InventoryListView.as_view(), name='inventory_list'),
    path('inventory/lots/<int:pk>/adjust/', views.StockLotAdjustView.as_view(), name='inventory_adjust'),
    path('inventory/summary/', views.InventorySummaryView.as_view(), name='inventory_summary'),
    path('inventory/events/', views.StockEventListView.as_view(), name='inventory_events'),
    path('inventory/scan/challenge/', views.QRChallengeView.as_view(), name='qr_challenge'),
    path('inventory/scan/resolve/', views.QRResolveView.as_view(), name='qr_resolve'),
    path('purchase-requests/', views.PurchaseRequestListCreateView.as_view(), name='purchase_requests'),
    path('purchase-requests/<int:pk>/status/', views.PurchaseRequestStatusView.as_view(), name='purchase_request_status'),
    # Dashboard & audit
    path('dashboard/summary/', views.DashboardView.as_view(), name='dashboard_summary'),
    path('audit-logs/', views.AuditLogListView.as_view(), name='audit_logs'),
]
