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
import '../../../catalog/catalog_provider.dart';
import '../../../requisitions/data/requisition_providers.dart';
import '../../data/inventory_repository.dart';

/// Lots / serials for one PPE item with adjust & write-off, plus stock movements.
class InventoryItemScreen extends ConsumerWidget {
  const InventoryItemScreen({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final item = ref.watch(ppeItemProvider(itemId));
    final lots = ref.watch(lotsForItemProvider(itemId));
    final events = ref.watch(stockEventsProvider(itemId));
    final locale = ref.watch(localeCodeProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.value?.nameFor(locale) ?? ''),
          bottom: TabBar(tabs: [Tab(text: l.lotsTitle), Tab(text: l.stockMovements)]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'receive-item',
          onPressed: () => context.push('${AppRoutes.receiveStock}?item=$itemId'),
          icon: const Icon(Icons.move_to_inbox),
          label: Text(l.actionReceiveStock),
        ),
        body: TabBarView(children: [
          RefreshIndicator(
            onRefresh: () => ref.refresh(lotsForItemProvider(itemId).future),
            child: AsyncValueView(
              value: lots,
              onRetry: () => ref.invalidate(lotsForItemProvider(itemId)),
              data: (lots) => lots.isEmpty
                  ? ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.inventory_2_outlined, message: l.noLots)])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: lots.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _LotCard(lot: lots[i]),
                    ),
            ),
          ),
          AsyncValueView(
            value: events,
            onRetry: () => ref.invalidate(stockEventsProvider(itemId)),
            data: (events) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: events.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = events[i];
                final positive = e.eventType == 'RECEIPT' || e.eventType == 'RETURN' || (e.eventType == 'ADJUSTMENT' && e.quantity > 0);
                return ListTile(
                  dense: true,
                  leading: Icon(positive ? Icons.add_circle_outline : Icons.remove_circle_outline, color: positive ? AppColors.success : AppColors.warning),
                  title: Text('${l.stockEvent(e.eventType)} ${e.quantity.abs()}${e.requestNo != null ? ' · ${e.requestNo}' : ''}'),
                  subtitle: Text([
                    if (e.lotNumber.isNotEmpty) '${l.lot} ${e.lotNumber}',
                    if ((e.serialNumber ?? '').isNotEmpty) e.serialNumber!,
                    if (e.receiverName != null) '→ ${e.receiverName}',
                    if (e.metadata['reason'] != null) '${e.metadata['reason']}',
                    Fmt.dateTime(context, e.createdAt),
                  ].join(' · ')),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _LotCard extends ConsumerWidget {
  const _LotCard({required this.lot});

  final StockLot lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                lot.serialNumber?.isNotEmpty == true ? '${l.serial} ${lot.serialNumber}' : '${l.lot} ${lot.lotNumber.isEmpty ? '#${lot.id}' : lot.lotNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (lot.isExpired) Pill(label: l.expired, color: AppColors.danger, dense: true),
            if (lot.expiresSoon) Pill(label: l.expiresSoon, color: AppColors.warning, dense: true),
            if (lot.serialNumber != null) ...[const SizedBox(width: 4), Pill(label: lot.serialStatus, color: AppColors.neutral, dense: true)],
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 16, runSpacing: 4, children: [
            Text('${l.available}: ${lot.availableQuantity}'),
            Text('${l.reserved}: ${lot.reservedQuantity}'),
            if (lot.expiryAt != null) Text('${l.expiry}: ${Fmt.date(context, lot.expiryAt)}'),
            if (lot.supplier.isNotEmpty) Text('${l.supplier}: ${lot.supplier}'),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(onPressed: () => _adjust(context, ref), icon: const Icon(Icons.tune, size: 18), label: Text(l.adjustStock)),
          ),
        ]),
      ),
    );
  }

  Future<void> _adjust(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final delta = TextEditingController();
    final reason = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var damage = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.adjustStock),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: delta,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(labelText: l.adjustDelta),
                validator: (v) => int.tryParse(v?.trim() ?? '') == null || int.parse(v!.trim()) == 0 ? l.invalidNumber : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: reason,
                decoration: InputDecoration(labelText: l.reason),
                validator: (v) => v == null || v.trim().isEmpty ? l.fieldRequired : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: damage,
                onChanged: (v) => setState(() => damage = v ?? false),
                title: Text(l.writeOffDamaged),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => formKey.currentState!.validate() ? Navigator.pop(context, true) : null, child: Text(l.save)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await runWithProgress(
      context,
      () => ref.read(inventoryRepositoryProvider).adjust(lot.id, delta: int.parse(delta.text.trim()), reason: reason.text.trim(), eventType: damage ? 'DAMAGE' : 'ADJUSTMENT'),
    );
    if (result != null && context.mounted) {
      ref.read(dataRevisionProvider.notifier).bump();
      ref.invalidate(catalogProvider);
      showSuccess(context, l.adjusted);
    }
  }
}
