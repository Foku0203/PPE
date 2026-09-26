import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/ppe_item_model.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/labels.dart';
import '../../auth/presentation/screens/auth_provider.dart';
import '../../requisitions/data/requisition_providers.dart';
import '../catalog_provider.dart';
import '../data/catalog_repository.dart';

class PpeDetailScreen extends ConsumerWidget {
  const PpeDetailScreen({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final item = ref.watch(ppeItemProvider(itemId));
    final role = ref.watch(authControllerProvider.select((s) => s.role));
    return Scaffold(
      appBar: AppBar(
        title: Text(item.value?.code ?? ''),
        actions: [
          if (role.canManageMasterData && item.hasValue)
            IconButton(tooltip: l.editPolicy, icon: const Icon(Icons.edit_note), onPressed: () => showPolicyEditor(context, ref, item.value!)),
          if (role.isStore && item.hasValue)
            IconButton(tooltip: l.lotsTitle, icon: const Icon(Icons.warehouse_outlined), onPressed: () => context.push(AppRoutes.inventoryItem(itemId))),
        ],
      ),
      body: AsyncValueView(
        value: item,
        onRetry: () => ref.invalidate(ppeItemProvider(itemId)),
        data: (item) => _Body(item: item),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.item});

  final PpeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(localeCodeProvider);
    final inCart = ref.watch(cartProvider.select((lines) => lines.any((line) => line.itemId == item.id)));
    final theme = Theme.of(context);
    final unit = l.unit(item.unit);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: PpeImage(code: item.code, imageUrl: item.imageUrl, iconKey: item.iconKey, size: 220, radius: 20)),
      const SizedBox(height: 16),
      Text(item.nameFor(locale), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 6, children: [
        Pill(label: l.category(item.category), color: AppColors.brand),
        Pill(
          label: item.isOutOfStock ? l.outOfStock : l.stockCount('${item.stock}'),
          color: item.isOutOfStock ? AppColors.danger : (item.isLowStock ? AppColors.warning : AppColors.success),
        ),
        if (!item.active) Pill(label: l.inactive, color: AppColors.neutral),
        if (item.requiresSerial) Pill(label: l.serialControlled, color: AppColors.special, icon: Icons.qr_code_2),
        if (item.isReturnable) Pill(label: l.returnable, color: AppColors.info, icon: Icons.assignment_return_outlined),
      ]),
      const SizedBox(height: 16),
      if (item.descriptionFor(locale).isNotEmpty) ...[
        Text(item.descriptionFor(locale)),
        const SizedBox(height: 16),
      ],
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (item.quota != null) LabelValue(l.quotaLabel, '${item.quota} $unit'),
            if (item.lifespanDays != null) LabelValue(l.lifespanLabel, '${item.lifespanDays}'),
            if (item.sizes.isNotEmpty) LabelValue(l.sizes, item.sizes.join(', ')),
            LabelValue(l.reorderPoint, '${item.reorderPoint}'),
            for (final t in item.translations.values.where((t) => t.locale != locale))
              LabelValue(AppLanguage.fromCode(t.locale).nativeName, t.name),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      _EligibilityCard(itemId: item.id),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: !item.active
            ? null
            : () {
                if (!inCart) ref.read(cartProvider.notifier).add(item, locale);
                context.push(AppRoutes.newRequest);
              },
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(inCart ? l.inRequest : l.requestThis),
      ),
    ]);
  }
}

class _EligibilityCard extends ConsumerWidget {
  const _EligibilityCard({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final eligibility = ref.watch(eligibilityProvider((itemId: itemId, quantity: 1)));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.eligibilityTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          eligibility.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(l.errorMessage(e), style: TextStyle(color: Theme.of(context).colorScheme.error)),
            data: (e) {
              final (IconData icon, Color color, String text) = switch (e.reason) {
                null => (Icons.check_circle, AppColors.success, l.eligibleNow),
                'ACTIVE_REQUEST_EXISTS' => (Icons.block, AppColors.danger, l.errActiveRequestExists),
                'ITEM_INACTIVE' => (Icons.block, AppColors.danger, l.errItemInactive),
                'LIFESPAN_NOT_EXPIRED' => (Icons.schedule, AppColors.special, '${l.eligibleAt(Fmt.date(context, e.eligibleAt))}\n${l.specialApprovalNeeded}'),
                _ => (Icons.priority_high, AppColors.special, l.specialApprovalNeeded),
              };
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500))),
                ]),
                if (e.lastIssuedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(l.lastIssuedAt(Fmt.date(context, e.lastIssuedAt)), style: Theme.of(context).textTheme.bodySmall),
                ],
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

/// EHS/Admin: edit quota, lifespan, reorder point and active flag (audited with a reason).
Future<void> showPolicyEditor(BuildContext context, WidgetRef ref, PpeItem item) async {
  final l = context.l10n;
  final formKey = GlobalKey<FormState>();
  final quota = TextEditingController(text: item.quota?.toString() ?? '');
  final lifespan = TextEditingController(text: item.lifespanDays?.toString() ?? '');
  final reorder = TextEditingController(text: '${item.reorderPoint}');
  final sizes = TextEditingController(text: item.sizes.join(','));
  final reason = TextEditingController();
  var active = item.active;
  String? number(String? v, {bool allowEmpty = true}) {
    if (v == null || v.trim().isEmpty) return allowEmpty ? null : l.fieldRequired;
    return int.tryParse(v.trim()) == null || int.parse(v.trim()) < 0 ? l.invalidNumber : null;
  }

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${l.editPolicy} · ${item.code}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(controller: quota, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.quotaLabel), validator: number),
              const SizedBox(height: 12),
              TextFormField(controller: lifespan, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.lifespanLabel), validator: number),
              const SizedBox(height: 12),
              TextFormField(
                controller: reorder,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.reorderPoint),
                validator: (v) => number(v, allowEmpty: false),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: sizes, decoration: InputDecoration(labelText: l.sizes, hintText: 'S,M,L,XL')),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.activeItem), value: active, onChanged: (v) => setState(() => active = v)),
              TextFormField(
                controller: reason,
                decoration: InputDecoration(labelText: l.changeReason, helperText: l.changeReasonHint),
                validator: (v) => v == null || v.trim().isEmpty ? l.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final result = await runWithProgress(
                    context,
                    () => ref.read(catalogRepositoryProvider).updateItem(
                          item.id,
                          {
                            'quota': quota.text.trim().isEmpty ? null : int.parse(quota.text.trim()),
                            'lifespan_days': lifespan.text.trim().isEmpty ? null : int.parse(lifespan.text.trim()),
                            'reorder_point': int.parse(reorder.text.trim()),
                            'sizes': sizes.text.replaceAll(' ', ''),
                            'active': active,
                          },
                          changeReason: reason.text.trim(),
                        ),
                  );
                  if (result != null && context.mounted) Navigator.pop(context, true);
                },
                child: Text(l.save),
              ),
            ]),
          ),
        ),
      ),
    ),
  );
  if (saved == true) {
    ref.invalidate(catalogProvider);
    ref.invalidate(catalogAdminProvider);
    ref.invalidate(ppeItemProvider(item.id));
    if (context.mounted) showSuccess(context, l.policyUpdated);
  }
}
