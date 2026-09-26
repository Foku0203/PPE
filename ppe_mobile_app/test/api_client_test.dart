import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_mobile_app/core/errors/app_exceptions.dart';
import 'package:ppe_mobile_app/core/network/api_client.dart';

DioException _response(int status, Object body) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('business error envelope becomes ApiException with code', () {
    final e = ApiClient.mapDioException(_response(409, {
      'success': false,
      'error': {'code': 'ACTIVE_REQUEST_EXISTS', 'message': 'Active request already exists', 'details': {'ppe_item_id': 3}},
    }));
    expect(e, isA<ApiException>());
    expect(e.code, 'ACTIVE_REQUEST_EXISTS');
    expect((e as ApiException).details['ppe_item_id'], 3);
  });

  test('validation errors expose field messages', () {
    final e = ApiClient.mapDioException(_response(400, {
      'success': false,
      'error': {
        'code': 'VALIDATION_ERROR',
        'message': 'This Employee ID is already registered.',
        'details': {'employee_id': ['This Employee ID is already registered.']},
      },
    }));
    expect(e, isA<ValidationException>());
    expect((e as ValidationException).fieldErrors['employee_id'], contains('already registered'));
  });

  test('401 becomes UnauthorizedException except for invalid credentials', () {
    expect(ApiClient.mapDioException(_response(401, {'success': false, 'error': {'code': 'TOKEN_INVALID', 'message': 'expired'}})),
        isA<UnauthorizedException>());
    final login = ApiClient.mapDioException(_response(401, {'success': false, 'error': {'code': 'INVALID_CREDENTIALS', 'message': 'bad'}}));
    expect(login, isNot(isA<UnauthorizedException>()));
    expect(login.code, 'INVALID_CREDENTIALS');
  });

  test('connection problems are classified as network failures', () {
    final options = RequestOptions(path: '/x');
    final offline = ApiClient.mapDioException(DioException(requestOptions: options, type: DioExceptionType.connectionError));
    final timeout = ApiClient.mapDioException(DioException(requestOptions: options, type: DioExceptionType.receiveTimeout));
    expect(offline, isA<NoInternetException>());
    expect(timeout, isA<RequestTimeoutException>());
    expect(offline.isNetworkFailure && timeout.isNetworkFailure, isTrue);
  });

  test('unwrapList accepts paginated and plain responses', () {
    expect(ApiClient.unwrapList({'count': 1, 'results': [{'id': 1}]}).single['id'], 1);
    expect(ApiClient.unwrapList([{'id': 2}]).single['id'], 2);
  });
}
