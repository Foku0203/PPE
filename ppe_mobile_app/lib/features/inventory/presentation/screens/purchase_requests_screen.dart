import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/inventory_models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../../catalog/catalog_provider.dart';
import '../../../requisitions/data/requisition_providers.dart';
import '../../data/inventory_repository.dart';

/// Replenishment: EHS/Admin raise purchase requests, store approves → orders → receives into stock.
class PurchaseRequestsScreen extends ConsumerWidget {
  const PurchaseRequestsScreen({super.key});

  Color _color(String status) => switch (status) {
        'APPROVED' => AppColors.brand,
        'ORDERED' => AppColors.info,
        'RECEIVED' => AppColors.success,
        'REJECTED' => AppColors.danger,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final requests = ref.watch(purchaseRequestsProvider);
    final canCreate = ref.watch(authControllerProvider.select((s) => s.role.canManageMasterData));
    return Scaffold(
      appBar: AppBar(title: Text(l.purchaseRequestsTitle)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(onPressed: () => _create(context, ref), icon: const Icon(Icons.add), label: Text(l.newPurchaseRequest))
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(purchaseRequestsProvider.future),
        child: AsyncValueView(
          value: requests,
          onRetry: () => ref.invalidate(purchaseRequestsProvider),
          data: (items) => items.isEmpty
              ? ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.shopping_bag_outlined, message: l.noPurchaseRequests)])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _card(context, ref, items[i]),
                ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, PurchaseRequest pr) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            PpeImage(code: pr.ppeCode, size: 44, radius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${pr.ppeName} ×${pr.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${pr.requestNo} · ${pr.requesterName} · ${Fmt.date(context, pr.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            Pill(label: l.purchaseStatus(pr.status), color: _color(pr.status), dense: true),
          ]),
          if (pr.reason.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(pr.reason)),
          if (pr.nextStatuses.isNotEmpty || pr.status == 'ORDERED')
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 8, children: [
                for (final next in pr.nextStatuses)
                  TextButton(
                    style: next == 'REJECTED' ? TextButton.styleFrom(foregroundColor: AppColors.danger) : null,
                    onPressed: () async {
                      final result = await runWithProgress(context, () => ref.read(inventoryRepositoryProvider).setPurchaseStatus(pr.id, next));
                      if (result != null) ref.read(dataRevisionProvider.notifier).bump();
                    },
                    child: Text(l.markAs(l.purchaseStatus(next))),
                  ),
                if (pr.status == 'ORDERED')
                  FilledButton.tonal(
                    onPressed: () => context.push('${AppRoutes.receiveStock}?item=${pr.ppeItemId}&pr=${pr.id}&qty=${pr.quantity}'),
                    child: Text(l.receiveIntoStock),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final locale = ref.read(localeCodeProvider);
    final items = ref.read(catalogProvider).value?.items ?? const [];
    final formKey = GlobalKey<FormState>();
    final qty = TextEditingController();
    final reason = TextEditingController();
    int? itemId = items.where((i) => i.isLowStock).firstOrNull?.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.newPurchaseRequest),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                initialValue: itemId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.ppeItem),
                items: [
                  for (final i in items)
                    DropdownMenuItem(value: i.id, child: Text('${i.code} · ${i.nameFor(locale)} (${i.stock})', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => itemId = v),
                validator: (v) => v == null ? l.fieldRequired : null,
              ),
              TextFormField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.quantity),
                validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? l.invalidNumber : null,
              ),
              TextFormField(controller: reason, decoration: InputDecoration(labelText: l.reason), validator: (v) => v == null || v.trim().isEmpty ? l.fieldRequired : null),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => formKey.currentState!.validate() ? Navigator.pop(context, true) : null, child: Text(l.submit)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await runWithProgress(
      context,
      () => ref.read(inventoryRepositoryProvider).createPurchaseRequest(ppeItemId: itemId!, quantity: int.parse(qty.text.trim()), reason: reason.text.trim()),
    );
    if (result != null) ref.read(dataRevisionProvider.notifier).bump();
  }
}
