import 'package:dio/dio.dart';

import '../errors/app_exceptions.dart';

/// Thin wrapper over Dio that converts every failure into an [AppException]
/// and unwraps DRF pagination (`{"count", "next", "results"}`).
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query, String? idempotencyKey}) => _send(() => _dio.post(
        path,
        data: data,
        queryParameters: _clean(query),
        options: idempotencyKey == null ? null : Options(headers: {'Idempotency-Key': idempotencyKey}),
      ));

  Future<dynamic> patch(String path, {Object? data}) => _send(() => _dio.patch(path, data: data));

  /// GET a list endpoint, accepting both plain lists and paginated responses.
  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, dynamic>? query}) async =>
      unwrapList(await get(path, query: query));

  static List<Map<String, dynamic>> unwrapList(dynamic data) {
    final list = data is Map<String, dynamic> ? (data['results'] as List? ?? const []) : (data as List? ?? const []);
    return list.cast<Map<String, dynamic>>();
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return {
      for (final entry in query.entries)
        if (entry.value != null && entry.value.toString().isNotEmpty) entry.key: entry.value,
    };
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  static AppException mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RequestTimeoutException();
      case DioExceptionType.connectionError:
        return const NoInternetException();
      case DioExceptionType.badResponse:
        return _fromResponse(e.response!);
      case DioExceptionType.cancel:
        return const UnknownException('Request cancelled');
      default:
        if (e.response != null) return _fromResponse(e.response!);
        return e.error is Exception && e.error.toString().contains('SocketException')
            ? const NoInternetException()
            : UnknownException(e.message ?? 'Unexpected error');
    }
  }

  static AppException _fromResponse(Response response) {
    final status = response.statusCode;
    final body = response.data;
    var code = 'HTTP_$status';
    var message = response.statusMessage ?? 'Request failed';
    Map<String, dynamic> details = const {};
    if (body is Map && body['error'] is Map) {
      final error = body['error'] as Map;
      code = (error['code'] ?? code).toString();
      message = (error['message'] ?? message).toString();
      if (error['details'] is Map) details = Map<String, dynamic>.from(error['details'] as Map);
    } else if (body is Map && body['detail'] != null) {
      message = body['detail'].toString();
    }
    if (status == 401 && code != 'INVALID_CREDENTIALS') return UnauthorizedException(message, code: code);
    if (code == 'VALIDATION_ERROR') {
      return ValidationException(message, fieldErrors: {
        for (final entry in details.entries)
          entry.key: entry.value is List && (entry.value as List).isNotEmpty ? (entry.value as List).first.toString() : entry.value.toString(),
      });
    }
    return ApiException(message, code: code, statusCode: status, details: details);
  }
}
