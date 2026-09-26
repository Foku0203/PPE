import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/audit_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/core_providers.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<List<AppUser>> users({String? search, UserRole? role}) async =>
      (await _api.getList(ApiEndpoints.users, query: {'search': search, 'role': role?.apiValue, 'page_size': AppConfig.pageSize}))
          .map(AppUser.fromJson)
          .toList();

  /// Admin only: change role, supervisor or active flag (audited server-side).
  Future<AppUser> updateUser(int id, Map<String, dynamic> changes) async =>
      AppUser.fromJson(Map<String, dynamic>.from(await _api.patch(ApiEndpoints.user(id), data: changes) as Map));

  Future<List<AuditEntry>> auditLogs({String? search, String? entity}) async =>
      (await _api.getList(ApiEndpoints.auditLogs, query: {'search': search, 'entity': entity, 'page_size': AppConfig.pageSize}))
          .map(AuditEntry.fromJson)
          .toList();
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref.watch(apiClientProvider)));

final usersProvider = FutureProvider.autoDispose.family<List<AppUser>, ({String search, UserRole? role})>(
  (ref, q) => ref.watch(adminRepositoryProvider).users(search: q.search, role: q.role),
);

final auditLogsProvider = FutureProvider.autoDispose.family<List<AuditEntry>, ({String search, String? entity})>(
  (ref, q) => ref.watch(adminRepositoryProvider).auditLogs(search: q.search, entity: q.entity),
);
