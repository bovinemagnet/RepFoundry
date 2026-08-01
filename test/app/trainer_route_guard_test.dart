import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/app/router.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedEntitlements implements EntitlementService {
  _FixedEntitlements({required this.entitled});

  final bool entitled;

  @override
  bool has(Entitlement entitlement) => entitled;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Mounts the real router and navigates to [location], returning where it
  /// actually settled.
  Future<Uri> navigateTo(
    WidgetTester tester,
    String location, {
    required bool entitled,
  }) async {
    final container = ProviderContainer(overrides: [
      entitlementServiceProvider
          .overrideWithValue(_FixedEntitlements(entitled: entitled)),
    ]);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pump();

    router.go(location);
    await tester.pump();
    await tester.pump();

    return router.routerDelegate.currentConfiguration.uri;
  }

  testWidgets('/settings/trainer redirects to settings when unentitled',
      (tester) async {
    // The settings tile is gated, but the route must be too: a deep link or
    // a restored location would otherwise reach a paid screen for free.
    final settled =
        await navigateTo(tester, '/settings/trainer', entitled: false);

    expect(settled.path, '/settings');
  });

  testWidgets('/settings/trainer is reachable when the entitlement is held',
      (tester) async {
    final settled =
        await navigateTo(tester, '/settings/trainer', entitled: true);

    expect(settled.path, '/settings/trainer');
  });
}
