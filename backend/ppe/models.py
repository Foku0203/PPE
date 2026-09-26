from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone


class Locale(models.TextChoices):
    TH = 'TH', 'Thai'
    EN = 'EN', 'English'
    MY = 'MY', 'Myanmar'
    ZH = 'ZH', 'Chinese'


class Role(models.TextChoices):
    WORKER = 'WORKER', 'Worker'
    SUPERVISOR = 'SUPERVISOR', 'Supervisor'
    STORE_KEEPER = 'STORE_KEEPER', 'Store Keeper'
    EHS = 'EHS', 'EHS'
    ADMIN = 'ADMIN', 'Admin'


class PermissionCode(models.TextChoices):
    CREATE_REQUISITION = 'CREATE_REQUISITION', 'Create requisition'
    APPROVE_REQUEST = 'APPROVE_REQUEST', 'Approve request'
    SPECIAL_APPROVAL = 'SPECIAL_APPROVAL', 'Special approval'
    MANAGE_STOCK = 'MANAGE_STOCK', 'Manage stock'
    ISSUE_STOCK = 'ISSUE_STOCK', 'Issue stock'
    MANAGE_MASTER_DATA = 'MANAGE_MASTER_DATA', 'Manage master data'
    VIEW_DASHBOARD = 'VIEW_DASHBOARD', 'View dashboard'


ROLE_PERMISSIONS = {
    Role.WORKER: {PermissionCode.CREATE_REQUISITION, PermissionCode.VIEW_DASHBOARD},
    Role.SUPERVISOR: {PermissionCode.CREATE_REQUISITION, PermissionCode.APPROVE_REQUEST, PermissionCode.SPECIAL_APPROVAL, PermissionCode.VIEW_DASHBOARD},
    Role.STORE_KEEPER: {PermissionCode.CREATE_REQUISITION, PermissionCode.APPROVE_REQUEST, PermissionCode.MANAGE_STOCK, PermissionCode.ISSUE_STOCK, PermissionCode.VIEW_DASHBOARD},
    Role.EHS: {PermissionCode.CREATE_REQUISITION, PermissionCode.APPROVE_REQUEST, PermissionCode.SPECIAL_APPROVAL, PermissionCode.MANAGE_STOCK, PermissionCode.MANAGE_MASTER_DATA, PermissionCode.VIEW_DASHBOARD},
    Role.ADMIN: set(PermissionCode.values),
}


class DevicePlatform(models.TextChoices):
    IOS = 'IOS', 'iOS'
    ANDROID = 'ANDROID', 'Android'
    WEB = 'WEB', 'Web'


class NotificationType(models.TextChoices):
    NEW_REQUISITION = 'NEW_REQUISITION', 'New Requisition'
    APPROVAL_RESULT = 'APPROVAL_RESULT', 'Approval Result'
    READY_FOR_PICKUP = 'READY_FOR_PICKUP', 'Ready for Pickup'
    REORDER_POINT = 'REORDER_POINT', 'Reorder Point Alert'


class User(AbstractUser):
    username = models.CharField(max_length=64, unique=True)
    employee_id = models.CharField(max_length=32, unique=True)
    display_name = models.CharField(max_length=160)
    phone_number = models.CharField(max_length=20, blank=True)
    department = models.CharField(max_length=120, blank=True)
    locale = models.CharField(max_length=2, choices=Locale.choices, default=Locale.TH)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.WORKER)
    supervisor = models.ForeignKey('self', null=True, blank=True, on_delete=models.SET_NULL, related_name='team_members')

    def has_permission_code(self, permission: str) -> bool:
        return permission in ROLE_PERMISSIONS.get(self.role, set())

    def __str__(self) -> str:
        return f'{self.employee_id} - {self.display_name}'


class PpeItem(models.Model):
    code = models.CharField(max_length=40, unique=True)
    icon_key = models.CharField(max_length=40, default='shield')
    image_url = models.URLField(blank=True)
    unit = models.CharField(max_length=30, default='piece')
    is_returnable = models.BooleanField(default=False)
    quota = models.PositiveIntegerField(null=True, blank=True)
    lifespan_days = models.PositiveIntegerField(null=True, blank=True)
    reorder_point = models.PositiveIntegerField(default=0)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class PpeTranslation(models.Model):
    ppe_item = models.ForeignKey(PpeItem, on_delete=models.CASCADE, related_name='translations')
    locale = models.CharField(max_length=2, choices=Locale.choices)
    name = models.CharField(max_length=180)
    short_name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['ppe_item', 'locale'], name='unique_ppe_locale')]


