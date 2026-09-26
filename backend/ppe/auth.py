from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User


class EmployeeIdTokenSerializer(serializers.Serializer):
    employee_id = serializers.CharField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate(self, attrs):
        employee_id = attrs['employee_id'].strip()
        password = attrs['password']
        user = User.objects.filter(employee_id=employee_id, is_active=True).first()
        authenticated = authenticate(username=user.username, password=password) if user else None
        if authenticated is None:
            raise AuthenticationFailed('Invalid Employee ID or password.')
        refresh = RefreshToken.for_user(authenticated)
        return {'refresh': str(refresh), 'access': str(refresh.access_token), 'user': {'id': authenticated.id, 'employee_id': authenticated.employee_id, 'display_name': authenticated.display_name, 'role': authenticated.role, 'locale': authenticated.locale}}
