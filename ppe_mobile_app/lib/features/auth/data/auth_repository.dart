import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/core_providers.dart';

class RegisterInput {
  const RegisterInput({
    required this.employeeId,
    required this.displayName,
    required this.password,
    this.department = '',
    this.phoneNumber = '',
    this.supervisorEmployeeId = '',
    this.locale = 'TH',
  });

  final String employeeId;
  final String displayName;
  final String password;
  final String department;
  final String phoneNumber;
  final String supervisorEmployeeId;
  final String locale;

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId.trim(),
        'display_name': displayName.trim(),
        'password': password,
        'department': department.trim(),
        'phone_number': phoneNumber.trim(),
        'supervisor_employee_id': supervisorEmployeeId.trim(),
        'locale': locale,
      };
}

class AuthRepository {
  AuthRepository(this._api, this._tokens, this._store);

  final ApiClient _api;
  final TokenStorage _tokens;
  final LocalStore _store;

  Future<AppUser> login(String employeeId, String password) async =>
      _saveSession(await _api.post(ApiEndpoints.login, data: {'employee_id': employeeId.trim(), 'password': password}));

  Future<AppUser> register(RegisterInput input) async => _saveSession(await _api.post(ApiEndpoints.register, data: input.toJson()));

  Future<AppUser> _saveSession(dynamic data) async {
    await _tokens.saveTokens(access: data['access'] as String, refresh: data['refresh'] as String);
    final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    await cacheUser(user);
    return user;
  }

  Future<bool> hasSession() async => await _tokens.readRefreshToken() != null;

  AppUser? cachedUser() {
    final json = _store.getJson(StoreKeys.cachedUser);
    return json is Map ? AppUser.fromJson(Map<String, dynamic>.from(json)) : null;
  }

  Future<void> cacheUser(AppUser user) => _store.putJson(StoreKeys.cachedUser, user.toJson());

  Future<AppUser> me() async {
    final user = AppUser.fromJson(Map<String, dynamic>.from(await _api.get(ApiEndpoints.me) as Map));
    await cacheUser(user);
    return user;
  }

  Future<AppUser> updateMe(Map<String, dynamic> changes) async {
    final user = AppUser.fromJson(Map<String, dynamic>.from(await _api.patch(ApiEndpoints.me, data: changes) as Map));
    await cacheUser(user);
    return user;
  }

  Future<void> changePassword(String current, String next) =>
      _api.post(ApiEndpoints.changePassword, data: {'current_password': current, 'new_password': next});

  Future<void> registerDevice(String token, String platform) => _api.post(ApiEndpoints.deviceToken, data: {'token': token, 'platform': platform});

  /// Revokes the refresh token server-side (best effort) and wipes local session data.
  Future<void> logout({String? deviceToken}) async {
    final refresh = await _tokens.readRefreshToken();
    try {
      if (refresh != null) await _api.post(ApiEndpoints.logout, data: {'refresh': refresh, 'device_token': deviceToken});
    } catch (_) {
      // Offline logout still clears the device.
    }
    await clearLocal();
  }

  Future<void> clearLocal() async {
    await _tokens.clear();
    await _store.remove(StoreKeys.cachedUser);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider), ref.watch(localStoreProvider)),
);
