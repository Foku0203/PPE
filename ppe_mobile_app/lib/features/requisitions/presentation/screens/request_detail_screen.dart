import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/inventory_models.dart';
import '../../../../shared/models/requisition_model.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../inventory/presentation/screens/qr_scanner_screen.dart';
import '../../data/requisition_providers.dart';
import '../../data/requisition_repository.dart';

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requisitionId, this.qrToken});

  final int requisitionId;

  /// Set when the store opened this request by scanning the worker's pickup QR.
  final String? qrToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final detail = ref.watch(requisitionDetailProvider(requisitionId));
    return Scaffold(
      appBar: AppBar(title: Text(detail.value?.requestNo ?? l.requestDetail)),
      body: AsyncValueView(
        value: detail,
        onRetry: () => ref.invalidate(requisitionDetailProvider(requisitionId)),
        data: (r) => RefreshIndicator(
          onRefresh: () => ref.refresh(requisitionDetailProvider(requisitionId).future),
          child: _DetailBody(requisition: r, qrToken: qrToken),
        ),
      ),
      bottomNavigationBar: detail.hasValue ? _ActionBar(requisition: detail.value!, qrToken: qrToken) : null,
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.requisition, this.qrToken});

  final Requisition requisition;
  final String? qrToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = requisition;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      if (qrToken != null && r.status == RequisitionStatus.ready) ...[
        InfoBanner(message: l.verifiedByQr, color: AppColors.success, icon: Icons.verified_user),
        const SizedBox(height: 12),
      ],
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.requestNo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
              StatusChip(r.status),
            ]),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [
              if (r.specialApprovalNeeded) Pill(label: l.statusSpecial, color: AppColors.special, icon: Icons.priority_high, dense: true),
              if (r.isOverdue) Pill(label: l.overdue, color: AppColors.danger, icon: Icons.timer_off_outlined, dense: true),
            ]),
            const SizedBox(height: 12),
            _ProgressSteps(status: r.status),
            const Divider(height: 24),
            LabelValue(l.requester, '${r.requesterName} (${r.requesterEmployeeId})'),
            if (r.requesterDepartment.isNotEmpty) LabelValue(l.department, r.requesterDepartment),
            LabelValue(l.createdAt, Fmt.dateTime(context, r.createdAt)),
            if (r.specialReason.isNotEmpty) LabelValue(l.specialReason, r.specialReason),
          ]),
        ),
      ),
      SectionHeader(l.items),
      for (final line in r.items) ...[_LineTile(line: line, requisition: r), const SizedBox(height: 8)],
      if (r.approvals.isNotEmpty) ...[
        SectionHeader(l.approvals),
        Card(
          child: Column(children: [
            for (final a in r.approvals)
              ListTile(
                leading: Icon(a.approved ? Icons.check_circle : Icons.cancel, color: a.approved ? AppColors.success : AppColors.danger),
                title: Text('${l.approvalKind(a.kind)} · ${a.approved ? l.decisionApproved : l.decisionRejected}'),
                subtitle: Text([a.approverName, Fmt.dateTime(context, a.createdAt), if (a.reason.isNotEmpty) a.reason].join('\n')),
                isThreeLine: a.reason.isNotEmpty,
              ),
          ]),
        ),
      ],
      SectionHeader(l.comments),
      _CommentsCard(requisition: r),
      if (r.stockEvents.isNotEmpty) ...[
        SectionHeader(l.stockHistory),
        Card(
          child: Column(children: [
            for (final e in r.stockEvents)
              ListTile(
                dense: true,
                leading: const Icon(Icons.swap_vert),
                title: Text('${l.stockEvent(e.eventType)} · ${e.ppeCode} ×${e.quantity}'),
                subtitle: Text([
                  if (e.lotNumber.isNotEmpty) '${l.lot} ${e.lotNumber}',
                  if ((e.serialNumber ?? '').isNotEmpty) '${l.serial} ${e.serialNumber}',
                  if (e.issuerName != null) e.issuerName!,
                  Fmt.dateTime(context, e.createdAt),
                ].join(' · ')),
              ),
          ]),
        ),
      ],
    ]);
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.status});

  final RequisitionStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (status == RequisitionStatus.rejected || status == RequisitionStatus.cancelled) {
      return InfoBanner(message: l.status(status), color: AppColors.status(status), icon: Icons.block);
    }
    final labels = [l.progressSubmitted, l.progressApproved, l.progressReady, l.progressReceived];
    final current = status.flowIndex;
    final done = status == RequisitionStatus.completed;
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        Expanded(
          child: Column(children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: i < current || done ? AppColors.success : (i == current ? AppColors.status(status) : Theme.of(context).colorScheme.surfaceContainerHighest),
              child: Icon(i < current || done ? Icons.check : Icons.circle, size: i < current || done ? 16 : 8, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(labels[i], textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
          ]),
        ),
        if (i < labels.length - 1)
          Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: i < current || done ? AppColors.success : Theme.of(context).dividerColor)),
      ],
    ]);
  }
}

