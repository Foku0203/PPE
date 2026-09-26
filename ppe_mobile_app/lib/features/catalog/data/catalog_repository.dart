import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../shared/models/ppe_item_model.dart';
import '../../../shared/providers/core_providers.dart';

class CatalogResult {
  const CatalogResult(this.items, {this.fromCache = false});

  final List<PpeItem> items;

  /// True when served from the offline cache because the server was unreachable.
  final bool fromCache;
}

class CatalogRepository {
  CatalogRepository(this._api, this._store);

  final ApiClient _api;
  final LocalStore _store;

  /// Full catalog for [locale]; falls back to the last cached copy when offline.
  Future<CatalogResult> fetchCatalog(String locale, {bool includeInactive = false}) async {
    try {
      final rows = await _api.getList(ApiEndpoints.catalog, query: {'locale': locale, if (includeInactive) 'include_inactive': '1'});
      if (!includeInactive) await _store.putJson(StoreKeys.catalog(locale), rows);
      return CatalogResult(rows.map(PpeItem.fromJson).toList());
    } on AppException catch (e) {
      final cached = _store.getJson(StoreKeys.catalog(locale));
      if (e.isNetworkFailure && cached is List) {
        return CatalogResult(ApiClient.unwrapList(cached).map(PpeItem.fromJson).toList(), fromCache: true);
      }
      rethrow;
    }
  }

  Future<PpeItem> fetchItem(int id, String locale) async =>
      PpeItem.fromJson(Map<String, dynamic>.from(await _api.get(ApiEndpoints.catalogItem(id), query: {'locale': locale}) as Map));

  Future<Eligibility> checkEligibility(int id, int quantity) async =>
      Eligibility.fromJson(Map<String, dynamic>.from(await _api.get(ApiEndpoints.eligibility(id), query: {'quantity': quantity}) as Map));

  /// Master data update (EHS/Admin). Policy fields require [changeReason] (audited server-side).
  Future<PpeItem> updateItem(int id, Map<String, dynamic> changes, {String changeReason = ''}) async => PpeItem.fromJson(
        Map<String, dynamic>.from(await _api.patch(ApiEndpoints.catalogItem(id), data: {...changes, 'change_reason': changeReason}) as Map),
      );

  Future<PpeItem> createItem(Map<String, dynamic> data) async =>
      PpeItem.fromJson(Map<String, dynamic>.from(await _api.post(ApiEndpoints.catalog, data: data) as Map));
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(apiClientProvider), ref.watch(localStoreProvider)));
