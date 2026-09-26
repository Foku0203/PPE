import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/ppe_item_model.dart';
import '../../../shared/models/requisition_model.dart';
import '../../../shared/providers/core_providers.dart';
import 'requisition_repository.dart';

typedef RequisitionQuery = ({String scope, String? statuses, String? search});

/// Bumped after any mutation (create/approve/issue/…, push received) so every
/// provider that shows requisition or stock data re-fetches.
class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dataRevisionProvider = NotifierProvider<DataRevision, int>(DataRevision.new);

final requisitionListProvider = FutureProvider.autoDispose.family<List<Requisition>, RequisitionQuery>((ref, q) {
  ref.watch(dataRevisionProvider);
  return ref.watch(requisitionRepositoryProvider).list(scope: q.scope, statuses: q.statuses?.split(','), search: q.search);
});

final requisitionDetailProvider = FutureProvider.autoDispose.family<Requisition, int>((ref, id) {
  ref.watch(dataRevisionProvider);
  return ref.watch(requisitionRepositoryProvider).detail(id);
});

final issuedItemsProvider = FutureProvider.autoDispose<IssuedItems>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(requisitionRepositoryProvider).myIssuedItems();
});

/// Draft "cart" for a new request, persisted so it survives app restarts (README §7.5).
class CartController extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => asMapList(ref.watch(localStoreProvider).getJson(StoreKeys.draftCart)).map(CartLine.fromJson).toList();

  Future<void> _save() => ref.read(localStoreProvider).putJson(StoreKeys.draftCart, state.map((l) => l.toJson()).toList());

  bool contains(int itemId) => state.any((l) => l.itemId == itemId);

  void add(PpeItem item, String locale) {
    if (contains(item.id)) return;
    state = [...state, CartLine(itemId: item.id, code: item.code, name: item.nameFor(locale), size: item.sizes.length == 1 ? item.sizes.first : '')];
    _save();
  }

  void update(int itemId, CartLine Function(CartLine) change) {
    state = [for (final l in state) l.itemId == itemId ? change(l) : l];
    _save();
  }

  void remove(int itemId) {
    state = state.where((l) => l.itemId != itemId).toList();
    _save();
  }

  void clear() {
    state = const [];
    _save();
  }
}

final cartProvider = NotifierProvider<CartController, List<CartLine>>(CartController.new);