class _LineTile extends ConsumerWidget {
  const _LineTile({required this.line, required this.requisition});

  final RequisitionLine line;
  final Requisition requisition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final canReturn = requisition.actions.canReturn && line.isReturnable && !line.isReturned;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PpeImage(code: line.code, imageUrl: line.imageUrl, iconKey: line.iconKey, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                [line.code, if (line.size.isNotEmpty) '${l.size} ${line.size}', '${l.quantity} ${line.quantity} ${l.unit(line.unit)}'].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text('${l.reason}: ${l.reasonLabel(line.reason)}', style: Theme.of(context).textTheme.bodySmall),
              if (line.eligibleAt != null)
                Text(l.eligibleAt(Fmt.date(context, line.eligibleAt)), style: const TextStyle(color: AppColors.special, fontSize: 12)),
              if (line.returnDueDate != null && !line.isReturned)
                Text(l.returnDue(Fmt.date(context, line.returnDueDate)), style: const TextStyle(color: AppColors.info, fontSize: 12)),
              if (line.isReturned) ...[const SizedBox(height: 4), Pill(label: l.returned, color: AppColors.neutral, icon: Icons.assignment_return, dense: true)],
              if (canReturn) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () => _receiveReturn(context, ref), icon: const Icon(Icons.assignment_return_outlined), label: Text(l.returnItem)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _receiveReturn(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final note = TextEditingController();
    final condition = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l.returnItem} · ${line.code}'),
        content: TextField(controller: note, decoration: InputDecoration(labelText: '${l.note} (${l.optional})')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          OutlinedButton(onPressed: () => Navigator.pop(context, 'DAMAGED'), child: Text(l.conditionDamaged)),
          FilledButton(onPressed: () => Navigator.pop(context, 'GOOD'), child: Text(l.conditionGood)),
        ],
      ),
    );
    if (condition == null || !context.mounted) return;
    final result = await runWithProgress(context, () => ref.read(requisitionRepositoryProvider).returnLine(line.id, condition: condition, note: note.text));
    if (result != null && context.mounted) {
      ref.read(dataRevisionProvider.notifier).bump();
      showSuccess(context, l.actionSuccess);
    }
  }
}

class _CommentsCard extends ConsumerStatefulWidget {
  const _CommentsCard({required this.requisition});

  final Requisition requisition;

  @override
  ConsumerState<_CommentsCard> createState() => _CommentsCardState();
}

class _CommentsCardState extends ConsumerState<_CommentsCard> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(requisitionRepositoryProvider).comment(widget.requisition.id, text);
      _controller.clear();
      ref.read(dataRevisionProvider.notifier).bump();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final comments = widget.requisition.comments;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (comments.isEmpty) Text('—', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          for (final c in comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  if (c.isInfoRequest) Pill(label: l.infoRequestTag, color: AppColors.warning, dense: true),
                  const Spacer(),
                  Text(Fmt.relative(context, c.createdAt), style: Theme.of(context).textTheme.bodySmall),
                ]),
                const SizedBox(height: 2),
                Text(c.message),
              ]),
            ),
          if (widget.requisition.actions.canComment)
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: l.addComment, isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: l.send,
                onPressed: _sending ? null : _send,
                icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
              ),
            ]),
        ]),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.requisition, this.qrToken});

  final Requisition requisition;
  final String? qrToken;

  RequisitionRepository _repo(WidgetRef ref) => ref.read(requisitionRepositoryProvider);

  Future<void> _run(BuildContext context, WidgetRef ref, Future<Requisition> Function() action, String Function(Requisition) message) async {
    final result = await runWithProgress(context, action);
    if (result != null && context.mounted) {
      ref.read(dataRevisionProvider.notifier).bump();
      showSuccess(context, message(result));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = requisition.actions;
    final id = requisition.id;
    final buttons = <Widget>[
      if (a.canApprove) ...[
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () async {
            final reason = await textInputDialog(context, title: l.reject, label: l.rejectReason, required: true, confirmLabel: l.reject);
            if (reason != null && context.mounted) await _run(context, ref, () => _repo(ref).decide(id, 'REJECTED', reason: reason), (_) => l.rejectedMsg);
          },
          child: Text(l.reject),
        ),
        OutlinedButton(
          onPressed: () async {
            final question = await textInputDialog(context, title: l.requestInfo, label: l.infoQuestion, required: true, confirmLabel: l.send);
            if (question != null && context.mounted) {
              await _run(context, ref, () => _repo(ref).decide(id, 'REQUEST_INFO', reason: question), (_) => l.infoRequestedMsg);
            }
          },
          child: Text(l.requestInfo),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: () async {
            final note = await textInputDialog(context, title: l.approve, label: l.approveNote, confirmLabel: l.approve);
            if (note != null && context.mounted) await _run(context, ref, () => _repo(ref).decide(id, 'APPROVED', reason: note), (_) => l.approvedMsg);
          },
          child: Text(l.approve),
        ),
      ],
      if (a.canPrepare)
        FilledButton.icon(
          onPressed: () => _run(context, ref, () => _repo(ref).prepare(id), (r) => r.status == RequisitionStatus.onHold ? l.onHoldMsg : l.preparedMsg),
          icon: const Icon(Icons.inventory),
          label: Text(l.prepare),
        ),
      if (a.canIssue)
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: () => _issue(context, ref),
          icon: Icon(qrToken != null ? Icons.verified_user : Icons.handshake),
          label: Text(l.issue),
        ),
      if (a.canShowPickupQr)
        FilledButton.icon(onPressed: () => showPickupQr(context, ref, id), icon: const Icon(Icons.qr_code_2), label: Text(l.showPickupQr)),
      if (a.canCancel)
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () async {
            if (await confirmDialog(context, title: l.cancelRequest, message: l.cancelConfirm, destructive: true, confirmLabel: l.cancelRequest) &&
                context.mounted) {
              await _run(context, ref, () => _repo(ref).cancel(id), (r) => l.status(r.status));
            }
          },
          child: Text(l.cancelRequest),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: buttons),
      ),
    );
  }

  Future<void> _issue(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final needsSerial = requisition.items.any((i) => i.requiresSerial);
    var serials = <String>[];
    if (needsSerial) {
      final expected = requisition.stockEvents
          .where((e) => e.eventType == 'RESERVE' && (e.serialNumber ?? '').isNotEmpty)
          .map((e) => e.serialNumber!)
          .toList();
      final entered = await showDialog<List<String>>(context: context, builder: (_) => _SerialDialog(expected: expected));
      if (entered == null) return;
      serials = entered;
    } else if (qrToken == null) {
      if (!await confirmDialog(context, title: l.issue, message: l.issueWithoutQr, confirmLabel: l.issue)) return;
    }
    if (!context.mounted) return;
    await _run(context, ref, () => _repo(ref).issue(requisition.id, serialNumbers: serials, qrToken: qrToken), (_) => l.issueConfirmed);
  }
}

