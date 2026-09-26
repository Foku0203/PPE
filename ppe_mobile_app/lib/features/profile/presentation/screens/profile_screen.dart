import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/services/push_service.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/auth_provider.dart';
import '../../../requisitions/data/offline_queue.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final queue = ref.watch(offlineQueueProvider);
    if (user == null) return const SizedBox.shrink();
    final role = user.role;

    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 30, child: Text(user.initials, style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                  Text('${user.employeeId} · ${l.roleName(role)}'),
                  if (user.department.isNotEmpty) Text(user.department, style: Theme.of(context).textTheme.bodySmall),
                  if (user.supervisorName != null) Text('${l.supervisor}: ${user.supervisorName}', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              IconButton(tooltip: l.editProfile, icon: const Icon(Icons.edit_outlined), onPressed: () => _editProfile(context, ref)),
            ]),
          ),
        ),
        SectionHeader(l.tools),
        Card(
          child: Column(children: [
            _tile(Icons.backpack_outlined, l.myPpeTitle, () => context.push(AppRoutes.myPpe)),
            _tile(Icons.notifications_outlined, l.notificationsTitle, () => context.push(AppRoutes.notifications)),
            _tile(Icons.cloud_upload_outlined, l.syncQueue, () => context.push(AppRoutes.syncQueue),
                trailing: queue.isEmpty ? null : Badge(label: Text('${queue.length}'))),
            if (role.isStore) _tile(Icons.qr_code_scanner, l.actionScanQr, () => context.push(AppRoutes.scan)),
            if (role.isStore) _tile(Icons.shopping_bag_outlined, l.actionPurchaseRequests, () => context.push(AppRoutes.purchaseRequests)),
            if (role.canManageMasterData) _tile(Icons.tune, l.actionManageCatalog, () => context.push(AppRoutes.manageCatalog)),
            if (role != UserRole.worker) _tile(Icons.insights_outlined, l.actionAnalytics, () => context.push(AppRoutes.analytics)),
            if (role.canViewAudit) _tile(Icons.history_edu_outlined, l.actionAuditLog, () => context.push(AppRoutes.audit)),
            if (role.isAdmin) _tile(Icons.manage_accounts_outlined, l.actionUsers, () => context.push(AppRoutes.users)),
          ]),
        ),
        SectionHeader(l.settings),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l.language),
              trailing: DropdownButton<AppLanguage>(
                value: settings.language,
                underline: const SizedBox.shrink(),
                items: [for (final lang in AppLanguage.values) DropdownMenuItem(value: lang, child: Text(lang.nativeName))],
                onChanged: (lang) async {
                  if (lang == null) return;
                  await ref.read(settingsProvider.notifier).setLanguage(lang);
                  // Persist on the server too, so push texts / defaults follow the user across devices.
                  try {
                    await ref.read(authControllerProvider.notifier).updateProfile({'locale': lang.apiCode});
                  } catch (_) {}
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text(l.appearance),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem, maxLines: 1)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight, maxLines: 1)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark, maxLines: 1)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setThemeMode(s.first),
                ),
              ),
            ),
            if (!kIsWeb)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text(l.biometricLock),
                subtitle: Text(l.biometricLockSub),
                value: settings.biometricEnabled,
                onChanged: (enabled) async {
                  if (enabled) {
                    final auth = LocalAuthentication();
                    final supported = await auth.isDeviceSupported();
                    if (!context.mounted) return;
                    if (!supported) return showError(context, UnknownException(l.biometricUnavailable));
                    final ok = await auth.authenticate(localizedReason: l.biometricReason);
                    if (!ok) return;
                  }
                  await ref.read(settingsProvider.notifier).setBiometric(enabled);
                },
              ),
            _tile(Icons.password, l.changePassword, () => _changePassword(context, ref)),
          ]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            if (await confirmDialog(context, title: l.logoutConfirm, confirmLabel: l.logout, destructive: true)) {
              await ref.read(authControllerProvider.notifier).logout(deviceToken: ref.read(pushServiceProvider).token);
            }
          },
          icon: const Icon(Icons.logout),
          label: Text(l.logout),
        ),
        const SizedBox(height: 16),
        Center(child: Text('${l.version('1.0.0')} · ${AppConfig.environment} · ${settings.serverUrl}', style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) =>
      ListTile(leading: Icon(icon), title: Text(title), trailing: trailing ?? const Icon(Icons.chevron_right), onTap: onTap);

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final user = ref.read(currentUserProvider)!;
    final name = TextEditingController(text: user.displayName);
    final phone = TextEditingController(text: user.phoneNumber);
    final department = TextEditingController(text: user.department);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.editProfile),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: l.displayName)),
          const SizedBox(height: 8),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l.phoneNumber)),
          const SizedBox(height: 8),
          TextField(controller: department, decoration: InputDecoration(labelText: l.department)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.save)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await runWithProgress(
      context,
      () => ref.read(authControllerProvider.notifier).updateProfile({
        'display_name': name.text.trim(),
        'phone_number': phone.text.trim(),
        'department': department.text.trim(),
      }).then((_) => true),
    );
    if (result == true && context.mounted) showSuccess(context, l.profileSaved);
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.changePassword),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: current, obscureText: true, decoration: InputDecoration(labelText: l.currentPassword),
                validator: (v) => v == null || v.isEmpty ? l.fieldRequired : null),
            TextFormField(controller: next, obscureText: true, decoration: InputDecoration(labelText: l.newPassword),
                validator: (v) => (v ?? '').length < 8 ? l.passwordTooShort : null),
            TextFormField(controller: confirm, obscureText: true, decoration: InputDecoration(labelText: l.confirmPassword),
                validator: (v) => v != next.text ? l.passwordMismatch : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => formKey.currentState!.validate() ? Navigator.pop(context, true) : null, child: Text(l.save)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await runWithProgress(context, () => ref.read(authRepositoryProvider).changePassword(current.text, next.text).then((_) => true));
    if (result == true && context.mounted) showSuccess(context, l.passwordChanged);
  }
}
