import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/models/requisition_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/labels.dart';
import '../../app_shell/presentation/screens/app_shell.dart';
import '../../requisitions/data/requisition_providers.dart';
import '../../requisitions/data/requisition_repository.dart';
import '../../requisitions/presentation/screens/requests_screen.dart';

/// Store fulfilment queue (README §6 steps 7–8): approved → reserve/prepare, on hold, ready → issue via QR.
class StoreQueueScreen extends ConsumerWidget {
  const StoreQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    RequisitionQuery q(RequisitionStatus s) => (scope: RequisitionScope.store, statuses: s.apiValue, search: null);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.storeTitle),
          actions: [
            IconButton(tooltip: l.actionReceiveStock, icon: const Icon(Icons.move_to_inbox_outlined), onPressed: () => context.push(AppRoutes.receiveStock)),
            const NotificationBell(),
          ],
          bottom: TabBar(tabs: [Tab(text: l.tabToPrepare), Tab(text: l.tabOnHold), Tab(text: l.tabReady)]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'scan',
          onPressed: () => context.push(AppRoutes.scan),
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l.scanPickupQr),
        ),
        body: TabBarView(children: [
          RequisitionListView(query: q(RequisitionStatus.approved), showRequester: true, trailingBuilder: (r) => _PrepareButton(requisition: r)),
          RequisitionListView(query: q(RequisitionStatus.onHold), showRequester: true, trailingBuilder: (r) => _PrepareButton(requisition: r)),
          RequisitionListView(query: q(RequisitionStatus.ready), showRequester: true),
        ]),
      ),
    );
  }
}

class _PrepareButton extends ConsumerWidget {
  const _PrepareButton({required this.requisition});

  final Requisition requisition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!requisition.actions.canPrepare) return const SizedBox.shrink();
    return IconButton.filledTonal(
      tooltip: l.prepare,
      icon: const Icon(Icons.inventory),
      onPressed: () async {
        final result = await runWithProgress(context, () => ref.read(requisitionRepositoryProvider).prepare(requisition.id));
        if (result != null && context.mounted) {
          ref.read(dataRevisionProvider.notifier).bump();
          showSuccess(context, result.status == RequisitionStatus.onHold ? l.onHoldMsg : l.preparedMsg);
        }
      },
    );
  }
}
