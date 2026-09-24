import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/data/noop_cloud_sync_service.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_result.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/core/units/weight_unit_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_coloured_line_provider.dart';
import 'package:rep_foundry/features/settings/presentation/screens/settings_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:rep_foundry/features/settings/presentation/providers/plate_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSyncOrchestrator extends SyncOrchestrator {
  _RecordingSyncOrchestrator._(
    this._database, {
    required this.result,
  }) : super(
          database: _database,
          cloudService: const NoopCloudSyncService(),
          deviceId: 'test-device',
        );

  factory _RecordingSyncOrchestrator({
    required SyncResult result,
    bool supported = true,
  }) =>
      _RecordingSyncOrchestrator._(
        AppDatabase.forTesting(NativeDatabase.memory()),
        result: result,
      ).._supported = supported;

  final AppDatabase _database;
  final SyncResult result;
  bool _supported = true;

  @override
  bool get isSupported => _supported;
  int syncCalls = 0;
  final List<bool> interactiveValues = [];

  @override
  Future<SyncResult> sync({bool interactive = false}) async {
    syncCalls += 1;
    interactiveValues.add(interactive);
    return result;
  }

  Future<void> dispose() => _database.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const packageInfoChannel =
      MethodChannel('dev.fluttercommunity.plus/package_info');
  late _RecordingSyncOrchestrator orchestrator;

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(900, 2600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      packageInfoChannel,
      (call) async {
        if (call.method != 'getAll') return null;
        return <String, dynamic>{
          'appName': 'RepFoundry',
          'packageName': 'com.repfoundry.app',
          'version': '0.1.0-SNAPSHOT',
          'buildNumber': '23',
          'buildSignature': '',
          'installerStore': null,
        };
      },
    );
  });

  tearDown(() async {
    await orchestrator.dispose();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      packageInfoChannel,
      null,
    );
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget buildScreen(_RecordingSyncOrchestrator orchestrator) {
    return ProviderScope(
      overrides: [
        syncOrchestratorProvider.overrideWithValue(orchestrator),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: SettingsScreen(),
      ),
    );
  }

  Future<void> tapSyncToggle(WidgetTester tester) async {
    final label = find.text('Enable Cross-Device Sync');
    await tester.ensureVisible(label);
    await tester.pumpAndSettle();

    final labelCenter = tester.getCenter(label);
    await tester.tapAt(Offset(850, labelCenter.dy));
    await tester.pumpAndSettle();
  }

  testWidgets('sync toggle is disabled when the platform has no cloud backend',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    orchestrator = _RecordingSyncOrchestrator(
      result: SyncResult(
        success: true,
        entitiesMerged: 0,
        syncedAt: DateTime.utc(2026, 6, 8, 12),
      ),
      supported: false,
    );

    await tester.pumpWidget(buildScreen(orchestrator));
    await tester.pumpAndSettle();
    await tapSyncToggle(tester);

    expect(orchestrator.syncCalls, 0);
    expect(find.text('Cloud sync is not available on this platform'),
        findsOneWidget);
  });

  testWidgets('page header shows the installed package version',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    orchestrator = _RecordingSyncOrchestrator(
      result: SyncResult(
        success: true,
        entitiesMerged: 0,
        syncedAt: DateTime.utc(2026, 6, 8, 12),
      ),
    );

    await tester.pumpWidget(buildScreen(orchestrator));
    await tester.pumpAndSettle();

    expect(find.text('REPFOUNDRY V0.1.0-SNAPSHOT'), findsOneWidget);
    expect(find.text('REPFOUNDRY V1.0'), findsNothing);
  });

  testWidgets(
      'Theme and Layout selectors stack below their labels on a narrow phone',
      (tester) async {
    // Regression for issue #79: on a narrow Android phone (~360dp) the wide
    // segmented selectors squeezed the label column to ~one character, so
    // "Theme"/"Layout" wrapped one letter per line. On narrow widths the
    // selector must sit BELOW the label rather than beside it.
    SharedPreferences.setMockInitialValues({});
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(360, 800);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    orchestrator = _RecordingSyncOrchestrator(
      result: SyncResult(
        success: true,
        entitiesMerged: 0,
        syncedAt: DateTime.utc(2026, 6, 8, 12),
      ),
    );

    await tester.pumpWidget(buildScreen(orchestrator));
    await tester.pumpAndSettle();

    // No RenderFlex overflow anywhere on the screen.
    expect(tester.takeException(), isNull);

    // The list builds lazily, so scroll each row into view before measuring.
    final scrollable = find.byType(Scrollable).first;

    // Theme row: the "Dark" segment sits below the "Theme" label.
    await tester.scrollUntilVisible(find.text('Theme'), 300,
        scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Dark')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Theme')).dy),
      reason: 'Theme selector should stack below its label on a narrow phone',
    );

    // Layout row: the "Mobile" segment sits below the "Layout" label.
    await tester.scrollUntilVisible(find.text('Layout'), 300,
        scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Mobile')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Layout')).dy),
      reason: 'Layout selector should stack below its label on a narrow phone',
    );
  });

  group('SettingsScreen weight unit toggle', () {
    testWidgets('selecting lbs updates the shared provider and persists',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      orchestrator = _RecordingSyncOrchestrator(
        result: SyncResult(
          success: true,
          entitiesMerged: 0,
          syncedAt: DateTime.utc(2026, 6, 8, 12),
        ),
      );

      await tester.pumpWidget(buildScreen(orchestrator));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('lbs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('lbs'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(weightUnitProvider), WeightUnit.lbs);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('weight_unit'), 'lbs');
    });
  });

  group('SettingsScreen plate calculator (#66)', () {
    Future<ProviderContainer> pumpAt(
      WidgetTester tester,
      String label, {
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues({'weight_unit': 'kg', ...prefs});
      orchestrator = _RecordingSyncOrchestrator(
        result: SyncResult(
          success: true,
          entitiesMerged: 0,
          syncedAt: DateTime.utc(2026, 9, 24, 12),
        ),
      );
      await tester.pumpWidget(buildScreen(orchestrator));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(label), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
    }

    testWidgets('choosing a bar weight persists for the active unit',
        (tester) async {
      final container = await pumpAt(tester, 'Bar weight');

      // 15 kg is both a bar and a plate; the bar row comes first.
      await tester.tap(find.text('15kg').first);
      await tester.pumpAndSettle();

      final kg = container.read(plateSettingsProvider).forUnit(WeightUnit.kg);
      expect(kg.bar, 15);
      expect(kg.plates, contains(15.0));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('plate_bar_kg'), 15);
    });

    testWidgets('tapping a plate size leaves it out and persists',
        (tester) async {
      final container = await pumpAt(tester, 'Plates available');
      await tester.ensureVisible(find.widgetWithText(FilterChip, '25kg'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '25kg'))
            .selected,
        isTrue,
      );

      await tester.tap(find.widgetWithText(FilterChip, '25kg'));
      await tester.pumpAndSettle();

      expect(
        container.read(plateSettingsProvider).forUnit(WeightUnit.kg).plates,
        isNot(contains(25.0)),
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '25kg'))
            .selected,
        isFalse,
      );
    });

    testWidgets('shows the pound setup when pounds are selected',
        (tester) async {
      await pumpAt(tester, 'Plates available', prefs: {'weight_unit': 'lbs'});

      expect(find.text('35lbs'), findsNWidgets(2)); // a bar and a plate
      expect(find.widgetWithText(FilterChip, '45lbs'), findsOneWidget);
      expect(find.text('25kg'), findsNothing);
    });
  });

  group('SettingsScreen zone-coloured HR line (#131)', () {
    testWidgets('is on by default and its switch turns it off and persists',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      orchestrator = _RecordingSyncOrchestrator(
        result: SyncResult(
          success: true,
          entitiesMerged: 0,
          syncedAt: DateTime.utc(2026, 9, 24, 12),
        ),
      );

      await tester.pumpWidget(buildScreen(orchestrator));
      await tester.pumpAndSettle();

      final label = find.text('Zone-Coloured HR Line');
      await tester.scrollUntilVisible(label, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Colour the heart-rate line by training zone'),
        findsOneWidget,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(zoneColouredLineProvider), isTrue);

      await tester.tapAt(Offset(850, tester.getCenter(label).dy));
      await tester.pumpAndSettle();

      expect(container.read(zoneColouredLineProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hr_zone_coloured_line'), isFalse);
      // The neighbouring zone-bands switch was not the one tapped.
      expect(prefs.getBool('hr_show_zone_bands'), isNull);
    });
  });

  group('SettingsScreen cloud sync setup', () {
    testWidgets('enables sync only after interactive first sync succeeds',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final syncedAt = DateTime.utc(2026, 6, 8, 12);
      orchestrator = _RecordingSyncOrchestrator(
        result: SyncResult(
          success: true,
          entitiesMerged: 0,
          syncedAt: syncedAt,
        ),
      );

      await tester.pumpWidget(buildScreen(orchestrator));
      await tester.pumpAndSettle();

      await tapSyncToggle(tester);
      await tester.tap(find.textContaining('Continue'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(orchestrator.syncCalls, 1);
      expect(orchestrator.interactiveValues, equals([true]));
      expect(prefs.getBool('cloud_sync_consent_given'), isTrue);
      expect(prefs.getBool('cloud_sync_enabled'), isTrue);
      expect(
        prefs.getInt('cloud_sync_last_sync_at'),
        syncedAt.millisecondsSinceEpoch,
      );
      expect(find.text('Sync complete'), findsOneWidget);
    });

    testWidgets('does not enable sync when interactive first sync fails',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      orchestrator = _RecordingSyncOrchestrator(
        result: SyncResult.error('Drive auth failed'),
      );

      await tester.pumpWidget(buildScreen(orchestrator));
      await tester.pumpAndSettle();

      await tapSyncToggle(tester);
      await tester.tap(find.textContaining('Continue'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(orchestrator.syncCalls, 1);
      expect(orchestrator.interactiveValues, equals([true]));
      expect(prefs.getBool('cloud_sync_consent_given'), isTrue);
      expect(prefs.getBool('cloud_sync_enabled'), isNull);
      expect(prefs.getInt('cloud_sync_last_sync_at'), isNull);
      expect(find.text('Sync failed: Drive auth failed'), findsOneWidget);
    });
  });
}