class SerialStatus(models.TextChoices):
    AVAILABLE = 'AVAILABLE', 'Available'
    RESERVED = 'RESERVED', 'Reserved'
    ISSUED = 'ISSUED', 'Issued'
    RETURNED = 'RETURNED', 'Returned'
    DAMAGED = 'DAMAGED', 'Damaged'
    EXPIRED = 'EXPIRED', 'Expired'


class StockLot(models.Model):
    ppe_item = models.ForeignKey(PpeItem, on_delete=models.PROTECT, related_name='stock_lots')
    lot_number = models.CharField(max_length=80, blank=True)
    serial_number = models.CharField(max_length=120, blank=True, unique=True, null=True)
    supplier = models.CharField(max_length=160, blank=True)
    quantity = models.PositiveIntegerField(default=0)
    reserved_quantity = models.PositiveIntegerField(default=0)
    expiry_at = models.DateTimeField(null=True, blank=True)
    manufactured_at = models.DateTimeField(null=True, blank=True)
    inspected_at = models.DateTimeField(null=True, blank=True)
    serial_status = models.CharField(max_length=20, choices=SerialStatus.choices, default=SerialStatus.AVAILABLE)

    @property
    def available_quantity(self) -> int:
        return self.quantity - self.reserved_quantity


class RequisitionType(models.TextChoices):
    ISSUE = 'ISSUE', 'Request for Issue'
    RETURN = 'RETURN', 'Request for Return'


class RequisitionStatus(models.TextChoices):
    PENDING = 'PENDING_APPROVAL', 'Pending approval'
    SPECIAL = 'SPECIAL_APPROVAL_REQUIRED', 'Special approval required'
    APPROVED = 'APPROVED', 'Approved'
    READY = 'READY_FOR_PICKUP', 'Ready for pickup'
    COMPLETED = 'COMPLETED', 'Completed'
    REJECTED = 'REJECTED', 'Rejected'
    CANCELLED = 'CANCELLED', 'Cancelled'
    ON_HOLD = 'ON_HOLD_STOCK', 'On hold stock'


class Requisition(models.Model):
    request_no = models.CharField(max_length=40, unique=True)
    req_type = models.CharField(max_length=20, choices=RequisitionType.choices, default=RequisitionType.ISSUE)
    requester = models.ForeignKey(User, on_delete=models.PROTECT, related_name='requisitions')
    status = models.CharField(max_length=40, choices=RequisitionStatus.choices, default=RequisitionStatus.PENDING)
    special_approval_needed = models.BooleanField(default=False)
    special_reason = models.TextField(blank=True)
    client_request_id = models.CharField(max_length=80)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['requester', 'client_request_id'], name='unique_client_request')]
        indexes = [models.Index(fields=['requester', 'status'])]


class RequisitionReason(models.TextChoices):
    DAMAGED = 'DAMAGED', 'Damaged'
    LIFESPAN_EXPIRED = 'LIFESPAN_EXPIRED', 'Lifespan expired'
    NEW_EMPLOYEE = 'NEW_EMPLOYEE', 'New employee'
    LOST = 'LOST', 'Lost'
    RETURN_SCHEDULED = 'RETURN_SCHEDULED', 'Return scheduled'
    OTHER = 'OTHER', 'Other'


class RequisitionItem(models.Model):
    requisition = models.ForeignKey(Requisition, on_delete=models.CASCADE, related_name='items')
    ppe_item = models.ForeignKey(PpeItem, on_delete=models.PROTECT, related_name='requisition_items')
    size = models.CharField(max_length=20, blank=True)
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    reason = models.CharField(max_length=30, choices=RequisitionReason.choices)
    eligible_at = models.DateTimeField(null=True, blank=True)
    return_due_date = models.DateTimeField(null=True, blank=True)
    returned_at = models.DateTimeField(null=True, blank=True)
    is_returned = models.BooleanField(default=False)


class PurchaseRequestStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending Store Review'
    APPROVED = 'APPROVED', 'Approved for Ordering'
    ORDERED = 'ORDERED', 'Ordered'
    RECEIVED = 'RECEIVED', 'Received into Stock'
    REJECTED = 'REJECTED', 'Rejected'


class PpePurchaseRequest(models.Model):
    request_no = models.CharField(max_length=40, unique=True)
    requester = models.ForeignKey(User, on_delete=models.PROTECT, related_name='purchase_requests')
    ppe_item = models.ForeignKey(PpeItem, on_delete=models.PROTECT, related_name='purchase_requests')
    requested_quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    reason = models.TextField()
    status = models.CharField(max_length=30, choices=PurchaseRequestStatus.choices, default=PurchaseRequestStatus.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class ApprovalKind(models.TextChoices):
    NORMAL = 'NORMAL', 'Normal'
    SPECIAL_SUPERVISOR = 'SPECIAL_SUPERVISOR', 'Special supervisor'
    SPECIAL_EHS = 'SPECIAL_EHS', 'Special EHS'
    STORE_RELEASE = 'STORE_RELEASE', 'Store release'


class ApprovalDecision(models.TextChoices):
    APPROVED = 'APPROVED', 'Approved'
    REJECTED = 'REJECTED', 'Rejected'


class Approval(models.Model):
    requisition = models.ForeignKey(Requisition, on_delete=models.CASCADE, related_name='approvals')
    approver = models.ForeignKey(User, on_delete=models.PROTECT, related_name='approvals')
    kind = models.CharField(max_length=30, choices=ApprovalKind.choices)
    decision = models.CharField(max_length=15, choices=ApprovalDecision.choices)
    reason = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['requisition', 'kind'], name='unique_approval_kind')]


class StockEventType(models.TextChoices):
    RECEIPT = 'RECEIPT', 'Receipt'
    RESERVE = 'RESERVE', 'Reserve'
    ISSUE = 'ISSUE', 'Issue'
    RETURN = 'RETURN', 'Return'
    ADJUSTMENT = 'ADJUSTMENT', 'Adjustment'
    DAMAGE = 'DAMAGE', 'Damage'


class StockEvent(models.Model):
    requisition = models.ForeignKey(Requisition, null=True, blank=True, on_delete=models.PROTECT, related_name='stock_events')
    stock_lot = models.ForeignKey(StockLot, on_delete=models.PROTECT, related_name='events')
    event_type = models.CharField(max_length=20, choices=StockEventType.choices)
    quantity = models.IntegerField()
    issuer = models.ForeignKey(User, null=True, blank=True, on_delete=models.PROTECT, related_name='issued_stock_events')
    receiver = models.ForeignKey(User, null=True, blank=True, on_delete=models.PROTECT, related_name='received_stock_events')
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(default=timezone.now)


class AuditLog(models.Model):
    actor = models.ForeignKey(User, null=True, blank=True, on_delete=models.PROTECT)
    action = models.CharField(max_length=80)
    entity = models.CharField(max_length=80)
    entity_id = models.CharField(max_length=80)
    before = models.JSONField(null=True, blank=True)
    after = models.JSONField(null=True, blank=True)
    request_id = models.CharField(max_length=80, blank=True)
    created_at = models.DateTimeField(default=timezone.now)


class DeviceToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='device_tokens')
    token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(max_length=10, choices=DevicePlatform.choices)
    active = models.BooleanField(default=True)
    last_seen_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)


class Notification(models.Model):
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=30, choices=NotificationType.choices)
    title = models.CharField(max_length=180)
    message = models.TextField()
    payload = models.JSONField(default=dict, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)


class QRChallenge(models.Model):
    token_hash = models.CharField(max_length=64, unique=True)
    purpose = models.CharField(max_length=30, default='ISSUE')
    user = models.ForeignKey(User, null=True, blank=True, on_delete=models.CASCADE)
    requisition = models.ForeignKey(Requisition, null=True, blank=True, on_delete=models.CASCADE)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def is_usable(self) -> bool:
        return self.used_at is None and self.expires_at > timezone.now()