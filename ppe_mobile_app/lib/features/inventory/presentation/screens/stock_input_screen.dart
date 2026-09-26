import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/ppe_item_model.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../catalog/catalog_provider.dart';
import '../../../requisitions/data/requisition_providers.dart';
import '../../data/inventory_repository.dart';
import 'qr_scanner_screen.dart';

/// Receive stock into the store: lot/expiry for consumables, one serial per unit for harnesses.
class StockInputScreen extends ConsumerStatefulWidget {
  const StockInputScreen({super.key, this.ppeItemId, this.purchaseRequestId, this.quantity});

  final int? ppeItemId;
  final int? purchaseRequestId;
  final int? quantity;

  @override
  ConsumerState<StockInputScreen> createState() => _StockInputScreenState();
}

class _StockInputScreenState extends ConsumerState<StockInputScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _quantity = TextEditingController(text: widget.quantity?.toString() ?? '');
  final _lot = TextEditingController();
  final _supplier = TextEditingController();
  final _serials = TextEditingController();
  int? _itemId;
  DateTime? _expiry;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _itemId = widget.ppeItemId;
  }

  @override
  void dispose() {
    for (final c in [_quantity, _lot, _supplier, _serials]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _serialList => _serials.text.split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _submit(PpeItem item) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l = context.l10n;
    try {
      final quantity = item.requiresSerial ? _serialList.length : int.parse(_quantity.text.trim());
      final lots = await ref.read(inventoryRepositoryProvider).receive(ReceiveStockInput(
            ppeItemId: item.id,
            quantity: quantity,
            lotNumber: _lot.text.trim(),
            supplier: _supplier.text.trim(),
            serialNumbers: item.requiresSerial ? _serialList : const [],
            expiryAt: _expiry,
            purchaseRequestId: widget.purchaseRequestId,
          ));
      ref.read(dataRevisionProvider.notifier).bump();
      ref.invalidate(catalogProvider);
      if (!mounted) return;
      showSuccess(context, l.receivedMsg('${lots.fold<int>(0, (s, lot) => s + lot.quantity)}'));
      context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = ref.watch(localeCodeProvider);
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.receiveStockTitle)),
      body: AsyncValueView(
        value: catalog,
        onRetry: () => ref.invalidate(catalogProvider),
        data: (result) {
          final items = result.items;
          final item = items.where((i) => i.id == _itemId).firstOrNull;
          return Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (widget.purchaseRequestId != null) ...[
                InfoBanner(message: '${l.purchaseRequest} #${widget.purchaseRequestId}', color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<int>(
                initialValue: _itemId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.ppeItem),
                items: [for (final i in items) DropdownMenuItem(value: i.id, child: Text('${i.code} · ${i.nameFor(locale)}', overflow: TextOverflow.ellipsis))],
                onChanged: widget.purchaseRequestId != null ? null : (v) => setState(() => _itemId = v),
                validator: (v) => v == null ? l.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              if (item?.requiresSerial ?? false) ...[
                TextFormField(
                  controller: _serials,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(labelText: l.serialNumbers, hintText: l.serialHint, helperText: l.errSerialRequired),
                  validator: (_) => _serialList.isEmpty ? l.fieldRequired : null,
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen(returnRawValue: true)));
                      if (code != null) setState(() => _serials.text = [..._serialList, code].join('\n'));
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text('${l.actionScanQr} (${_serialList.length})'),
                  ),
                ),
              ] else
                TextFormField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.quantity),
                  validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? l.invalidNumber : null,
                ),
              const SizedBox(height: 12),
              TextFormField(controller: _lot, decoration: InputDecoration(labelText: '${l.lotNumber} (${l.optional})')),
              const SizedBox(height: 12),
              TextFormField(controller: _supplier, decoration: InputDecoration(labelText: '${l.supplier} (${l.optional})')),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(labelText: '${l.expiryDate} (${l.optional})'),
                child: Row(children: [
                  Expanded(child: Text(_expiry == null ? '-' : Fmt.date(context, _expiry))),
                  if (_expiry != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _expiry = null)),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: now.add(const Duration(days: 1)),
                        lastDate: DateTime(now.year + 15),
                        initialDate: _expiry ?? now.add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _expiry = picked);
                    },
                    child: Text(l.pickDate),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving || item == null ? null : () => _submit(item),
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.move_to_inbox),
                label: Text(l.actionReceiveStock),
              ),
            ]),
          );
        },
      ),
    );
  }
}
