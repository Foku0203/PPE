from datetime import timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework import serializers

from .exceptions import BusinessRuleError

from .models import (
    Approval,
    AuditLog,
    DeviceToken,
    Locale,
    Notification,
    PpeCategory,
    PpeItem,
    PpePurchaseRequest,
    PpeTranslation,
    Requisition,
    RequisitionComment,
    RequisitionItem,
    RequisitionReason,
    RequisitionStatus,
    Role,
    StockEvent,
    StockLot,
    User,
)
from .services import STORE_ROLES, approval_kind_for, approval_sla_hours


def request_locale(context) -> str:
    request = context.get('request') if context else None
    if request is None:
        return Locale.EN
    locale = (request.query_params.get('locale') or '').upper()
    if locale in Locale.values:
        return locale
    user = getattr(request, 'user', None)
    return getattr(user, 'locale', Locale.EN) or Locale.EN


def translated(ppe_item: PpeItem, locale: str) -> PpeTranslation | None:
    translations = {t.locale: t for t in ppe_item.translations.all()}
    return translations.get(locale) or translations.get(Locale.EN) or next(iter(translations.values()), None)


# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------

class UserSerializer(serializers.ModelSerializer):
    supervisor_name = serializers.CharField(source='supervisor.display_name', read_only=True, default=None)
    permissions = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'employee_id', 'username', 'display_name', 'phone_number', 'department', 'locale', 'role', 'supervisor', 'supervisor_name', 'is_active', 'permissions']
        read_only_fields = ['id', 'employee_id', 'username', 'role', 'supervisor', 'is_active', 'permissions']

    def get_permissions(self, user):
        from .models import ROLE_PERMISSIONS
        return sorted(str(p) for p in ROLE_PERMISSIONS.get(user.role, set()))


class UserAdminSerializer(UserSerializer):
    team_size = serializers.SerializerMethodField()

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + ['team_size']
        read_only_fields = ['id', 'employee_id', 'username', 'permissions', 'team_size']

    def get_team_size(self, user):
        return user.team_members.filter(is_active=True).count()

    def validate(self, attrs):
        # A supervisor who leaves the role or is deactivated would strand the team's requests; move the team first.
        user = self.instance
        leaving = attrs.get('is_active') is False or attrs.get('role', getattr(user, 'role', None)) != Role.SUPERVISOR
        if user and user.role == Role.SUPERVISOR and leaving and user.team_members.filter(is_active=True).exists():
            raise BusinessRuleError('TEAM_NOT_EMPTY', 'Move this supervisor\'s team to another supervisor first.', 400)
        return attrs

    def validate_supervisor(self, supervisor):
        if supervisor and supervisor.role not in [Role.SUPERVISOR, Role.EHS, Role.ADMIN]:
            raise serializers.ValidationError('Supervisor must have Supervisor, EHS or Admin role.')
        if supervisor and self.instance and supervisor.pk == self.instance.pk:
            raise serializers.ValidationError('A user cannot supervise themselves.')
        return supervisor


class RegisterSerializer(serializers.Serializer):
    employee_id = serializers.CharField(max_length=32)
    display_name = serializers.CharField(max_length=160)
    password = serializers.CharField(min_length=8, write_only=True)
    department = serializers.CharField(max_length=120, required=False, allow_blank=True)
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    locale = serializers.ChoiceField(choices=Locale.values, required=False, default=Locale.TH)
    supervisor_employee_id = serializers.CharField(max_length=32, required=False, allow_blank=True)

    def validate_employee_id(self, value):
        value = value.strip().upper()
        if User.objects.filter(employee_id=value).exists() or User.objects.filter(username=value.lower()).exists():
            raise serializers.ValidationError('This Employee ID is already registered.')
        return value

    def validate_supervisor_employee_id(self, value):
        value = (value or '').strip().upper()
        if not value:
            return None
        # Only the Supervisor role: approval_inbox routes a worker's requests by requester__supervisor for supervisors alone.
        supervisor = User.objects.filter(employee_id=value, is_active=True, role=Role.SUPERVISOR).first()
        if supervisor is None:
            raise serializers.ValidationError('Supervisor Employee ID not found.')
        return supervisor

    def validate(self, attrs):
        # Without a supervisor the worker's requests never reach a supervisor's inbox, so require one whenever any exists.
        if not attrs.get('supervisor_employee_id') and User.objects.filter(is_active=True, role=Role.SUPERVISOR).exists():
            raise serializers.ValidationError({'supervisor_employee_id': 'Please select your supervisor.'})
        return attrs

    def create(self, validated_data):
        supervisor = validated_data.pop('supervisor_employee_id', None)
        password = validated_data.pop('password')
        user = User(username=validated_data['employee_id'].lower(), role=Role.WORKER, supervisor=supervisor, **validated_data)
        user.set_password(password)
        user.save()
        return user


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField()
    new_password = serializers.CharField(min_length=8)


