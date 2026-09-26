import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/presentation/screens/auth_provider.dart';
import '../../requisitions/data/requisition_providers.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> list({bool unreadOnly = false}) async =>
      (await _api.getList(ApiEndpoints.notifications, query: {'unread': unreadOnly ? '1' : null, 'page_size': AppConfig.pageSize}))
          .map(AppNotification.fromJson)
          .toList();

  Future<AppNotification> setRead(int id, {bool read = true}) async => AppNotification.fromJson(
        Map<String, dynamic>.from(await _api.post(ApiEndpoints.notificationRead(id), data: read ? const {} : {'unread': true}) as Map),
      );

  Future<void> readAll() => _api.post(ApiEndpoints.notificationsReadAll);

  Future<int> unreadCount() async => ((await _api.get(ApiEndpoints.notificationsUnreadCount)) as Map)['unread_count'] as int? ?? 0;
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(apiClientProvider)));

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(notificationRepositoryProvider).list();
});

/// Unread badge count. Polls while signed in (fallback when push is not configured)
/// and bumps [dataRevisionProvider] when new notifications arrive so open screens refresh.
class UnreadCountController extends Notifier<int> {
  Timer? _timer;

  @override
  int build() {
    final signedIn = ref.watch(authControllerProvider.select((s) => s.isAuthenticated && !s.locked));
    _timer?.cancel();
    ref.onDispose(() => _timer?.cancel());
    if (signedIn) {
      Future.microtask(refresh);
      _timer = Timer.periodic(AppConfig.notificationPollInterval, (_) => refresh());
    }
    return 0;
  }

  Future<void> refresh() async {
    try {
      final count = await ref.read(notificationRepositoryProvider).unreadCount();
      if (count > state) ref.read(dataRevisionProvider.notifier).bump();
      state = count;
    } catch (_) {
      // Offline: keep last value.
    }
  }

  void set(int value) => state = value < 0 ? 0 : value;
}

final unreadCountProvider = NotifierProvider<UnreadCountController, int>(UnreadCountController.new);
