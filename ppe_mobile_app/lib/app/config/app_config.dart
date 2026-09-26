import 'package:flutter/foundation.dart';

/// Central configuration. Override the API at build time with
/// `--dart-define=API_BASE_URL=https://ppe.example.com/api/v1`, or at runtime
/// from the login screen (server settings), which is persisted per device.
class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String environment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static String get defaultApiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    // Android emulator reaches the host machine through 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration notificationPollInterval = Duration(seconds: 30);
  static const Duration offlineSyncInterval = Duration(seconds: 45);
  static const Duration relockAfter = Duration(minutes: 1);
  static const int pageSize = 100;
  static bool get enableLogging => kDebugMode;
}
