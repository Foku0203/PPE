import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/local_store.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HiveLocalStore.open();
  runApp(ProviderScope(
    // Surface errors to the UI (retry buttons) instead of Riverpod's silent automatic retry.
    retry: (retryCount, error) => null,
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: const PPEApp(),
  ));
}
