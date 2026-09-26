from django.contrib import admin
from django.urls import include, path
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenRefreshView
from ppe.auth import EmployeeIdTokenSerializer


class EmployeeIdTokenView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        serializer = EmployeeIdTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/token/', EmployeeIdTokenView.as_view(), name='token_obtain'),
    path('api/v1/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/v1/', include('ppe.urls')),
]
