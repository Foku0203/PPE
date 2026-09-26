from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.views import exception_handler


class BusinessRuleError(APIException):
    """Business rule violation with a stable machine-readable code for the mobile app."""

    status_code = status.HTTP_409_CONFLICT
    default_code = 'BUSINESS_RULE'
    default_detail = 'The request violates a business rule.'

    def __init__(self, code: str, message: str, http_status: int | None = None, details: dict | None = None):
        super().__init__(detail=message, code=code)
        self.error_code = code
        self.details = details or {}
        if http_status:
            self.status_code = http_status


_CODE_BY_STATUS = {
    400: 'VALIDATION_ERROR',
    401: 'UNAUTHORIZED',
    403: 'FORBIDDEN',
    404: 'NOT_FOUND',
    405: 'METHOD_NOT_ALLOWED',
    409: 'CONFLICT',
    429: 'THROTTLED',
}


def _first_message(detail) -> str:
    if isinstance(detail, dict):
        for value in detail.values():
            return _first_message(value)
    if isinstance(detail, list) and detail:
        return _first_message(detail[0])
    return str(detail)


def api_exception_handler(exc, context):
    """Wraps every error as {"success": false, "error": {"code", "message", "details"}} (README §9)."""
    response = exception_handler(exc, context)
    if response is None:
        return None
    if isinstance(exc, BusinessRuleError):
        code, message, details = exc.error_code, str(exc.detail), exc.details
    else:
        code = _CODE_BY_STATUS.get(response.status_code, 'ERROR')
        if response.status_code == 401 and getattr(exc, 'default_code', '') == 'token_not_valid':
            code = 'TOKEN_INVALID'
        message = _first_message(response.data)
        details = response.data if isinstance(exc, ValidationError) else {}
    response.data = {'success': False, 'error': {'code': code, 'message': message, 'details': details}}
    return response
