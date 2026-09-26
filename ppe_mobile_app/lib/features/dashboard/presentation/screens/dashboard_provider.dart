import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/models/dashboard_model.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../requisitions/data/requisition_providers.dart';

/// Role-scoped KPI summary (`GET /dashboard/summary/`).
final dashboardProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  ref.watch(dataRevisionProvider);
  ref.watch(localeCodeProvider);
  final data = await ref.watch(apiClientProvider).get(ApiEndpoints.dashboard);
  return DashboardSummary.fromJson(Map<String, dynamic>.from(data as Map));
});
