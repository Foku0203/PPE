import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../app/config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

/// Builds the Dio instance used by [ApiClient].
///
/// * attaches `Authorization: Bearer <access>` and `Accept-Language`
/// * adds an `Idempotency-Key` to every mutation (README §7.1)
/// * refreshes the access token once on 401 (refresh token rotates on use)
///   and replays the original request; concurrent 401s share one refresh.
class DioClient {
  static Dio create({
    required String Function() baseUrl,
    required TokenStorage tokens,
    required String Function() locale,
    required void Function() onSessionExpired,
  }) {
    final dio = Dio(BaseOptions(
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
    dio.interceptors.add(_AuthInterceptor(dio: dio, baseUrl: baseUrl, tokens: tokens, locale: locale, onSessionExpired: onSessionExpired));
    if (AppConfig.enableLogging) {
      // Headers are never logged: they carry the bearer token.
      dio.interceptors.add(LogInterceptor(request: false, requestHeader: false, responseHeader: false, logPrint: (o) => debugPrint(o.toString())));
    }
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required this.dio, required this.baseUrl, required this.tokens, required this.locale, required this.onSessionExpired});

  final Dio dio;
  final String Function() baseUrl;
  final TokenStorage tokens;
  final String Function() locale;
  final void Function() onSessionExpired;
  static const _uuid = Uuid();
  Completer<String?>? _refreshing;

  static const _publicPaths = {ApiEndpoints.login, ApiEndpoints.register, ApiEndpoints.refresh};

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.baseUrl = baseUrl();
    options.headers['Accept-Language'] = locale().toLowerCase();
    if (options.method != 'GET' && !options.headers.containsKey('Idempotency-Key')) {
      options.headers['Idempotency-Key'] = _uuid.v4();
    }
    if (!_publicPaths.contains(options.path)) {
      final access = await tokens.readAccessToken();
      if (access != null) options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isAuthError = err.response?.statusCode == 401;
    if (!isAuthError || _publicPaths.contains(request.path) || request.extra['retried'] == true) {
      return handler.next(err);
    }
    final String? newAccess;
    try {
      newAccess = await _refreshAccessToken();
    } on DioException catch (e) {
      // Network failure while refreshing: keep the session, surface the network error.
      return handler.next(e);
    }
    if (newAccess == null) {
      onSessionExpired();
      return handler.next(err);
    }
    try {
      request.headers['Authorization'] = 'Bearer $newAccess';
      request.extra['retried'] = true;
      handler.resolve(await dio.fetch(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Returns the new access token, null when the refresh token was rejected
  /// (session over), or throws [DioException] on network failure.
  Future<String?> _refreshAccessToken() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = _refreshing = Completer<String?>();
    // Avoid an unhandled error when nobody else awaits this future.
    completer.future.ignore();
    try {
      final refresh = await tokens.readRefreshToken();
      if (refresh == null) {
        completer.complete(null);
      } else {
        final plain = Dio(BaseOptions(baseUrl: baseUrl(), connectTimeout: AppConfig.connectTimeout));
        final response = await plain.post(ApiEndpoints.refresh, data: {'refresh': refresh});
        final access = response.data['access'] as String;
        await tokens.saveTokens(access: access, refresh: (response.data['refresh'] as String?) ?? refresh);
        completer.complete(access);
      }
    } on DioException catch (e) {
      if (e.response == null) {
        completer.completeError(e);
      } else {
        await tokens.clear();
        completer.complete(null);
      }
    } catch (_) {
      await tokens.clear();
      completer.complete(null);
    } finally {
      _refreshing = null;
    }
    return completer.future;
  }
}
