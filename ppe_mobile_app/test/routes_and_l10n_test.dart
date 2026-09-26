import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_mobile_app/app/routes/app_routes.dart';
import 'package:ppe_mobile_app/shared/models/user_model.dart';

void main() {
  group('role-based route guard', () {
    test('workers cannot open approval, store, inventory or admin screens', () {
      for (final path in [AppRoutes.approvals, AppRoutes.store, AppRoutes.inventory, AppRoutes.scan, AppRoutes.users, AppRoutes.audit, AppRoutes.analytics]) {
        expect(AppRoutes.canAccess(path, UserRole.worker), isFalse, reason: path);
      }
      expect(AppRoutes.canAccess(AppRoutes.catalog, UserRole.worker), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.request(3), UserRole.worker), isTrue);
    });

    test('each role reaches its own workspace', () {
      expect(AppRoutes.canAccess(AppRoutes.approvals, UserRole.supervisor), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.store, UserRole.supervisor), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.store, UserRole.storeKeeper), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.approvals, UserRole.storeKeeper), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.manageCatalog, UserRole.ehs), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.users, UserRole.ehs), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.users, UserRole.admin), isTrue);
    });

    test('every tab of a role is accessible to that role', () {
      for (final role in UserRole.values) {
        for (final tab in AppRoutes.tabsFor(role)) {
          expect(AppRoutes.canAccess(tab, role), isTrue, reason: '$role → $tab');
        }
      }
    });
  });

  test('TH / EN / MY / ZH translations have identical keys and placeholders', () {
    Map<String, dynamic> load(String locale) => jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
    Set<String> keys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();
    Set<String> placeholders(String text) => RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

    final en = load('en');
    for (final locale in ['th', 'my', 'zh']) {
      final other = load(locale);
      expect(keys(other), keys(en), reason: 'keys differ for $locale');
      for (final key in keys(en)) {
        expect(placeholders(other[key] as String), placeholders(en[key] as String), reason: '$locale.$key');
        expect((other[key] as String).trim(), isNotEmpty, reason: '$locale.$key is empty');
      }
    }
  });
}
