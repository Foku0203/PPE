from django.contrib.auth import authenticate
from rest_framework import serializers

from .exceptions import BusinessRuleError
from .models import User


class EmployeeIdTokenSerializer(serializers.Serializer):
    employee_id = serializers.CharField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate(self, attrs):
        employee_id = attrs['employee_id'].strip().upper()
        user = User.objects.filter(employee_id__iexact=employee_id, is_active=True).first()
        authenticated = authenticate(username=user.username, password=attrs['password']) if user else None
        if authenticated is None:
            raise BusinessRuleError('INVALID_CREDENTIALS', 'Invalid Employee ID or password.', 401)
        return {'user_obj': authenticated}