# ---------------------------------------------------------------------------
# Catalog
# ---------------------------------------------------------------------------

class TranslationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PpeTranslation
        fields = ['locale', 'name', 'short_name', 'description']


class PpeItemSerializer(serializers.ModelSerializer):
    translations = TranslationSerializer(many=True, read_only=True)
    stock = serializers.IntegerField(read_only=True, default=0)
    reserved = serializers.IntegerField(read_only=True, default=0)
    name = serializers.SerializerMethodField()
    description = serializers.SerializerMethodField()
    size_options = serializers.SerializerMethodField()

    class Meta:
        model = PpeItem
        fields = ['id', 'code', 'category', 'icon_key', 'image_url', 'unit', 'sizes', 'size_options', 'requires_serial', 'is_returnable', 'quota',
                  'lifespan_days', 'reorder_point', 'active', 'name', 'description', 'translations', 'stock', 'reserved']

    def get_name(self, obj):
        t = translated(obj, request_locale(self.context))
        return t.name if t else obj.code

    def get_description(self, obj):
        t = translated(obj, request_locale(self.context))
        return t.description if t else ''

    def get_size_options(self, obj):
        return [s.strip() for s in obj.sizes.split(',') if s.strip()]


class PpeItemWriteSerializer(serializers.ModelSerializer):
    translations = TranslationSerializer(many=True, required=False)
    change_reason = serializers.CharField(write_only=True, required=False, allow_blank=True)
    category = serializers.ChoiceField(choices=PpeCategory.values, required=False)

    class Meta:
        model = PpeItem
        fields = ['id', 'code', 'category', 'icon_key', 'image_url', 'unit', 'sizes', 'requires_serial', 'is_returnable', 'quota', 'lifespan_days',
                  'reorder_point', 'active', 'translations', 'change_reason']

    def validate(self, attrs):
        policy_fields = {'quota', 'lifespan_days', 'reorder_point', 'active'}
        if self.instance and policy_fields & set(attrs) and not attrs.get('change_reason', '').strip():
            raise serializers.ValidationError({'change_reason': 'A reason is required when changing quota, lifespan, reorder point or status.'})
        return attrs

    @transaction.atomic
    def save_with_translations(self):
        translations = self.validated_data.pop('translations', None)
        self.validated_data.pop('change_reason', None)
        item = self.save()
        for t in translations or []:
            PpeTranslation.objects.update_or_create(ppe_item=item, locale=t['locale'], defaults={k: v for k, v in t.items() if k != 'locale'})
        return item


class EligibilitySerializer(serializers.Serializer):
    allowed = serializers.BooleanField()
    special_approval_required = serializers.BooleanField()
    reason = serializers.CharField(allow_null=True)
    eligible_at = serializers.DateTimeField(allow_null=True)
    last_issued_at = serializers.DateTimeField(allow_null=True, required=False)
    stock = serializers.IntegerField()
    quota = serializers.IntegerField(allow_null=True)


# ---------------------------------------------------------------------------
# Requisitions
# ---------------------------------------------------------------------------

class RequisitionItemInputSerializer(serializers.Serializer):
    ppe_item_id = serializers.IntegerField()
    size = serializers.CharField(required=False, allow_blank=True, default='')
    quantity = serializers.IntegerField(min_value=1, max_value=999)
    reason = serializers.ChoiceField(choices=RequisitionReason.values)


class RequisitionItemSerializer(serializers.ModelSerializer):
    ppe_item_code = serializers.CharField(source='ppe_item.code', read_only=True)
    ppe_item_name = serializers.SerializerMethodField()
    ppe_icon_key = serializers.CharField(source='ppe_item.icon_key', read_only=True)
    ppe_image_url = serializers.CharField(source='ppe_item.image_url', read_only=True)
    unit = serializers.CharField(source='ppe_item.unit', read_only=True)
    is_returnable = serializers.BooleanField(source='ppe_item.is_returnable', read_only=True)
    requires_serial = serializers.BooleanField(source='ppe_item.requires_serial', read_only=True)

    class Meta:
        model = RequisitionItem
        fields = ['id', 'ppe_item', 'ppe_item_code', 'ppe_item_name', 'ppe_icon_key', 'ppe_image_url', 'unit', 'size', 'quantity', 'reason', 'eligible_at',
                  'return_due_date', 'returned_at', 'is_returned', 'is_returnable', 'requires_serial']

    def get_ppe_item_name(self, obj):
        t = translated(obj.ppe_item, request_locale(self.context))
        return t.name if t else obj.ppe_item.code


