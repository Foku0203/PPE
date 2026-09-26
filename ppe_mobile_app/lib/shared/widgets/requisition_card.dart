import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../models/requisition_model.dart';
import 'common_widgets.dart';
import 'labels.dart';

class RequisitionCard extends StatelessWidget {
  const RequisitionCard({super.key, required this.requisition, required this.onTap, this.showRequester = false, this.trailing});

  final Requisition requisition;
  final VoidCallback onTap;
  final bool showRequester;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = requisition;
    final first = r.items.isNotEmpty ? r.items.first : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (first != null) PpeImage(code: first.code, imageUrl: first.imageUrl, iconKey: first.iconKey, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(r.requestNo, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(Fmt.relative(context, r.createdAt), style: Theme.of(context).textTheme.bodySmall),
                ]),
                const SizedBox(height: 2),
                Text(
                  r.items.map((i) => '${i.name} ×${i.quantity}').join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (showRequester) ...[
                  const SizedBox(height: 2),
                  Text('${r.requesterName} · ${r.requesterEmployeeId}${r.requesterDepartment.isEmpty ? '' : ' · ${r.requesterDepartment}'}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  StatusChip(r.status, dense: true),
                  if (r.specialApprovalNeeded) Pill(label: l.statusSpecial, color: AppColors.special, icon: Icons.priority_high, dense: true),
                  if (r.isOverdue) Pill(label: l.overdue, color: AppColors.danger, icon: Icons.timer_off_outlined, dense: true),
                ]),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ]),
        ),
      ),
    );
  }
}
