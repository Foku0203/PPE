import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../data/notification_repository.dart';

/// In-app notification feed (README §5.6) with read/unread persistence on the backend.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationKind kind) => switch (kind) {
        NotificationKind.newRequisition => Icons.note_add_outlined,
        NotificationKind.approvalResult => Icons.fact_check_outlined,
        NotificationKind.readyForPickup => Icons.local_shipping_outlined,
        NotificationKind.reorderPoint => Icons.warning_amber_rounded,
        NotificationKind.infoRequested => Icons.forum_outlined,
        NotificationKind.issued => Icons.task_alt,
        NotificationKind.onHold => Icons.pause_circle_outline,
        NotificationKind.other => Icons.notifications_outlined,
      };

  Future<void> _setRead(WidgetRef ref, AppNotification n, bool read) async {
    await ref.read(notificationRepositoryProvider).setRead(n.id, read: read);
    ref.invalidate(notificationsProvider);
    await ref.read(unreadCountProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(notificationsProvider);
    final role = ref.watch(authControllerProvider.select((s) => s.role));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(notificationRepositoryProvider).readAll();
                ref.invalidate(notificationsProvider);
                ref.read(unreadCountProvider.notifier).set(0);
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(notificationsProvider),
          data: (items) => items.isEmpty
              ? ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.notifications_none, message: l.noNotifications)])
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final color = n.kind == NotificationKind.reorderPoint ? AppColors.warning : AppColors.brand;
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _setRead(ref, n, !n.isRead);
                        return false;
                      },
                      background: Container(
                        color: AppColors.info.withValues(alpha: 0.15),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(n.isRead ? l.markUnread : l.markRead),
                      ),
                      child: ListTile(
                        tileColor: n.isRead ? null : color.withValues(alpha: 0.06),
                        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(_icon(n.kind), color: color)),
                        title: Text(l.notificationTitle(n), style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.w700)),
                        subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(Fmt.relative(context, n.createdAt), style: Theme.of(context).textTheme.bodySmall),
                          if (!n.isRead) const Padding(padding: EdgeInsets.only(top: 4), child: CircleAvatar(radius: 4, backgroundColor: AppColors.brand)),
                        ]),
                        onTap: () async {
                          if (!n.isRead) _setRead(ref, n, true).ignore();
                          if (n.requisitionId != null) {
                            context.push(AppRoutes.request(n.requisitionId!));
                          } else if (n.ppeItemId != null && role.isStore) {
                            context.push(AppRoutes.inventoryItem(n.ppeItemId!));
                          } else if (n.payload['purchase_request_id'] != null && role.isStore) {
                            context.push(AppRoutes.purchaseRequests);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
