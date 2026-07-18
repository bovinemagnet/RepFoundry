import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/settings/presentation/providers/import_file_picker_provider.dart';
import 'package:rep_foundry/features/settings/presentation/screens/settings_screen.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/data/noop_cloud_sync_service.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fixture(String name) =>
    File('test/features/settings/fixtures/$name').readAsStringSync();

class _TestSyncOrchestrator extends SyncOrchestrator {
  _TestSyncOrchestrator._(this._database)
      : super(
          database: _database,
          cloudService: const NoopCloudSyncService(),
          deviceId: 'test-device',
        );

  factory _TestSyncOrchestrator() =>
      _TestSyncOrchestrator._(AppDatabase.forTesting(NativeDatabase.memory()));

  final AppDatabase _database;

  Future<void> dispose() => _database.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestSyncOrchestrator orchestrator;
  late InMemoryWorkoutRepository workoutRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(900, 2600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    orchestrator = _TestSyncOrchestrator();
    workoutRepo = InMemoryWorkoutRepository();
  });

  tearDown(() async {
    await orchestrator.dispose();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget buildScreen(String? pickedContent) {
    return ProviderScope(
      overrides: [
        syncOrchestratorProvider.overrideWithValue(orchestrator),
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
        exerciseRepositoryProvider
            .overrideWithValue(InMemoryExerciseRepository()),
        cardioSessionRepositoryProvider
            .overrideWithValue(InMemoryCardioSessionRepository()),
        personalRecordRepositoryProvider
            .overrideWithValue(InMemoryPersonalRecordRepository()),
        stretchingSessionRepositoryProvider
            .overrideWithValue(InMemoryStretchingSessionRepository()),
        importFileContentPickerProvider
            .overrideWithValue(() async => pickedContent),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: SettingsScreen(),
      ),
    );
  }

  Future<void> tapImportFromFile(WidgetTester tester) async {
    final row = find.text('Import from File');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  group('Import from File', () {
    testWidgets('Strong file without units asks for the unit then imports',
        (tester) async {
      await tester.pumpWidget(buildScreen(fixture('strong.csv')));
      await tester.pumpAndSettle();

      await tapImportFromFile(tester);

      expect(find.textContaining('Detected format: Strong'), findsOneWidget);
      expect(find.text('Import as kg'), findsOneWidget);
      expect(find.text('Import as lbs'), findsOneWidget);

      await tester.tap(find.text('Import as kg'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Imported 2 workouts'), findsOneWidget);
      expect(await workoutRepo.getWorkoutHistory(), hasLength(2));
    });

    testWidgets('Hevy file confirms without a unit question', (tester) async {
      await tester.pumpWidget(buildScreen(fixture('hevy.csv')));
      await tester.pumpAndSettle();

      await tapImportFromFile(tester);

      expect(find.textContaining('Detected format: Hevy'), findsOneWidget);
      expect(find.text('Import as kg'), findsNothing);

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(await workoutRepo.getWorkoutHistory(), hasLength(2));
    });

    testWidgets('unsupported content shows an error and imports nothing',
        (tester) async {
      await tester.pumpWidget(buildScreen(fixture('malformed.csv')));
      await tester.pumpAndSettle();

      await tapImportFromFile(tester);

      expect(find.textContaining('Unsupported file format'), findsOneWidget);
      expect(await workoutRepo.getWorkoutHistory(), isEmpty);
    });

    testWidgets('cancelled picker does nothing', (tester) async {
      await tester.pumpWidget(buildScreen(null));
      await tester.pumpAndSettle();

      await tapImportFromFile(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(await workoutRepo.getWorkoutHistory(), isEmpty);
    });

    testWidgets('JSON file content routes through the JSON importer',
        (tester) async {
      const json = '{"workouts": [{"id": "w-json-1", '
          '"startedAt": "2024-03-10T09:00:00Z", '
          '"completedAt": "2024-03-10T10:00:00Z", "sets": []}]}';
      await tester.pumpWidget(buildScreen(json));
      await tester.pumpAndSettle();

      await tapImportFromFile(tester);

      expect(find.textContaining('Detected format: JSON'), findsOneWidget);
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(await workoutRepo.getWorkoutHistory(), hasLength(1));
    });
  });
}
