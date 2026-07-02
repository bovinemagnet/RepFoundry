import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/data/noop_cloud_sync_service.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_result.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/core/units/weight_unit_provider.dart';
import 'package:rep_foundry/features/settings/presentation/screens/settings_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
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

  factory _RecordingSyncOrchestrator({required SyncResult result}) =>
      _RecordingSyncOrchestrator._(
        AppDatabase.forTesting(NativeDatabase.memory()),
        result: result,
      );

  final AppDatabase _database;
  final SyncResult result;
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

  late _RecordingSyncOrchestrator orchestrator;

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(900, 2600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() async {
    await orchestrator.dispose();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
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
