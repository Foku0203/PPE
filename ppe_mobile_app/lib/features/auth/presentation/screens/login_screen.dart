import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  Object? _error;

  static const _demoAccounts = ['EMP001', 'SUP001', 'STORE001', 'EHS001', 'ADMIN001'];

  @override
  void dispose() {
    _employeeId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(_employeeId.text, _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final sessionExpired = ref.watch(authControllerProvider.select((s) => s.sessionExpired));
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Navy hero with the logo; the form card overlaps its rounded bottom edge.
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.inkLight]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 64),
                  child: Column(
                    children: [
                      IconTheme(
                        data: const IconThemeData(color: Colors.white),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const LanguageMenuButton(),
                            IconButton(tooltip: l.serverSettings, icon: const Icon(Icons.dns_outlined), onPressed: () => showServerSettings(context, ref)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Image.asset('assets/images/logo_mark.png', height: 72, semanticLabel: 'PPE SMART'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.appTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), child: _form(context, l, theme, sessionExpired)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AppLocalizations l, ThemeData theme, bool sessionExpired) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.signIn, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            if (sessionExpired && _error == null) ...[
              InfoBanner(message: l.errorSessionExpired, color: AppColors.warning, icon: Icons.lock_clock),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              InfoBanner(message: l.errorMessage(_error!), color: AppColors.danger, icon: Icons.error_outline),
              const SizedBox(height: 16),
            ],
            TextFormField(
              key: const Key('login_employee_id'),
              controller: _employeeId,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(labelText: l.employeeId, prefixIcon: const Icon(Icons.badge_outlined)),
              validator: (v) => v == null || v.trim().isEmpty ? l.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('login_password'),
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? l.fieldRequired : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login_submit'),
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : Text(l.signIn),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.go(AppRoutes.register), child: Text(l.noAccount)),
            if (kDebugMode || AppConfig.environment != 'production') ...[
              const SizedBox(height: 24),
              Text(l.demoAccounts, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in _demoAccounts)
                    ActionChip(
                      label: Text(id),
                      onPressed: () => setState(() {
                        _employeeId.text = id;
                        _password.text = 'ChangeMe123!';
                      }),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Globe button to switch TH / EN / MY from anywhere.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider.select((s) => s.language));
    return PopupMenuButton<AppLanguage>(
      tooltip: context.l10n.language,
      icon: const Icon(Icons.translate),
      initialValue: current,
      onSelected: (lang) => ref.read(settingsProvider.notifier).setLanguage(lang),
      itemBuilder: (_) => [for (final lang in AppLanguage.values) PopupMenuItem(value: lang, child: Text(lang.nativeName))],
    );
  }
}

Future<void> showServerSettings(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final controller = TextEditingController(text: ref.read(settingsProvider).serverUrl);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.serverSettings),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(labelText: l.serverUrl, hintText: l.serverUrlHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, ''), child: Text(l.resetDefault)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l.save)),
      ],
    ),
  );
  if (result != null) await ref.read(settingsProvider.notifier).setServerUrl(result);
}
