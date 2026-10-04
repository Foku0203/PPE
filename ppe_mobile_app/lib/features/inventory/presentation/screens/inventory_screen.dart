import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/ppe_item_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../app_shell/presentation/screens/app_shell.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../data/inventory_repository.dart';

/// Stock overview (README §5.5): available / reserved / issued, reorder and expiry alerts.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _lowOnly = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final summary = ref.watch(inventorySummaryProvider);
    final locale = ref.watch(localeCodeProvider);
    final role = ref.watch(authControllerProvider.select((s) => s.role));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.inventoryTitle),
        actions: [
          IconButton(tooltip: l.actionPurchaseRequests, icon: const Icon(Icons.shopping_bag_outlined), onPressed: () => context.push(AppRoutes.purchaseRequests)),
          IconButton(tooltip: l.actionScanQr, icon: const Icon(Icons.qr_code_scanner), onPressed: () => context.push(AppRoutes.scan)),
          const NotificationBell(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                decoration: InputDecoration(hintText: l.searchPpe, prefixIcon: const Icon(Icons.search), isDense: true),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilterChip(label: Text(l.filterLowStock), selected: _lowOnly, onSelected: (v) => setState(() => _lowOnly = v)),
              ),
            ),
          ]),
        ),
      ),
      // EHS oversees stock but does not receive goods into the store.
      floatingActionButton: role == UserRole.ehs
          ? null
          : FloatingActionButton.extended(
              heroTag: 'receive',
              onPressed: () => context.push(AppRoutes.receiveStock),
              icon: const Icon(Icons.move_to_inbox),
              label: Text(l.actionReceiveStock),
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(inventorySummaryProvider.future),
        child: AsyncValueView(
          value: summary,
          onRetry: () => ref.invalidate(inventorySummaryProvider),
          data: (items) {
            final visible = items
                .where((i) => !_lowOnly || i.isLowStock)
                .where((i) => _search.isEmpty || i.code.toLowerCase().contains(_search) || i.nameFor(locale).toLowerCase().contains(_search))
                .toList()
              ..sort((a, b) => (b.isLowStock ? 1 : 0).compareTo(a.isLowStock ? 1 : 0));
            if (visible.isEmpty) return ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.warehouse_outlined, message: l.noItems)]);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _StockRow(item: visible[i], locale: locale),
            );
          },
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.item, required this.locale});

  final PpeItem item;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = item.isOutOfStock ? AppColors.danger : (item.isLowStock ? AppColors.warning : AppColors.success);
    final ratio = item.reorderPoint == 0 ? 1.0 : (item.stock / (item.reorderPoint * 3)).clamp(0.0, 1.0);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.inventoryItem(item.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            PpeImage(code: item.code, imageUrl: item.imageUrl, iconKey: item.iconKey, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(item.nameFor(locale), style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (item.isLowStock) Pill(label: l.needsReorder, color: color, icon: Icons.warning_amber_rounded, dense: true),
                ]),
                Text(item.code, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: ratio, color: color, backgroundColor: color.withValues(alpha: 0.15), minHeight: 6, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 6),
                Wrap(spacing: 12, children: [
                  _metric(context, l.available, item.stock, color),
                  _metric(context, l.reserved, item.reserved, AppColors.info),
                  _metric(context, l.issued30d, item.issued30d, AppColors.neutral),
                  _metric(context, l.reorderPoint, item.reorderPoint, AppColors.neutral),
                ]),
                if (item.expiringLots > 0) ...[
                  const SizedBox(height: 4),
                  Text(l.expiringLots('${item.expiringLots}'), style: const TextStyle(color: AppColors.warning, fontSize: 12)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, int value, Color color) => Text.rich(TextSpan(children: [
        TextSpan(text: '$value ', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.readable(context, color))),
        TextSpan(text: label, style: Theme.of(context).textTheme.bodySmall),
      ]));
}
