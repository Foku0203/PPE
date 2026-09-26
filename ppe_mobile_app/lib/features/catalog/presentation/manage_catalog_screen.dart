import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/labels.dart';
import '../catalog_provider.dart';
import 'ppe_detail_screen.dart';

/// EHS/Admin master data: every item including inactive ones, with policy values at a glance.
class ManageCatalogScreen extends ConsumerWidget {
  const ManageCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(localeCodeProvider);
    final catalog = ref.watch(catalogAdminProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.actionManageCatalog)),
      body: AsyncValueView(
        value: catalog,
        onRetry: () => ref.invalidate(catalogAdminProvider),
        data: (result) => RefreshIndicator(
          onRefresh: () => ref.refresh(catalogAdminProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: result.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = result.items[i];
              return Card(
                child: ListTile(
                  leading: PpeImage(code: item.code, imageUrl: item.imageUrl, iconKey: item.iconKey, size: 48),
                  title: Text(item.nameFor(locale)),
                  subtitle: Text([
                    item.code,
                    if (item.quota != null) '${l.quotaLabel}: ${item.quota}',
                    if (item.lifespanDays != null) '${l.lifespanLabel}: ${item.lifespanDays}',
                    '${l.reorderPoint}: ${item.reorderPoint}',
                  ].join(' · ')),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (!item.active) Pill(label: l.inactive, color: AppColors.neutral, dense: true),
                    IconButton(icon: const Icon(Icons.edit_note), tooltip: l.editPolicy, onPressed: () => showPolicyEditor(context, ref, item)),
                  ]),
                  onTap: () => context.push(AppRoutes.ppeItem(item.id)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
