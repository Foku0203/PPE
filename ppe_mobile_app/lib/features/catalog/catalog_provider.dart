import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/ppe_item_model.dart';
import '../../shared/providers/core_providers.dart';
import 'data/catalog_repository.dart';

/// Catalog for the current language (cached for offline use).
final catalogProvider = FutureProvider<CatalogResult>((ref) {
  final locale = ref.watch(localeCodeProvider);
  return ref.watch(catalogRepositoryProvider).fetchCatalog(locale);
});

/// Catalog including inactive items, for master-data management.
final catalogAdminProvider = FutureProvider.autoDispose<CatalogResult>((ref) {
  final locale = ref.watch(localeCodeProvider);
  return ref.watch(catalogRepositoryProvider).fetchCatalog(locale, includeInactive: true);
});

final ppeItemProvider = FutureProvider.autoDispose.family<PpeItem, int>((ref, id) async {
  final locale = ref.watch(localeCodeProvider);
  final cached = ref.read(catalogProvider).value?.items.where((i) => i.id == id).firstOrNull;
  try {
    return await ref.watch(catalogRepositoryProvider).fetchItem(id, locale);
  } catch (_) {
    if (cached != null) return cached;
    rethrow;
  }
});

final eligibilityProvider = FutureProvider.autoDispose.family<Eligibility, ({int itemId, int quantity})>(
  (ref, args) => ref.watch(catalogRepositoryProvider).checkEligibility(args.itemId, args.quantity),
);

class CatalogFilter {
  const CatalogFilter({this.search = '', this.category, this.inStockOnly = false});

  final String search;
  final PpeCategory? category;
  final bool inStockOnly;

  CatalogFilter copyWith({String? search, PpeCategory? category, bool clearCategory = false, bool? inStockOnly}) => CatalogFilter(
        search: search ?? this.search,
        category: clearCategory ? null : (category ?? this.category),
        inStockOnly: inStockOnly ?? this.inStockOnly,
      );

  List<PpeItem> apply(List<PpeItem> items, String locale) {
    final query = search.trim().toLowerCase();
    return items.where((item) {
      if (category != null && item.category != category) return false;
      if (inStockOnly && item.isOutOfStock) return false;
      if (query.isEmpty) return true;
      return item.code.toLowerCase().contains(query) ||
          item.nameFor(locale).toLowerCase().contains(query) ||
          item.translations.values.any((t) => t.name.toLowerCase().contains(query)) ||
          item.sizes.any((s) => s.toLowerCase() == query);
    }).toList();
  }
}

class CatalogFilterController extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  void setSearch(String value) => state = state.copyWith(search: value);
  void setCategory(PpeCategory? category) => state = category == null ? state.copyWith(clearCategory: true) : state.copyWith(category: category);
  void toggleInStock() => state = state.copyWith(inStockOnly: !state.inStockOnly);
}

final catalogFilterProvider = NotifierProvider<CatalogFilterController, CatalogFilter>(CatalogFilterController.new);
