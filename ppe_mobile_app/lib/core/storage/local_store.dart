import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Key/value store for non-secret local data: settings, cached catalog and
/// profile, request drafts and the offline sync queue (README §7.5).
abstract class LocalStore {
  T? get<T>(String key);
  Future<void> put(String key, Object? value);
  Future<void> remove(String key);

  Object? getJson(String key) {
    final raw = get<String>(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> putJson(String key, Object? value) => put(key, jsonEncode(value));
}

class HiveLocalStore extends LocalStore {
  HiveLocalStore._(this._box);

  static const boxName = 'ppe_app';
  final Box _box;

  static Future<HiveLocalStore> open() async {
    await Hive.initFlutter();
    return HiveLocalStore._(await Hive.openBox(boxName));
  }

  @override
  T? get<T>(String key) {
    final value = _box.get(key);
    return value is T ? value : null;
  }

  @override
  Future<void> put(String key, Object? value) => _box.put(key, value);

  @override
  Future<void> remove(String key) => _box.delete(key);
}

class MemoryLocalStore extends LocalStore {
  final Map<String, Object?> values = {};

  @override
  T? get<T>(String key) {
    final value = values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> put(String key, Object? value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

class StoreKeys {
  static const locale = 'settings.locale';
  static const biometric = 'settings.biometric';
  static const serverUrl = 'settings.server_url';
  static const themeMode = 'settings.theme_mode';
  static const cachedUser = 'cache.user';
  static String catalog(String locale) => 'cache.catalog.$locale';
  static const draftCart = 'draft.cart';
  static const offlineQueue = 'sync.queue';
}
