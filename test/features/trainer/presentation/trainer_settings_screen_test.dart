import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/settings/presentation/screens/settings_screen.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/data/noop_cloud_sync_service.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/coach_bridge.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/features/trainer/presentation/screens/trainer_settings_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/silent_speech_service.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _NeverEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SilentSpeechService speechService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    speechService = SilentSpeechService();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        speechServiceProvider.overrideWithValue(speechService),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: TrainerSettingsScreen(),
      ),
    );
  }

  SwitchListTile findEnableSwitch(WidgetTester tester) {
    return tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Enable coach'),
    );
  }

  testWidgets('renders with the master switch off by default', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(findEnableSwitch(tester).value, isFalse);
  });

  testWidgets(
      'enabling without an accepted disclaimer shows the notice and leaves '
      'the trainer disabled', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Enable coach'));
    await tester.pumpAndSettle();

    expect(find.text('Before your coach speaks'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(findEnableSwitch(tester).value, isFalse);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrainerSettingsScreen)),
    );
    expect(container.read(trainerSettingsProvider).disclaimerAccepted, isFalse);
  });

  testWidgets('accepting the disclaimer then enabling sets both flags true',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Enable coach'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrainerSettingsScreen)),
    );
    final settings = container.read(trainerSettingsProvider);
    expect(settings.disclaimerAccepted, isTrue);
    expect(settings.enabled, isTrue);
    expect(findEnableSwitch(tester).value, isTrue);
  });

  testWidgets('Test voice speaks exactly one phrase', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test voice'));
    await tester.pumpAndSettle();

    expect(speechService.spoken, hasLength(1));
  });

  testWidgets(
      'reviewing the disclaimer and declining it revokes consent and '
      'disables the trainer', (tester) async {
    // Gives revokeDisclaimer() a real UI path to be reached from: previously
    // "Review safety notice" discarded the sheet's result entirely.
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Accept once via the master switch, as in the earlier test.
    await tester.tap(find.widgetWithText(SwitchListTile, 'Enable coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(findEnableSwitch(tester).value, isTrue);

    // Now review the notice again and decline it.
    await tester.tap(find.text('Review safety notice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrainerSettingsScreen)),
    );
    final settings = container.read(trainerSettingsProvider);
    expect(settings.disclaimerAccepted, isFalse);
    expect(settings.enabled, isFalse);
    expect(findEnableSwitch(tester).value, isFalse);
  });

  group('SettingsScreen entitlement gate', () {
    const packageInfoChannel =
        MethodChannel('dev.fluttercommunity.plus/package_info');
    final databases = <db.AppDatabase>[];

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized()
          .defaultBinaryMessenger
          .setMockMethodCallHandler(packageInfoChannel, (call) async {
        if (call.method != 'getAll') return null;
        return <String, dynamic>{
          'appName': 'RepFoundry',
          'packageName': 'com.repfoundry.app',
          'version': '0.1.0-SNAPSHOT',
          'buildNumber': '23',
          'buildSignature': '',
          'installerStore': null,
        };
      });
    });

    tearDown(() async {
      TestWidgetsFlutterBinding.ensureInitialized()
          .defaultBinaryMessenger
          .setMockMethodCallHandler(packageInfoChannel, null);
      for (final database in databases) {
        await database.close();
      }
      databases.clear();
    });

    Widget buildSettingsScreen(EntitlementService entitlementService) {
      final database = db.AppDatabase.forTesting(NativeDatabase.memory());
      databases.add(database);
      final orchestrator = SyncOrchestrator(
        database: database,
        cloudService: const NoopCloudSyncService(),
        deviceId: 'test-device',
      );
      return ProviderScope(
        overrides: [
          entitlementServiceProvider.overrideWithValue(entitlementService),
          syncOrchestratorProvider.overrideWithValue(orchestrator),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: SettingsScreen(),
        ),
      );
    }

    testWidgets('shows no trainer tile when unentitled', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(_NeverEntitled()));
      await tester.pumpAndSettle();

      // The trainer section sits below several others in a lazily-built
      // ListView, so an assertion without scrolling would pass whether or
      // not the gate actually works (the tile simply wouldn't be mounted
      // yet either way). A single scroll straight to a distant target (e.g.
      // the footer) is *also* not a reliable check: the sliver drops
      // far-off-screen children once scrolled past their cache extent, so a
      // broken gate's tile could be built, then unmounted again by the time
      // the scroll settles further down — indistinguishable from never
      // having been built at all. Instead, check at every small step of the
      // scroll, so the tile is caught the moment it would enter the
      // viewport/cache if the gate were broken.
      final scrollable = find.byType(Scrollable).first;
      var sawTile = false;
      for (var i = 0; i < 25 && !sawTile; i++) {
        sawTile = find.text('Virtual Trainer').evaluate().isNotEmpty ||
            find.text('COACH').evaluate().isNotEmpty;
        await tester.drag(scrollable, const Offset(0, -150));
        await tester.pump();
      }
      sawTile = sawTile ||
          find.text('Virtual Trainer').evaluate().isNotEmpty ||
          find.text('COACH').evaluate().isNotEmpty;

      expect(sawTile, isFalse,
          reason: 'the trainer tile must never be reachable, at any scroll '
              'position, while the entitlement is not held');
    });

    testWidgets('shows the trainer tile when entitled', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(_AlwaysEntitled()));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Virtual Trainer'),
        300,
        scrollable: scrollable,
      );

      expect(find.text('Virtual Trainer'), findsOneWidget);
      expect(find.text('COACH'), findsOneWidget);
    });
  });
}
