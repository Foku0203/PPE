import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.locked = false, this.offline = false, this.sessionExpired = false});

  final AuthStatus status;
  final AppUser? user;

  /// Biometric lock is active: the session exists but UI stays hidden until unlocked.
  final bool locked;

  /// Session restored from cache because the server was unreachable.
  final bool offline;

  /// Set when the server rejected the refresh token (shown once on the login screen).
  final bool sessionExpired;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  UserRole get role => user?.role ?? UserRole.worker;

  AuthState copyWith({AuthStatus? status, AppUser? user, bool? locked, bool? offline, bool? sessionExpired}) => AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        locked: locked ?? this.locked,
        offline: offline ?? this.offline,
        sessionExpired: sessionExpired ?? this.sessionExpired,
      );
}

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState(status: AuthStatus.unknown);
  }

  /// Restores the session on app start (README Phase 1: session restore).
  Future<void> restore() async {
    if (!await _repo.hasSession()) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    final locked = ref.read(settingsProvider).biometricEnabled;
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user, locked: locked);
    } on AppException catch (e) {
      final cached = _repo.cachedUser();
      if (e.isNetworkFailure && cached != null) {
        state = AuthState(status: AuthStatus.authenticated, user: cached, locked: locked, offline: true);
      } else {
        await _repo.clearLocal();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> login(String employeeId, String password) async {
    final user = await _repo.login(employeeId, password);
    await _applyUserLanguage(user);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> register(RegisterInput input) async {
    final user = await _repo.register(input);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> _applyUserLanguage(AppUser user) async {
    await ref.read(settingsProvider.notifier).setLanguage(AppLanguage.fromCode(user.locale));
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repo.me();
      state = state.copyWith(user: user, offline: false);
    } catch (_) {}
  }

  Future<void> updateProfile(Map<String, dynamic> changes) async {
    final user = await _repo.updateMe(changes);
    state = state.copyWith(user: user);
  }

  Future<void> logout({String? deviceToken}) async {
    await _repo.logout(deviceToken: deviceToken);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void onSessionExpired() {
    if (state.status != AuthStatus.authenticated) return;
    unawaited(_repo.clearLocal());
    state = const AuthState(status: AuthStatus.unauthenticated, sessionExpired: true);
  }

  void lock() {
    if (state.isAuthenticated && ref.read(settingsProvider).biometricEnabled) state = state.copyWith(locked: true);
  }

  void unlock() => state = state.copyWith(locked: false);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience accessor for the signed-in user (null while signed out).
final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authControllerProvider.select((s) => s.user)));
