import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/models/ppe_item_model.dart';
import '../../shared/providers/core_providers.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/labels.dart';
import '../app_shell/presentation/screens/app_shell.dart';
import '../auth/presentation/screens/auth_provider.dart';
import '../requisitions/data/requisition_providers.dart';
import 'catalog_provider.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final catalog = ref.watch(catalogProvider);
    final filter = ref.watch(catalogFilterProvider);
    final locale = ref.watch(localeCodeProvider);
    final cartCount = ref.watch(cartProvider).length;
    final canManage = ref.watch(authControllerProvider.select((s) => s.role.canManageMasterData));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.catalogTitle),
        actions: [
          if (canManage) IconButton(tooltip: l.actionManageCatalog, icon: const Icon(Icons.tune), onPressed: () => context.push(AppRoutes.manageCatalog)),
          IconButton(
            tooltip: l.newRequestTitle,
            onPressed: () => context.push(AppRoutes.newRequest),
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
          ),
          const NotificationBell(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: ref.read(catalogFilterProvider.notifier).setSearch,
                decoration: InputDecoration(hintText: l.searchPpe, prefixIcon: const Icon(Icons.search), isDense: true),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip(context, l.inStockOnly, filter.inStockOnly, () => ref.read(catalogFilterProvider.notifier).toggleInStock(), icon: Icons.inventory),
                  _chip(context, l.all, filter.category == null, () => ref.read(catalogFilterProvider.notifier).setCategory(null)),
                  for (final c in PpeCategory.values)
                    _chip(context, l.category(c), filter.category == c, () => ref.read(catalogFilterProvider.notifier).setCategory(c)),
                ],
              ),
            ),
          ]),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(catalogProvider.future),
        child: AsyncValueView(
          value: catalog,
          onRetry: () => ref.invalidate(catalogProvider),
          data: (result) {
            final items = filter.apply(result.items, locale);
            return CustomScrollView(slivers: [
              if (result.fromCache)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: InfoBanner(message: l.offlineBanner, color: AppColors.warning, icon: Icons.wifi_off),
                  ),
                ),
              if (items.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off, message: l.noItems))
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 240, mainAxisExtent: 268, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    delegate: SliverChildBuilderDelegate((context, i) => PpeCard(item: items[i]), childCount: items.length),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap, {IconData? icon}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), avatar: icon == null ? null : Icon(icon, size: 16)),
      );
}

class PpeCard extends ConsumerWidget {
  const PpeCard({super.key, required this.item});

  final PpeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(localeCodeProvider);
    final inCart = ref.watch(cartProvider.select((lines) => lines.any((line) => line.itemId == item.id)));
    final stockColor = item.isOutOfStock ? AppColors.danger : (item.isLowStock ? AppColors.warning : AppColors.success);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.ppeItem(item.id)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: PpeImage(code: item.code, imageUrl: item.imageUrl, iconKey: item.iconKey, size: 110)),
            const SizedBox(height: 8),
            Text(item.nameFor(locale), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(item.code, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Row(children: [
              Expanded(
                child: Pill(
                  label: item.isOutOfStock ? l.outOfStock : l.stockCount('${item.stock}'),
                  color: stockColor,
                  dense: true,
                ),
              ),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: inCart ? l.inRequest : l.addToRequest,
                onPressed: inCart || !item.active
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).add(item, locale);
                        showSuccess(context, '${item.nameFor(locale)} · ${l.inRequest}');
                      },
                icon: Icon(inCart ? Icons.check : Icons.add_shopping_cart, size: 20),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
