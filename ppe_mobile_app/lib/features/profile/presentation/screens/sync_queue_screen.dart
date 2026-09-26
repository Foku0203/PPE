import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../requisitions/data/offline_queue.dart';

/// Requests created offline: pending / syncing / failed with retry & remove (README §7.5).
class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref.watch(offlineQueueProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.syncQueue),
        actions: [
          if (queue.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final result = await ref.read(offlineQueueProvider.notifier).syncAll();
                if (!context.mounted) return;
                if (result.stillOffline) {
                  showError(context, const NoInternetException());
                } else {
                  showSuccess(context, l.syncedCount('${result.sent}'));
                }
              },
              icon: const Icon(Icons.sync),
              label: Text(l.syncNow),
            ),
        ],
      ),
      body: queue.isEmpty
          ? EmptyState(icon: Icons.cloud_done_outlined, message: l.syncQueueEmpty)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: queue.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final q = queue[i];
                final (String label, Color color) = switch (q.state) {
                  SyncState.pending => (l.syncPending, AppColors.info),
                  SyncState.syncing => (l.syncSyncing, AppColors.brand),
                  SyncState.failed => (l.syncFailed, AppColors.danger),
                };
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(Fmt.dateTime(context, q.createdAt), style: const TextStyle(fontWeight: FontWeight.w600))),
                        Pill(label: label, color: color, dense: true),
                      ]),
                      const SizedBox(height: 6),
                      for (final line in q.lines) Text('• ${line.name} ×${line.quantity}${line.size.isNotEmpty ? ' (${line.size})' : ''}'),
                      if (q.state == SyncState.failed && q.errorCode != null) ...[
                        const SizedBox(height: 6),
                        Text(l.errorMessage(ApiException(q.errorMessage ?? '', code: q.errorCode!)), style: const TextStyle(color: AppColors.danger)),
                      ],
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(onPressed: () => ref.read(offlineQueueProvider.notifier).remove(q.clientRequestId), child: Text(l.remove)),
                        if (q.state == SyncState.failed)
                          TextButton(onPressed: () => ref.read(offlineQueueProvider.notifier).retry(q.clientRequestId), child: Text(l.retry)),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
