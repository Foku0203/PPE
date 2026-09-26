import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../requisitions/data/requisition_providers.dart';

/// PPE currently held by the user, with lifespan-based replacement dates.
class MyPpeScreen extends ConsumerWidget {
  const MyPpeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final issued = ref.watch(issuedItemsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myPpeTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(issuedItemsProvider.future),
        child: AsyncValueView(
          value: issued,
          onRetry: () => ref.invalidate(issuedItemsProvider),
          data: (data) => data.items.isEmpty
              ? ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.backpack_outlined, message: l.noIssuedItems)])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final line = data.items[i];
                    return Card(
                      child: ListTile(
                        leading: PpeImage(code: line.code, imageUrl: line.imageUrl, iconKey: line.iconKey, size: 48),
                        title: Text(line.name),
                        subtitle: Text([
                          '${line.quantity} ${l.unit(line.unit)}${line.size.isNotEmpty ? ' · ${line.size}' : ''}',
                          l.issuedOn(Fmt.date(context, line.issuedAt)),
                          if (line.replaceAt != null) l.replaceFrom(Fmt.date(context, line.replaceAt)),
                        ].join('\n')),
                        isThreeLine: true,
                        trailing: line.replacementDue ? Pill(label: l.replacementDueNow, color: AppColors.warning, dense: true) : null,
                        onTap: line.requisitionId == null ? null : () => context.push(AppRoutes.request(line.requisitionId!)),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
