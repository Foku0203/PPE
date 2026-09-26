from rest_framework.permissions import BasePermission
from .models import Role


class IsSupervisorOrHigher(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [Role.SUPERVISOR, Role.EHS, Role.ADMIN]


class IsStoreOrHigher(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [Role.STORE_KEEPER, Role.EHS, Role.ADMIN]
