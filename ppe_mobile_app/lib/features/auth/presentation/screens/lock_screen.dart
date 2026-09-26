import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import 'auth_provider.dart';

/// Biometric gate shown on start / after the app was in background (README §8).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _auth = LocalAuthentication();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = context.l10n;
    try {
      final supported = !kIsWeb && await _auth.isDeviceSupported();
      if (!supported) {
        // Device cannot do biometrics: don't trap the user behind a lock.
        ref.read(authControllerProvider.notifier).unlock();
        return;
      }
      final ok = await _auth.authenticate(localizedReason: l.biometricReason, persistAcrossBackgrounding: true);
      if (ok) ref.read(authControllerProvider.notifier).unlock();
    } catch (e) {
      if (mounted) setState(() => _message = l.biometricUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.fingerprint, size: 88, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(l.unlockTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(user?.displayName ?? '', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l.unlockSubtitle, textAlign: TextAlign.center),
              if (_message != null) ...[const SizedBox(height: 12), Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: _busy ? null : _unlock, icon: const Icon(Icons.lock_open), label: Text(l.unlock)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  if (await confirmDialog(context, title: l.logoutConfirm, confirmLabel: l.logout)) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                },
                child: Text(l.logout),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
