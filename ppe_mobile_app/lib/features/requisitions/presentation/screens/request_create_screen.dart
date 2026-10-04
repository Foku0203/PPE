import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/ppe_item_model.dart';
import '../../../../shared/models/requisition_model.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../catalog/catalog_provider.dart';
import '../../data/offline_queue.dart';
import '../../data/requisition_providers.dart';
import '../../data/requisition_repository.dart';

/// Create a requisition: pick items, size, quantity and reason; the app pre-checks
/// quota / lifespan / duplicates per line, and asks for a justification when special approval is needed.
class RequestCreateScreen extends ConsumerStatefulWidget {
  const RequestCreateScreen({super.key});

  @override
  ConsumerState<RequestCreateScreen> createState() => _RequestCreateScreenState();
}

class _RequestCreateScreenState extends ConsumerState<RequestCreateScreen> {
  final _specialReason = TextEditingController();
  bool _submitting = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _specialReason.dispose();
    super.dispose();
  }

  List<Eligibility?> _eligibilities(List<CartLine> lines) =>
      [for (final line in lines) ref.watch(eligibilityProvider((itemId: line.itemId, quantity: line.quantity))).value];

  Future<void> _submit(List<CartLine> lines, Map<int, PpeItem> catalog, bool needsSpecial) async {
    final l = context.l10n;
    setState(() => _showErrors = true);
    final missingSize = lines.any((line) => (catalog[line.itemId]?.sizes.isNotEmpty ?? false) && line.size.isEmpty);
    if (missingSize) return showError(context, ApiException(l.errSizeRequired, code: 'SIZE_REQUIRED'));
    if (needsSpecial && _specialReason.text.trim().isEmpty) {
      return showError(context, ApiException(l.errSpecialReasonRequired, code: 'SPECIAL_REASON_REQUIRED'));
    }
    final clientRequestId = const Uuid().v4();
    final reason = needsSpecial ? _specialReason.text.trim() : '';
    setState(() => _submitting = true);
    try {
      final created = await ref.read(requisitionRepositoryProvider).create(lines: lines, clientRequestId: clientRequestId, specialReason: reason);
      ref.read(cartProvider.notifier).clear();
      ref.read(dataRevisionProvider.notifier).bump();
      if (!mounted) return;
      showSuccess(context, l.requestSubmitted(created.requestNo));
      context.pushReplacement(AppRoutes.request(created.id));
    } on AppException catch (e) {
      if (e.isNetworkFailure) {
        await ref.read(offlineQueueProvider.notifier).enqueue(
              QueuedRequest(clientRequestId: clientRequestId, lines: lines, specialReason: reason, createdAt: DateTime.now()),
            );
        ref.read(cartProvider.notifier).clear();
        if (!mounted) return;
        showSuccess(context, l.requestQueued);
        context.pop();
      } else if (mounted) {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lines = ref.watch(cartProvider);
    final catalog = {for (final item in ref.watch(catalogProvider).value?.items ?? const <PpeItem>[]) item.id: item};
    final eligibilities = _eligibilities(lines);
    final needsSpecial = eligibilities.any((e) => e?.specialApprovalRequired ?? false);
    final blocked = eligibilities.any((e) => e?.isBlocked ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(l.newRequestTitle)),
      body: lines.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              message: l.cartEmpty,
              action: FilledButton.icon(onPressed: () => _pickItem(catalog), icon: const Icon(Icons.add), label: Text(l.addItem)),
            )
          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 120), children: [
              for (var i = 0; i < lines.length; i++) ...[
                _LineCard(line: lines[i], item: catalog[lines[i].itemId], eligibility: eligibilities[i], showErrors: _showErrors),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(onPressed: () => _pickItem(catalog), icon: const Icon(Icons.add), label: Text(l.addItem)),
              if (needsSpecial) ...[
                const SizedBox(height: 16),
                InfoBanner(message: l.specialApprovalNeeded, color: AppColors.special, icon: Icons.priority_high),
                const SizedBox(height: 12),
                TextField(
                  controller: _specialReason,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l.specialReasonLabel,
                    hintText: l.specialReasonHint,
                    errorText: _showErrors && _specialReason.text.trim().isEmpty ? l.fieldRequired : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ]),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _submitting || blocked ? null : () => _submit(lines, catalog, needsSpecial),
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text('${l.submitRequest} (${lines.length})'),
                ),
              ),
            ),
    );
  }

  Future<void> _pickItem(Map<int, PpeItem> catalog) async {
    final locale = ref.read(localeCodeProvider);
    final inCart = ref.read(cartProvider).map((l) => l.itemId).toSet();
    final items = catalog.values.where((i) => i.active && !inCart.contains(i.id)).toList();
    final picked = await showModalBottomSheet<PpeItem>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: items.length,
          itemBuilder: (context, i) => ListTile(
            leading: PpeImage(code: items[i].code, imageUrl: items[i].imageUrl, iconKey: items[i].iconKey, size: 44),
            title: Text(items[i].nameFor(locale)),
            subtitle: Text('${items[i].code} · ${context.l10n.stockCount('${items[i].stock}')}'),
            onTap: () => Navigator.pop(context, items[i]),
          ),
        ),
      ),
    );
    if (picked != null) ref.read(cartProvider.notifier).add(picked, locale);
  }
}

