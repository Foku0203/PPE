import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_mobile_app/app/app.dart';
import 'package:ppe_mobile_app/core/storage/local_store.dart';
import 'package:ppe_mobile_app/core/storage/secure_storage_service.dart';
import 'package:ppe_mobile_app/shared/providers/core_providers.dart';

Widget buildApp({String locale = 'EN'}) {
  final store = MemoryLocalStore()..values[StoreKeys.locale] = locale;
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [
      localStoreProvider.overrideWithValue(store),
      tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
    ],
    child: const PPEApp(),
  );
}

void main() {
  testWidgets('signed-out user lands on the login screen', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('PPE SMART'), findsWidgets);
    expect(find.byKey(const Key('login_employee_id')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
  });

  testWidgets('login form validates required fields', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(2));
  });

  testWidgets('demo account chip fills the credentials', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SUP001'));
    await tester.tap(find.text('SUP001'));
    await tester.pump();

    final field = tester.widget<TextFormField>(find.byKey(const Key('login_employee_id')));
    expect(field.controller!.text, 'SUP001');
  });

  testWidgets('UI is localized to Thai, Myanmar and Chinese', (tester) async {
    await tester.pumpWidget(buildApp(locale: 'TH'));
    await tester.pumpAndSettle();
    expect(find.text('รหัสพนักงาน'), findsOneWidget);

    await tester.pumpWidget(buildApp(locale: 'MY'));
    await tester.pumpAndSettle();
    expect(find.text('ဝန်ထမ်း ID'), findsOneWidget);

    await tester.pumpWidget(buildApp(locale: 'ZH'));
    await tester.pumpAndSettle();
    expect(find.text('工号'), findsOneWidget);
    expect(find.text('登录'), findsWidgets);
  });
}
