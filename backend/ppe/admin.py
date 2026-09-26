from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import (
    Approval,
    AuditLog,
    PpeItem,
    PpePurchaseRequest,
    PpeTranslation,
    QRChallenge,
    Requisition,
    RequisitionItem,
    StockEvent,
    StockLot,
    User,
)

admin.site.register(User, UserAdmin)
admin.site.register([PpeItem, PpeTranslation, StockLot, Requisition, RequisitionItem, Approval, StockEvent, AuditLog, QRChallenge, PpePurchaseRequest])