class ApprovalSerializer(serializers.ModelSerializer):
    approver_name = serializers.CharField(source='approver.display_name', read_only=True)
    approver_role = serializers.CharField(source='approver.role', read_only=True)

    class Meta:
        model = Approval
        fields = ['id', 'kind', 'decision', 'reason', 'approver_name', 'approver_role', 'created_at']


class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.display_name', read_only=True)
    author_role = serializers.CharField(source='author.role', read_only=True)

    class Meta:
        model = RequisitionComment
        fields = ['id', 'author', 'author_name', 'author_role', 'message', 'is_info_request', 'created_at']


class StockEventSerializer(serializers.ModelSerializer):
    ppe_code = serializers.CharField(source='stock_lot.ppe_item.code', read_only=True)
    lot_number = serializers.CharField(source='stock_lot.lot_number', read_only=True)
    serial_number = serializers.CharField(source='stock_lot.serial_number', read_only=True, allow_null=True)
    issuer_name = serializers.CharField(source='issuer.display_name', read_only=True, default=None)
    receiver_name = serializers.CharField(source='receiver.display_name', read_only=True, default=None)
    request_no = serializers.CharField(source='requisition.request_no', read_only=True, default=None)

    class Meta:
        model = StockEvent
        fields = ['id', 'event_type', 'quantity', 'ppe_code', 'lot_number', 'serial_number', 'issuer_name', 'receiver_name', 'request_no', 'metadata', 'created_at']


class RequisitionSerializer(serializers.ModelSerializer):
    items = RequisitionItemSerializer(many=True, read_only=True)
    approvals = ApprovalSerializer(many=True, read_only=True)
    requester_name = serializers.CharField(source='requester.display_name', read_only=True)
    requester_employee_id = serializers.CharField(source='requester.employee_id', read_only=True)
    requester_department = serializers.CharField(source='requester.department', read_only=True)
    age_hours = serializers.SerializerMethodField()
    is_overdue = serializers.SerializerMethodField()
    actions = serializers.SerializerMethodField()

    class Meta:
        model = Requisition
        fields = ['id', 'request_no', 'req_type', 'requester', 'requester_name', 'requester_employee_id', 'requester_department', 'status',
                  'special_approval_needed', 'special_reason', 'client_request_id', 'items', 'approvals', 'age_hours', 'is_overdue', 'actions',
                  'created_at', 'updated_at']

    def get_age_hours(self, obj):
        return round((timezone.now() - obj.created_at).total_seconds() / 3600, 1)

    def get_is_overdue(self, obj):
        return obj.status in [RequisitionStatus.PENDING, RequisitionStatus.SPECIAL] and timezone.now() - obj.created_at > timedelta(hours=approval_sla_hours())

    def get_actions(self, obj):
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if user is None or not user.is_authenticated:
            return {}
        is_store = user.role in STORE_ROLES
        can_approve = approval_kind_for(obj, user) is not None
        return {
            'can_approve': can_approve,
            'can_request_info': can_approve,
            'can_cancel': obj.status not in [RequisitionStatus.COMPLETED, RequisitionStatus.REJECTED, RequisitionStatus.CANCELLED] and (obj.requester_id == user.id or is_store),
            'can_prepare': is_store and obj.status in [RequisitionStatus.APPROVED, RequisitionStatus.ON_HOLD],
            'can_issue': is_store and obj.status == RequisitionStatus.READY,
            'can_show_pickup_qr': obj.requester_id == user.id and obj.status == RequisitionStatus.READY,
            'can_return': is_store and obj.status == RequisitionStatus.COMPLETED,
            'can_comment': obj.requester_id == user.id or can_approve or is_store or user.role in [Role.SUPERVISOR, Role.EHS, Role.ADMIN],
        }


class RequisitionDetailSerializer(RequisitionSerializer):
    comments = CommentSerializer(many=True, read_only=True)
    stock_events = StockEventSerializer(many=True, read_only=True)

    class Meta(RequisitionSerializer.Meta):
        fields = RequisitionSerializer.Meta.fields + ['comments', 'stock_events']


