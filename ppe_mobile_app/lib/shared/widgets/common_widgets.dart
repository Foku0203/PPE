import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../models/requisition_model.dart';
import 'labels.dart';

/// Loading / error-with-retry / data states for any [AsyncValue] (README: loading, empty, retry, error).
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.onRetry, this.loading});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => loading ?? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(l.errorMessage(error), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l.retry)),
          ],
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: color)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final RequisitionStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => Pill(label: context.l10n.status(status), color: AppColors.status(status), dense: dense);
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon, this.dense = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: color), const SizedBox(width: 4)],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: dense ? 11 : 12)),
        ),
      ]),
    );
  }
}

/// PPE picture: server image URL → bundled asset by code → icon placeholder.
class PpeImage extends StatelessWidget {
  const PpeImage({super.key, required this.code, this.imageUrl = '', this.iconKey = 'shield', this.size = 56, this.radius = 12});

  final String code;
  final String imageUrl;
  final String iconKey;
  final double size;
  final double radius;

  static IconData iconFor(String key) => switch (key) {
        'helmet' => Icons.construction,
        'goggles' => Icons.visibility,
        'earplug' || 'earmuff' => Icons.hearing,
        'mask' || 'respirator' => Icons.masks,
        'gloves' => Icons.back_hand,
        'boots' => Icons.hiking,
        'vest' => Icons.checkroom,
        'harness' || 'lanyard' => Icons.safety_divider,
        _ => Icons.health_and_safety,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.primaryContainer.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Icon(iconFor(iconKey), color: scheme.primary, size: size * 0.5),
    );
    final asset = Image.asset('assets/images/ppe/$code.jpg', fit: BoxFit.contain, errorBuilder: (_, _, _) => placeholder);
    final image = imageUrl.isNotEmpty
        ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain, placeholder: (_, _) => asset, errorWidget: (_, _, _) => asset)
        : asset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(width: size, height: size, color: Colors.white, child: image),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.label, required this.value, required this.icon, required this.color, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ]),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, required this.color, this.icon = Icons.info_outline, this.action, this.onAction});

  final String message;
  final Color color;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: color))),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ]),
    );
  }
}

class LabelValue extends StatelessWidget {
  const LabelValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback helpers
// ---------------------------------------------------------------------------

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.success));
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(error)), backgroundColor: AppColors.danger));
}

Future<bool> confirmDialog(BuildContext context, {required String title, String? message, String? confirmLabel, bool destructive = false}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a text; returns null when cancelled.
Future<String?> textInputDialog(
  BuildContext context, {
  required String title,
  String? label,
  bool required = false,
  int maxLines = 3,
  String? confirmLabel,
  String initialValue = '',
}) {
  final l = context.l10n;
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: (v) => required && (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
          },
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
}

/// Runs [action] with a blocking progress indicator and error snackbar. Returns null on failure.
Future<T?> runWithProgress<T>(BuildContext context, Future<T> Function() action) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  );
  try {
    final result = await action();
    navigator.pop();
    return result;
  } catch (e) {
    navigator.pop();
    if (context.mounted) showError(context, e);
    return null;
  }
}
