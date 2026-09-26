import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/local_store.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/presentation/screens/auth_provider.dart';

/// Overridden in `main()` with the opened Hive store (and in tests with memory stores).
final localStoreProvider = Provider<LocalStore>((ref) => MemoryLocalStore());
final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureStorageService());

/// Supported app languages (TH / EN / MY / ZH). Codes match the backend `Locale` choices.
enum AppLanguage {
  th('TH', Locale('th'), 'ไทย'),
  en('EN', Locale('en'), 'English'),
  my('MY', Locale('my'), 'မြန်မာ'),
  zh('ZH', Locale('zh'), '中文');

  const AppLanguage(this.apiCode, this.locale, this.nativeName);
  final String apiCode;
  final Locale locale;
  final String nativeName;

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere((l) => l.apiCode == code?.toUpperCase(), orElse: () => AppLanguage.th);
}

class AppSettings {
  const AppSettings({required this.language, required this.biometricEnabled, required this.serverUrl, this.themeMode = ThemeMode.system});

  final AppLanguage language;
  final bool biometricEnabled;
  final String serverUrl;
  final ThemeMode themeMode;

  AppSettings copyWith({AppLanguage? language, bool? biometricEnabled, String? serverUrl, ThemeMode? themeMode}) => AppSettings(
        language: language ?? this.language,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        serverUrl: serverUrl ?? this.serverUrl,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsController extends Notifier<AppSettings> {
  LocalStore get _store => ref.read(localStoreProvider);

  @override
  AppSettings build() {
    final store = ref.watch(localStoreProvider);
    return AppSettings(
      language: AppLanguage.fromCode(store.get<String>(StoreKeys.locale)),
      biometricEnabled: store.get<bool>(StoreKeys.biometric) ?? false,
      serverUrl: store.get<String>(StoreKeys.serverUrl) ?? AppConfig.defaultApiBaseUrl,
      themeMode: ThemeMode.values.asNameMap()[store.get<String>(StoreKeys.themeMode)] ?? ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _store.put(StoreKeys.themeMode, mode.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _store.put(StoreKeys.locale, language.apiCode);
  }

  Future<void> setBiometric(bool enabled) async {
    state = state.copyWith(biometricEnabled: enabled);
    await _store.put(StoreKeys.biometric, enabled);
  }

  Future<void> setServerUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    state = state.copyWith(serverUrl: cleaned.isEmpty ? AppConfig.defaultApiBaseUrl : cleaned);
    await _store.put(StoreKeys.serverUrl, cleaned.isEmpty ? null : cleaned);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Current backend locale code (TH/EN/MY) used for API calls and localized PPE names.
final localeCodeProvider = Provider<String>((ref) => ref.watch(settingsProvider.select((s) => s.language.apiCode)));

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = DioClient.create(
    baseUrl: () => ref.read(settingsProvider).serverUrl,
    tokens: ref.read(tokenStorageProvider),
    locale: () => ref.read(settingsProvider).language.apiCode,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).onSessionExpired(),
  );
  return ApiClient(dio);
});
