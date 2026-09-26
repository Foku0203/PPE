import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/labels.dart';
import '../data/admin_repository.dart';

/// Read-only audit trail for EHS/Admin (who did what, before/after).
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _search = '';
  String? _entity;

  static const _entities = ['Requisition', 'RequisitionItem', 'PpeItem', 'StockLot', 'PurchaseRequest', 'User'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final query = (search: _search, entity: _entity);
    final logs = ref.watch(auditLogsProvider(query));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.auditTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: TextField(
                onSubmitted: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(hintText: l.searchAudit, prefixIcon: const Icon(Icons.search), isDense: true),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(label: Text(l.all), selected: _entity == null, onSelected: (_) => setState(() => _entity = null)),
                ),
                for (final e in _entities)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(label: Text(e), selected: _entity == e, onSelected: (_) => setState(() => _entity = e)),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(auditLogsProvider(query).future),
        child: AsyncValueView(
          value: logs,
          onRetry: () => ref.invalidate(auditLogsProvider(query)),
          data: (entries) => entries.isEmpty
              ? ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.history, message: l.noAuditEntries)])
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final changes = [
                      if (e.before != null) 'before: ${e.before}',
                      if (e.after != null) 'after: ${e.after}',
                    ].join('\n');
                    return ExpansionTile(
                      leading: const Icon(Icons.history_edu_outlined),
                      title: Text('${e.action} · ${e.entity} #${e.entityId}'),
                      subtitle: Text('${e.actorName ?? '-'} (${e.actorEmployeeId ?? '-'}) · ${Fmt.dateTime(context, e.createdAt)}'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [SelectableText(changes.isEmpty ? '-' : changes, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
