import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/screens/auth_provider.dart';
import '../features/requisitions/data/offline_queue.dart';
import '../l10n/app_localizations.dart';
import '../shared/providers/core_providers.dart';
import '../shared/services/push_service.dart';
import 'config/app_config.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class PPEApp extends ConsumerStatefulWidget {
  const PPEApp({super.key});

  @override
  ConsumerState<PPEApp> createState() => _PPEAppState();
}

class _PPEAppState extends ConsumerState<PPEApp> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _pausedAt;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onPause: () => _pausedAt = DateTime.now(), onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _syncTimer?.cancel();
    super.dispose();
  }

  void _onResume() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null && DateTime.now().difference(pausedAt) > AppConfig.relockAfter) {
      ref.read(authControllerProvider.notifier).lock();
    }
    _syncOffline();
  }

  void _syncOffline() {
    final auth = ref.read(authControllerProvider);
    if (auth.isAuthenticated && ref.read(offlineQueueProvider).isNotEmpty) {
      ref.read(offlineQueueProvider.notifier).syncAll();
    }
  }

  void _onAuthChanged(AuthState? previous, AuthState next) {
    final signedIn = next.isAuthenticated && !next.locked;
    final wasSignedIn = previous?.isAuthenticated == true && previous?.locked == false;
    if (signedIn && !wasSignedIn) {
      ref.read(pushServiceProvider).start();
      _syncOffline();
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(AppConfig.offlineSyncInterval, (_) => _syncOffline());
    } else if (!next.isAuthenticated) {
      _syncTimer?.cancel();
      ref.read(pushServiceProvider).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, _onAuthChanged);
    final router = ref.watch(routerProvider);
    final language = ref.watch(settingsProvider.select((s) => s.language));
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
    );
  }
}
