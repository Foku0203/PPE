import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/models/requisition_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../../shared/widgets/requisition_card.dart';
import '../../../app_shell/presentation/screens/app_shell.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../data/requisition_providers.dart';
import '../../data/requisition_repository.dart';

const activeStatuses = 'PENDING_APPROVAL,SPECIAL_APPROVAL_REQUIRED,APPROVED,ON_HOLD_STOCK,READY_FOR_PICKUP';
const historyStatuses = 'COMPLETED,REJECTED,CANCELLED';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  String? _scope;
  String _search = '';

  List<(String, String)> _scopes(UserRole role) {
    final l = context.l10n;
    return switch (role) {
      UserRole.worker => const [],
      UserRole.supervisor => [(RequisitionScope.mine, l.scopeMine), (RequisitionScope.team, l.scopeTeam)],
      _ => [(RequisitionScope.mine, l.scopeMine), (RequisitionScope.visible, l.scopeAll)],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = ref.watch(authControllerProvider.select((s) => s.role));
    final scopes = _scopes(role);
    final scope = _scope ?? (scopes.isEmpty ? RequisitionScope.mine : scopes.last.$1);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.requestsTitle),
          actions: const [NotificationBell()],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(scopes.isEmpty ? 104 : 152),
            child: Column(children: [
              if (scopes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<String>(
                    segments: [for (final (value, label) in scopes) ButtonSegment(value: value, label: Text(label))],
                    selected: {scope},
                    onSelectionChanged: (s) => setState(() => _scope = s.first),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: TextField(
                  onSubmitted: (v) => setState(() => _search = v.trim()),
                  decoration: InputDecoration(hintText: l.searchRequests, prefixIcon: const Icon(Icons.search), isDense: true),
                ),
              ),
              TabBar(tabs: [Tab(text: l.tabActive), Tab(text: l.tabHistory)]),
            ]),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new-request',
          onPressed: () => context.push(AppRoutes.newRequest),
          icon: const Icon(Icons.add),
          label: Text(l.actionNewRequest),
        ),
        body: TabBarView(children: [
          RequisitionListView(query: (scope: scope, statuses: activeStatuses, search: _search), showRequester: scope != RequisitionScope.mine),
          RequisitionListView(query: (scope: scope, statuses: historyStatuses, search: _search), showRequester: scope != RequisitionScope.mine),
        ]),
      ),
    );
  }
}

/// Reusable pull-to-refresh list of requisitions for a query (also used by approvals and store tabs).
class RequisitionListView extends ConsumerWidget {
  const RequisitionListView({super.key, required this.query, this.showRequester = false, this.emptyMessage, this.trailingBuilder});

  final RequisitionQuery query;
  final bool showRequester;
  final String? emptyMessage;
  final Widget Function(Requisition r)? trailingBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(requisitionListProvider(query));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(requisitionListProvider(query).future),
      child: AsyncValueView(
        value: list,
        onRetry: () => ref.invalidate(requisitionListProvider(query)),
        data: (items) => items.isEmpty
            ? ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.inbox_outlined, message: emptyMessage ?? l.noRequests)])
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => RequisitionCard(
                  requisition: items[i],
                  showRequester: showRequester,
                  trailing: trailingBuilder?.call(items[i]),
                  onTap: () => context.push(AppRoutes.request(items[i].id)),
                ),
              ),
      ),
    );
  }
}