class _LineCard extends ConsumerWidget {
  const _LineCard({required this.line, required this.item, required this.eligibility, required this.showErrors});

  final CartLine line;
  final PpeItem? item;
  final Eligibility? eligibility;
  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cart = ref.read(cartProvider.notifier);
    final locale = ref.watch(localeCodeProvider);
    final sizes = item?.sizes ?? const <String>[];
    final e = eligibility;
    final (String? note, Color noteColor) = switch (e?.reason) {
      'ACTIVE_REQUEST_EXISTS' => (l.errActiveRequestExists, AppColors.danger),
      'ITEM_INACTIVE' => (l.errItemInactive, AppColors.danger),
      'QUOTA_EXCEEDED' => (l.quotaExceededLine('${e?.quota ?? ''}'), AppColors.special),
      'LIFESPAN_NOT_EXPIRED' => (l.lifespanNotExpiredLine(Fmt.date(context, e?.eligibleAt)), AppColors.special),
      'SPECIAL_ITEM' => (l.specialItemLine, AppColors.special),
      _ => (null, AppColors.success),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            PpeImage(code: line.code, imageUrl: item?.imageUrl ?? '', iconKey: item?.iconKey ?? 'shield', size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item?.nameFor(locale) ?? line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${line.code}${item != null ? ' · ${l.stockLine('${item!.stock}')}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
            IconButton(tooltip: l.remove, icon: const Icon(Icons.delete_outline), onPressed: () => cart.remove(line.itemId)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (sizes.isNotEmpty) ...[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: sizes.contains(line.size) ? line.size : null,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: l.size,
                    errorText: showErrors && line.size.isEmpty ? l.fieldRequired : null,
                  ),
                  items: [for (final s in sizes) DropdownMenuItem(value: s, child: Text(s))],
                  onChanged: (v) => cart.update(line.itemId, (c) => c.copyWith(size: v)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            _QuantityStepper(
              value: line.quantity,
              onChanged: (v) => cart.update(line.itemId, (c) => c.copyWith(quantity: v)),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<RequestReason>(
            initialValue: line.reason,
            isDense: true,
            decoration: InputDecoration(labelText: l.reason),
            items: [for (final r in RequestReason.values) DropdownMenuItem(value: r, child: Text(l.reasonLabel(r)))],
            onChanged: (v) => cart.update(line.itemId, (c) => c.copyWith(reason: v)),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline, size: 16, color: noteColor),
              const SizedBox(width: 6),
              Expanded(child: Text(note, style: TextStyle(color: noteColor, fontSize: 13))),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(visualDensity: VisualDensity.compact, onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove)),
        SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        IconButton(visualDensity: VisualDensity.compact, onPressed: value < 999 ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add)),
      ]),
    );
  }
}
