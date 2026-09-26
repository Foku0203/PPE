import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes/app_router.dart';
import '../../app/routes/app_routes.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/requisitions/data/requisition_providers.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// FCM/APNs push (README §5.6). Enabled when Firebase is configured for the build
/// (google-services.json / GoogleService-Info.plist). Without it the app silently falls
/// back to polling the notification endpoint, so every feature still works.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  bool _started = false;
  String? token;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  String get _platform => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'IOS',
        TargetPlatform.android => 'ANDROID',
        _ => 'WEB',
      };

  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Push notifications disabled (Firebase not configured): $e');
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      token = await messaging.getToken();
      await _register(token);
      _subscriptions
        ..add(messaging.onTokenRefresh.listen((t) {
          token = t;
          _register(t);
        }))
        ..add(FirebaseMessaging.onMessage.listen(_onForeground))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      debugPrint('Push setup failed: $e');
    }
  }

  Future<void> _register(String? value) async {
    if (value == null) return;
    try {
      await _ref.read(authRepositoryProvider).registerDevice(value, _platform);
    } catch (_) {}
  }

  void _onForeground(RemoteMessage message) {
    _ref.read(unreadCountProvider.notifier).refresh();
    _ref.read(dataRevisionProvider.notifier).bump();
    final title = message.notification?.title;
    if (title != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(title),
        action: _requisitionId(message) == null ? null : SnackBarAction(label: '›', onPressed: () => _open(message)),
      ));
    }
  }

  int? _requisitionId(RemoteMessage m) => int.tryParse('${m.data['requisition_id'] ?? ''}');

  void _open(RemoteMessage message) {
    final id = _requisitionId(message);
    _ref.read(routerProvider).push(id != null ? AppRoutes.request(id) : AppRoutes.notifications);
  }

  Future<void> stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _started = false;
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  ref.onDispose(service.stop);
  return service;
});
