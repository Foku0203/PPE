/// Standard error types (README §7.4). Repositories throw these; the UI maps
/// them to localized messages with `errorMessage()` in shared/widgets/labels.dart.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code = 'ERROR'});

  final String message;
  final String code;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// Backend returned `{"success": false, "error": {...}}`.
class ApiException extends AppException {
  const ApiException(super.message, {super.code, this.statusCode, this.details = const {}});

  final int? statusCode;
  final Map<String, dynamic> details;
}

/// 400 VALIDATION_ERROR with per-field messages.
class ValidationException extends ApiException {
  const ValidationException(super.message, {this.fieldErrors = const {}, super.statusCode = 400})
      : super(code: 'VALIDATION_ERROR');

  final Map<String, String> fieldErrors;
}

/// Session expired or credentials rejected.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.code = 'UNAUTHORIZED'}) : super(statusCode: 401);
}

class NoInternetException extends AppException {
  const NoInternetException([super.message = 'No connection to server']) : super(code: 'NO_INTERNET');
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'Request timed out']) : super(code: 'TIMEOUT');
}

class UnknownException extends AppException {
  const UnknownException(super.message) : super(code: 'UNKNOWN');
}

extension AppExceptionX on Object {
  /// True when the failure is transient and the action can be retried later (offline queue).
  bool get isNetworkFailure => this is NoInternetException || this is RequestTimeoutException;
}
