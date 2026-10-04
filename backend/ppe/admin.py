from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import (
    Approval,
    AuditLog,
    DeviceToken,
    Notification,
    PpeItem,
    PpePurchaseRequest,
    PpeTranslation,
    QRChallenge,
    Requisition,
    RequisitionComment,
    RequisitionItem,
    StockEvent,
    StockLot,
    User,
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('employee_id', 'display_name', 'role', 'department', 'supervisor', 'is_active')
    list_filter = ('role', 'is_active', 'department')
    search_fields = ('employee_id', 'display_name', 'username')
    fieldsets = BaseUserAdmin.fieldsets + (('PPE', {'fields': ('employee_id', 'display_name', 'phone_number', 'department', 'locale', 'role', 'supervisor')}),)
    add_fieldsets = BaseUserAdmin.add_fieldsets + (('PPE', {'fields': ('employee_id', 'display_name', 'role', 'supervisor')}),)


class TranslationInline(admin.TabularInline):
    model = PpeTranslation
    extra = 0


@admin.register(PpeItem)
class PpeItemAdmin(admin.ModelAdmin):
    list_display = ('code', 'category', 'unit', 'quota', 'lifespan_days', 'reorder_point', 'requires_serial', 'always_special_approval', 'active')
    list_filter = ('category', 'active')
    inlines = [TranslationInline]


class RequisitionItemInline(admin.TabularInline):
    model = RequisitionItem
    extra = 0


@admin.register(Requisition)
class RequisitionAdmin(admin.ModelAdmin):
    list_display = ('request_no', 'requester', 'status', 'special_approval_needed', 'created_at')
    list_filter = ('status', 'special_approval_needed')
    search_fields = ('request_no', 'requester__employee_id')
    inlines = [RequisitionItemInline]


@admin.register(StockLot)
class StockLotAdmin(admin.ModelAdmin):
    list_display = ('ppe_item', 'lot_number', 'serial_number', 'quantity', 'reserved_quantity', 'expiry_at', 'serial_status')
    list_filter = ('serial_status', 'ppe_item')


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'actor', 'action', 'entity', 'entity_id')
    list_filter = ('action', 'entity')
    readonly_fields = [f.name for f in AuditLog._meta.fields]


admin.site.register([Approval, StockEvent, QRChallenge, PpePurchaseRequest, Notification, DeviceToken, RequisitionComment])
