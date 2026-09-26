from rest_framework import serializers
from .models import Approval, DeviceToken, Notification, PpeItem, PpeTranslation, Requisition, RequisitionItem, StockLot, User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'employee_id', 'display_name', 'department', 'locale', 'role', 'supervisor']


class TranslationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PpeTranslation
        fields = ['locale', 'name', 'short_name', 'description']


class PpeItemSerializer(serializers.ModelSerializer):
    translations = TranslationSerializer(many=True, read_only=True)
    stock = serializers.IntegerField(read_only=True)

    class Meta:
        model = PpeItem
        fields = ['id', 'code', 'icon_key', 'image_url', 'unit', 'quota', 'lifespan_days', 'reorder_point', 'active', 'translations', 'stock']


class RequisitionItemInputSerializer(serializers.Serializer):
    ppe_item_id = serializers.IntegerField()
    size = serializers.CharField(required=False, allow_blank=True)
    quantity = serializers.IntegerField(min_value=1)
    reason = serializers.CharField(max_length=80)


class RequisitionItemSerializer(serializers.ModelSerializer):
    ppe_item_code = serializers.CharField(source='ppe_item.code', read_only=True)

    class Meta:
        model = RequisitionItem
        fields = ['id', 'ppe_item', 'ppe_item_code', 'size', 'quantity', 'reason', 'eligible_at']


class ApprovalSerializer(serializers.ModelSerializer):
    approver_name = serializers.CharField(source='approver.display_name', read_only=True)

    class Meta:
        model = Approval
        fields = ['id', 'kind', 'decision', 'reason', 'approver_name', 'created_at']


class RequisitionSerializer(serializers.ModelSerializer):
    items = RequisitionItemSerializer(many=True, read_only=True)
    approvals = ApprovalSerializer(many=True, read_only=True)
    requester_name = serializers.CharField(source='requester.display_name', read_only=True)

    class Meta:
        model = Requisition
        fields = ['id', 'request_no', 'requester', 'requester_name', 'status', 'special_approval_needed', 'special_reason', 'client_request_id', 'items', 'approvals', 'created_at', 'updated_at']


class CreateRequisitionSerializer(serializers.Serializer):
    client_request_id = serializers.CharField(max_length=80)
    items = RequisitionItemInputSerializer(many=True, min_length=1)


class ApprovalInputSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=['APPROVED', 'REJECTED'])
    reason = serializers.CharField(required=False, allow_blank=True)


class StockLotSerializer(serializers.ModelSerializer):
    available_quantity = serializers.IntegerField(read_only=True)
    ppe_code = serializers.CharField(source='ppe_item.code', read_only=True)

    class Meta:
        model = StockLot
        fields = ['id', 'ppe_item', 'ppe_code', 'lot_number', 'serial_number', 'quantity', 'reserved_quantity', 'available_quantity', 'expiry_at', 'manufactured_at', 'inspected_at', 'serial_status']


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ['id', 'token', 'platform', 'active', 'last_seen_at', 'created_at']
        read_only_fields = ['id', 'active', 'last_seen_at', 'created_at']


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'notification_type', 'title', 'message', 'payload', 'read_at', 'delivered_at', 'created_at']
