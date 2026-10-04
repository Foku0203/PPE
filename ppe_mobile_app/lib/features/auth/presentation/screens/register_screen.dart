import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../data/auth_repository.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeId = TextEditingController();
  final _name = TextEditingController();
  final _department = TextEditingController();
  final _phone = TextEditingController();
  final _supervisor = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _supervisorId;
  bool _supervisorMissing = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _loading = false;
  Object? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [_employeeId, _name, _department, _phone, _supervisor, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final pickSupervisor = ref.read(supervisorOptionsProvider).value?.isNotEmpty ?? false;
    setState(() {
      _supervisorMissing = pickSupervisor && _supervisorId == null;
      // After the first attempt, re-check each field as it changes so fixed errors disappear.
      _autovalidate = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate() || _supervisorMissing) return;
    setState(() {
      _loading = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      await ref.read(authControllerProvider.notifier).register(RegisterInput(
            employeeId: _employeeId.text,
            displayName: _name.text,
            password: _password.text,
            department: _department.text,
            phoneNumber: _phone.text,
            supervisorEmployeeId: _supervisorId ?? _supervisor.text,
            locale: ref.read(settingsProvider).language.apiCode,
          ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          if (e is ValidationException) _fieldErrors = e.fieldErrors;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pick-or-search list of supervisors; falls back to typing the ID if the list cannot be loaded.
  List<Widget> _supervisorField(AppLocalizations l, InputDecoration Function(String, IconData, String, {bool optional}) deco) {
    final options = ref.watch(supervisorOptionsProvider);
    if (options.isLoading) return const [LinearProgressIndicator(), SizedBox(height: 12)];
    final supervisors = options.value;
    if (supervisors == null) {
      return [
        TextFormField(
          controller: _supervisor,
          textCapitalization: TextCapitalization.characters,
          decoration: deco(l.supervisorEmployeeId, Icons.supervisor_account_outlined, 'supervisor_employee_id'),
          validator: (v) => v == null || v.trim().isEmpty ? l.fieldRequired : null,
        ),
        const SizedBox(height: 12),
      ];
    }
    if (supervisors.isEmpty) return const [];
    return [
      DropdownMenu<String>(
        controller: _supervisor,
        expandedInsets: EdgeInsets.zero,
        enableFilter: true,
        requestFocusOnTap: true,
        menuHeight: 320,
        label: Text(l.selectSupervisor),
        hintText: l.searchSupervisor,
        leadingIcon: const Icon(Icons.supervisor_account_outlined),
        errorText: _supervisorMissing ? l.fieldRequired : _fieldErrors['supervisor_employee_id'],
        dropdownMenuEntries: [for (final s in supervisors) DropdownMenuEntry(value: s.employeeId, label: s.label)],
        onSelected: (id) => setState(() {
          _supervisorId = id;
          if (id != null) _supervisorMissing = false;
        }),
      ),
      const SizedBox(height: 12),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    InputDecoration deco(String label, IconData icon, String field, {bool optional = false}) => InputDecoration(
          labelText: optional ? '$label (${l.optional})' : label,
          prefixIcon: Icon(icon),
          errorText: _fieldErrors[field],
        );
    String? required(String? v) => v == null || v.trim().isEmpty ? l.fieldRequired : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.registerTitle),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
        actions: const [LanguageMenuButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  InfoBanner(message: l.registerNote, color: AppColors.info),
                  const SizedBox(height: 16),
                  if (_error != null && _fieldErrors.isEmpty) ...[
                    InfoBanner(message: l.errorMessage(_error!), color: AppColors.danger, icon: Icons.error_outline),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _employeeId,
                    textCapitalization: TextCapitalization.characters,
                    decoration: deco(l.employeeId, Icons.badge_outlined, 'employee_id'),
                    validator: required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _name, decoration: deco(l.displayName, Icons.person_outline, 'display_name'), validator: required),
                  const SizedBox(height: 12),
                  TextFormField(controller: _department, decoration: deco(l.department, Icons.apartment_outlined, 'department', optional: true)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: deco(l.phoneNumber, Icons.phone_outlined, 'phone_number', optional: true),
                  ),
                  const SizedBox(height: 12),
                  ..._supervisorField(l, deco),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: deco(l.password, Icons.lock_outline, 'password'),
                    validator: (v) => (v ?? '').length < 8 ? l.passwordTooShort : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: deco(l.confirmPassword, Icons.lock_outline, 'confirm'),
                    validator: (v) => v != _password.text ? l.passwordMismatch : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Text(l.createAccount),
                  ),
                  TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(l.haveAccount)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