class _SerialDialog extends StatefulWidget {
  const _SerialDialog({required this.expected});

  final List<String> expected;

  @override
  State<_SerialDialog> createState() => _SerialDialogState();
}

class _SerialDialogState extends State<_SerialDialog> {
  final _controller = TextEditingController();

  List<String> get _values => _controller.text.split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.serialNumbers),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.expected.isNotEmpty) Text(l.expectedSerials(widget.expected.join(', ')), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        TextField(controller: _controller, minLines: 2, maxLines: 5, decoration: InputDecoration(hintText: l.serialHint)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen(returnRawValue: true)));
            if (code != null) setState(() => _controller.text = [..._values, code].join('\n'));
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l.actionScanQr),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _values.isEmpty ? null : () => Navigator.pop(context, _values), child: Text(l.issue)),
      ],
    );
  }
}

/// Worker's one-time pickup QR. Refreshes the request while open and closes when the store has issued it.
Future<void> showPickupQr(BuildContext context, WidgetRef ref, int requisitionId) {
  return showDialog<void>(context: context, builder: (_) => _PickupQrDialog(requisitionId: requisitionId));
}

class _PickupQrDialog extends ConsumerStatefulWidget {
  const _PickupQrDialog({required this.requisitionId});

  final int requisitionId;

  @override
  ConsumerState<_PickupQrDialog> createState() => _PickupQrDialogState();
}

class _PickupQrDialogState extends ConsumerState<_PickupQrDialog> {
  PickupQr? _qr;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _qr = null;
      _error = null;
    });
    try {
      final qr = await ref.read(requisitionRepositoryProvider).pickupQr(widget.requisitionId);
      if (mounted) setState(() => _qr = qr);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _tick() async {
    if (!mounted) return;
    setState(() {}); // update expiry state
    try {
      final r = await ref.read(requisitionRepositoryProvider).detail(widget.requisitionId);
      if (r.status == RequisitionStatus.completed && mounted) {
        ref.read(dataRevisionProvider.notifier).bump();
        Navigator.pop(context);
        showSuccess(context, context.l10n.issueConfirmed);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final qr = _qr;
    final expired = qr != null && qr.expiresAt.isBefore(DateTime.now());
    return AlertDialog(
      title: Text(l.pickupQrTitle),
      content: SizedBox(
        width: 280,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_error != null)
            Text(l.errorMessage(_error!))
          else if (qr == null)
            const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())
          else ...[
            Opacity(
              opacity: expired ? 0.2 : 1,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(data: qr.token, size: 240, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(qr.requestNo, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(expired ? l.qrExpired : l.expiresAt(Fmt.time(context, qr.expiresAt)),
                style: TextStyle(color: expired ? AppColors.danger : Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 8),
            Text(l.pickupQrHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: _load, child: Text(l.regenerate)),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
      ],
    );
  }
}
