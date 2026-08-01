import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drift/native.dart';
import 'package:rep_foundry/core/database/app_database.dart' show AppDatabase;
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_result.dart';
import 'package:rep_foundry/features/sync/domain/sync_service.dart';
import 'package:rep_foundry/features/sync/presentation/providers/sync_settings_provider.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _NeverEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => false;
}

class _FakeCloudSyncService implements CloudSyncService {
  @override
  Future<void> deleteCloudData({bool interactive = false}) async {}

  @override
  Future<String?> downloadSnapshot({bool interactive = false}) async => null;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> uploadSnapshot(
    String jsonData, {
    bool interactive = false,
  }) async {}
}

class _NoOpHealthSyncSettingsNotifier extends HealthSyncSettingsNotifier {
  @override
  HealthSyncSettings build() => const HealthSyncSettings();
}

class _RecordingSyncOrchestrator extends SyncOrchestrator {
  _RecordingSyncOrchestrator._(this._database)
      : super(
          database: _database,
          cloudService: _FakeCloudSyncService(),
          deviceId: 'test-device',
        );

  factory _RecordingSyncOrchestrator() => _RecordingSyncOrchestrator._(
        AppDatabase.forTesting(NativeDatabase.memory()),
      );

  final AppDatabase _database;

  @override
  Future<SyncResult> sync({bool interactive = false}) async {
    return SyncResult.success(entitiesMerged: 0);
  }

  Future<void> dispose() => _database.close();
}

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryPersonalRecordRepository prRepo;
  late InMemoryWorkoutTemplateRepository templateRepo;
  late _RecordingSyncOrchestrator syncOrchestrator;

  ProviderContainer createContainer(EntitlementService entitlementService) {
    return ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
        exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
        personalRecordRepositoryProvider.overrideWithValue(prRepo),
        workoutTemplateRepositoryProvider.overrideWithValue(templateRepo),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => _NoOpHealthSyncSettingsNotifier()),
        syncSettingsProvider.overrideWith(() => SyncSettingsNotifier()),
        syncOrchestratorProvider.overrideWithValue(syncOrchestrator),
        entitlementServiceProvider.overrideWithValue(entitlementService),
      ],
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    workoutRepo = InMemoryWorkoutRepository();
    exerciseRepo = InMemoryExerciseRepository();
    prRepo = InMemoryPersonalRecordRepository();
    templateRepo = InMemoryWorkoutTemplateRepository();
    syncOrchestrator = _RecordingSyncOrchestrator();
  });

  tearDown(() async {
    await syncOrchestrator.dispose();
  });

  /// Wait for the controller's _init microtask to complete.
  Future<void> waitForInit(ProviderContainer container) async {
    container.read(activeWorkoutControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('logging a set emits one SetLogged event when entitled', () async {
    final container = createContainer(_AlwaysEntitled());
    addTearDown(container.dispose);

    final received = <TrainerEvent>[];
    container.read(trainerEventBusProvider).events.listen(received.add);

    await waitForInit(container);
    final controller = container.read(activeWorkoutControllerProvider.notifier);
    await controller.startWorkout();

    final exercises = await exerciseRepo.getAllExercises();
    final exercise = exercises.first;
    await controller.addExercise(exercise);

    await controller.logSet(exerciseId: exercise.id, weight: 100, reps: 5);
    await Future<void>.delayed(Duration.zero);

    final setLoggedEvents = received.whereType<SetLogged>().toList();
    expect(setLoggedEvents, hasLength(1));
    expect(setLoggedEvents.single.setNumber, 1);
  });

  test('logging a set emits nothing when not entitled', () async {
    final container = createContainer(_NeverEntitled());
    addTearDown(container.dispose);

    final received = <TrainerEvent>[];
    container.read(trainerEventBusProvider).events.listen(received.add);

    await waitForInit(container);
    final controller = container.read(activeWorkoutControllerProvider.notifier);
    await controller.startWorkout();

    final exercises = await exerciseRepo.getAllExercises();
    final exercise = exercises.first;
    await controller.addExercise(exercise);

    await controller.logSet(exerciseId: exercise.id, weight: 100, reps: 5);
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });
}
