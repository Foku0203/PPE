from rest_framework.permissions import SAFE_METHODS, BasePermission

from .models import PermissionCode, Role


class IsSupervisorOrHigher(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [Role.SUPERVISOR, Role.EHS, Role.ADMIN]


class IsStoreOrHigher(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [Role.STORE_KEEPER, Role.EHS, Role.ADMIN]


class IsEhsOrAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [Role.EHS, Role.ADMIN]


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == Role.ADMIN


class CanManageMasterDataOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.method in SAFE_METHODS or request.user.has_permission_code(PermissionCode.MANAGE_MASTER_DATA)