class CreateRequisitionSerializer(serializers.Serializer):
    client_request_id = serializers.CharField(max_length=80)
    items = RequisitionItemInputSerializer(many=True, min_length=1, max_length=20)
    special_reason = serializers.CharField(required=False, allow_blank=True, default='')


class ApprovalInputSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=['APPROVED', 'REJECTED', 'REQUEST_INFO'])
    reason = serializers.CharField(required=False, allow_blank=True, default='')


class CommentInputSerializer(serializers.Serializer):
    message = serializers.CharField(max_length=2000)


class IssueInputSerializer(serializers.Serializer):
    serial_numbers = serializers.ListField(child=serializers.CharField(max_length=120), required=False, default=list)
    qr_token = serializers.CharField(required=False, allow_blank=True, default='')


class ReturnInputSerializer(serializers.Serializer):
    condition = serializers.ChoiceField(choices=['GOOD', 'DAMAGED'], default='GOOD')
    note = serializers.CharField(required=False, allow_blank=True, default='')


# ---------------------------------------------------------------------------
# Inventory
# ---------------------------------------------------------------------------

class StockLotSerializer(serializers.ModelSerializer):
    available_quantity = serializers.IntegerField(read_only=True)
    ppe_code = serializers.CharField(source='ppe_item.code', read_only=True)
    ppe_name = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()

    class Meta:
        model = StockLot
        fields = ['id', 'ppe_item', 'ppe_code', 'ppe_name', 'lot_number', 'serial_number', 'supplier', 'quantity', 'reserved_quantity', 'available_quantity',
                  'expiry_at', 'manufactured_at', 'inspected_at', 'serial_status', 'is_expired']

    def get_ppe_name(self, obj):
        t = translated(obj.ppe_item, request_locale(self.context))
        return t.name if t else obj.ppe_item.code

    def get_is_expired(self, obj):
        return bool(obj.expiry_at and obj.expiry_at <= timezone.now())


class ReceiveStockSerializer(serializers.Serializer):
    ppe_item_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, max_value=100000)
    lot_number = serializers.CharField(max_length=80, required=False, allow_blank=True, default='')
    supplier = serializers.CharField(max_length=160, required=False, allow_blank=True, default='')
    serial_numbers = serializers.ListField(child=serializers.CharField(max_length=120), required=False, default=list)
    expiry_at = serializers.DateTimeField(required=False, allow_null=True, default=None)
    manufactured_at = serializers.DateTimeField(required=False, allow_null=True, default=None)
    inspected_at = serializers.DateTimeField(required=False, allow_null=True, default=None)
    purchase_request_id = serializers.IntegerField(required=False, allow_null=True, default=None)


class AdjustStockSerializer(serializers.Serializer):
    delta = serializers.IntegerField()
    reason = serializers.CharField(max_length=500)
    event_type = serializers.ChoiceField(choices=['ADJUSTMENT', 'DAMAGE'], default='ADJUSTMENT')


class PurchaseRequestSerializer(serializers.ModelSerializer):
    ppe_item_code = serializers.CharField(source='ppe_item.code', read_only=True)
    ppe_item_name = serializers.SerializerMethodField()
    requester_name = serializers.CharField(source='requester.display_name', read_only=True)

    class Meta:
        model = PpePurchaseRequest
        fields = ['id', 'request_no', 'ppe_item', 'ppe_item_code', 'ppe_item_name', 'requester_name', 'requested_quantity', 'reason', 'status', 'created_at', 'updated_at']
        read_only_fields = ['id', 'request_no', 'status', 'created_at', 'updated_at']

    def get_ppe_item_name(self, obj):
        t = translated(obj.ppe_item, request_locale(self.context))
        return t.name if t else obj.ppe_item.code


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ['id', 'token', 'platform', 'active', 'last_seen_at', 'created_at']
        read_only_fields = ['id', 'active', 'last_seen_at', 'created_at']
        extra_kwargs = {'token': {'validators': []}}


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'notification_type', 'title', 'message', 'payload', 'read_at', 'delivered_at', 'created_at']


class AuditLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.CharField(source='actor.display_name', read_only=True, default=None)
    actor_employee_id = serializers.CharField(source='actor.employee_id', read_only=True, default=None)

    class Meta:
        model = AuditLog
        fields = ['id', 'actor_name', 'actor_employee_id', 'action', 'entity', 'entity_id', 'before', 'after', 'request_id', 'created_at']
