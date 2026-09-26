import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/requisition_model.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../app_shell/presentation/screens/app_shell.dart';
import '../../../requisitions/data/requisition_providers.dart';
import '../../../requisitions/data/requisition_repository.dart';
import '../../../requisitions/presentation/screens/requests_screen.dart';

/// Approver inbox (README §5.4): requests waiting for *this* user's decision, oldest first, with SLA flags.
class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key});

  static const RequisitionQuery query = (scope: RequisitionScope.inbox, statuses: null, search: null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.approvalsTitle), actions: const [NotificationBell()]),
      body: RequisitionListView(
        query: query,
        showRequester: true,
        emptyMessage: l.noApprovals,
        trailingBuilder: (r) => _QuickDecision(requisition: r),
      ),
    );
  }
}

class _QuickDecision extends ConsumerWidget {
  const _QuickDecision({required this.requisition});

  final Requisition requisition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!requisition.actions.canApprove) return const SizedBox.shrink();
    Future<void> decide(String decision) async {
      String reason = '';
      if (decision == 'REJECTED') {
        final input = await textInputDialog(context, title: l.reject, label: l.rejectReason, required: true, confirmLabel: l.reject);
        if (input == null) return;
        reason = input;
      }
      if (!context.mounted) return;
      final result = await runWithProgress(context, () => ref.read(requisitionRepositoryProvider).decide(requisition.id, decision, reason: reason));
      if (result != null && context.mounted) {
        ref.read(dataRevisionProvider.notifier).bump();
        showSuccess(context, decision == 'APPROVED' ? l.approvedMsg : l.rejectedMsg);
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      IconButton.filledTonal(
        tooltip: l.approve,
        style: IconButton.styleFrom(foregroundColor: AppColors.success),
        onPressed: () => decide('APPROVED'),
        icon: const Icon(Icons.check),
      ),
      IconButton(tooltip: l.reject, color: AppColors.danger, onPressed: () => decide('REJECTED'), icon: const Icon(Icons.close)),
    ]);
  }
}
