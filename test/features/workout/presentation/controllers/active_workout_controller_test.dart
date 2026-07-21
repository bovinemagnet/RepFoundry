import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drift/native.dart';
import 'package:rep_foundry/core/database/app_database.dart' show AppDatabase;
import 'package:rep_foundry/core/heart_rate/hr_session_recorder.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_result.dart';
import 'package:rep_foundry/features/sync/domain/sync_service.dart';
import 'package:rep_foundry/features/sync/presentation/providers/sync_settings_provider.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';

import '../../../cardio/data/fake_heart_rate_service.dart';

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
  final Completer<void> _syncCalled = Completer<void>();
  int syncCalls = 0;

  Future<void> get syncCalled => _syncCalled.future;

  @override
  Future<SyncResult> sync({bool interactive = false}) async {
    syncCalls += 1;
    if (!_syncCalled.isCompleted) {
      _syncCalled.complete();
    }
    return SyncResult.success(entitiesMerged: 0);
  }

  Future<void> dispose() => _database.close();
}

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryPersonalRecordRepository prRepo;
  late InMemoryWorkoutTemplateRepository templateRepo;
  late ProviderContainer container;
  late _RecordingSyncOrchestrator syncOrchestrator;

  ProviderContainer createContainer() {
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
    container = createContainer();
  });

  tearDown(() async {
    container.dispose();
    await syncOrchestrator.dispose();
  });

  ActiveWorkoutController readController() {
    return container.read(activeWorkoutControllerProvider.notifier);
  }

  ActiveWorkoutState readState() {
    return container.read(activeWorkoutControllerProvider);
  }

  /// Wait for the controller's _init microtask to complete.
  Future<void> waitForInit() async {
    // Force the provider to build, then let microtasks settle.
    container.read(activeWorkoutControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('ActiveWorkoutController', () {
    group('startWorkout', () {
      test('creates an active workout', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final state = readState();
        expect(state.hasActiveWorkout, isTrue);
        expect(state.activeWorkout, isNotNull);
        expect(state.isLoading, isFalse);
      });

      test('is idempotent — second call does not create a new workout',
          () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();
        final firstId = readState().activeWorkout!.id;

        await controller.startWorkout();
        expect(readState().activeWorkout!.id, firstId);
      });
    });

    group('addExercise', () {
      test('adds exercise to exerciseIds', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);

        expect(readState().exerciseIds, contains(exercise.id));
        expect(readState().exercises, contains(exercise));
      });

      test('does nothing when no active workout', () async {
        await waitForInit();
        final controller = readController();
        final exercises = await exerciseRepo.getAllExercises();
        await controller.addExercise(exercises.first);

        expect(readState().exerciseIds, isEmpty);
      });
    });

    group('logSet', () {
      test('adds set to state', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);

        await controller.logSet(
          exerciseId: exercise.id,
          weight: 100,
          reps: 5,
        );

        final sets = readState().setsByExercise[exercise.id]!;
        expect(sets, hasLength(1));
        expect(sets.first.weight, 100);
        expect(sets.first.reps, 5);
      });

      test('stamps the set with avg/peak heart rate from the recorder',
          () async {
        final hrService = FakeHeartRateService();
        addTearDown(hrService.dispose);
        container.dispose();
        container = ProviderContainer(
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
            heartRateServiceProvider.overrideWithValue(hrService),
          ],
        );
        // Start the recorder buffering before any readings arrive.
        container.read(hrSessionRecorderProvider.notifier);

        await waitForInit();
        final controller = readController();
        await controller.startWorkout();
        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);

        await Future<void>.delayed(const Duration(milliseconds: 5));
        hrService.emitHeartRate(130);
        hrService.emitHeartRate(150);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        await controller.logSet(exerciseId: exercise.id, weight: 100, reps: 5);

        final firstSet = readState().setsByExercise[exercise.id]!.single;
        expect(firstSet.avgHeartRate, 140);
        expect(firstSet.peakHeartRate, 150);

        // The second set's window starts at the first set's timestamp, so it
        // must only see the readings emitted after it.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        hrService.emitHeartRate(170);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        await controller.logSet(exerciseId: exercise.id, weight: 100, reps: 5);

        final secondSet = readState().setsByExercise[exercise.id]!.last;
        expect(secondSet.avgHeartRate, 170);
        expect(secondSet.peakHeartRate, 170);
      });

      test('leaves heart rate fields null when no monitor readings exist',
          () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();
        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);

        await controller.logSet(exerciseId: exercise.id, weight: 100, reps: 5);

        final set = readState().setsByExercise[exercise.id]!.single;
        expect(set.avgHeartRate, isNull);
        expect(set.peakHeartRate, isNull);
      });

      test(
          'surfaces a clean error message (not the exception class name) '
          'for invalid reps', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);

        await controller.logSet(
          exerciseId: exercise.id,
          weight: 100,
          reps: 0,
        );

        // Invalid input logs no set.
        expect(readState().setsByExercise[exercise.id] ?? const [], isEmpty);
        // The user-facing error must not leak the exception class name.
        expect(readState().error, 'Reps must be greater than zero');
      });
    });

    group('updateSet', () {
      test('modifies set weight in state', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);
        await controller.logSet(
          exerciseId: exercise.id,
          weight: 100,
          reps: 5,
        );

        final originalSet = readState().setsByExercise[exercise.id]!.first;
        final updated = originalSet.copyWith(weight: 120);
        await controller.updateSet(updated);

        final sets = readState().setsByExercise[exercise.id]!;
        expect(sets.first.weight, 120);
        expect(sets.first.id, originalSet.id);
      });
    });

    group('deleteSet', () {
      test('removes set from state', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);
        await controller.logSet(
          exerciseId: exercise.id,
          weight: 100,
          reps: 5,
        );

        final set = readState().setsByExercise[exercise.id]!.first;
        await controller.deleteSet(set.id, exercise.id);

        final sets = readState().setsByExercise[exercise.id]!;
        expect(sets, isEmpty);
      });
    });

    group('finishWorkout', () {
      test('clears active workout', () async {
        await waitForInit();

        // Eagerly initialise settings providers so their async _load()
        // completes before finishWorkout reads them. Without this, the
        // _load() futures resolve after tearDown disposes the container.
        container.read(healthSyncSettingsProvider);
        container.read(syncSettingsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final controller = readController();
        await controller.startWorkout();
        expect(readState().hasActiveWorkout, isTrue);

        await controller.finishWorkout();
        expect(readState().hasActiveWorkout, isFalse);
      });

      test('syncs to cloud when persisted sync is enabled', () async {
        SharedPreferences.setMockInitialValues({'cloud_sync_enabled': true});
        container.dispose();
        await syncOrchestrator.dispose();
        syncOrchestrator = _RecordingSyncOrchestrator();
        container = createContainer();

        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        await controller.finishWorkout();
        await syncOrchestrator.syncCalled;

        expect(syncOrchestrator.syncCalls, 1);
      });
    });

    group('reopenWorkout', () {
      test('reopens a completed workout and loads its sets into state',
          () async {
        await waitForInit();
        final now = DateTime.now().toUtc();
        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;

        await workoutRepo.createWorkout(
          Workout(
            id: 'w-done',
            startedAt: now.subtract(const Duration(hours: 1)),
            completedAt: now,
            clientId: kSelfClientId,
            updatedAt: now,
          ),
        );
        await workoutRepo.addSet(
          WorkoutSet.create(
            workoutId: 'w-done',
            exerciseId: exercise.id,
            setOrder: 0,
            weight: 100,
            reps: 5,
          ),
        );

        final controller = readController();
        final reopened = await controller.reopenWorkout('w-done');

        expect(reopened, isTrue);
        final state = readState();
        expect(state.hasActiveWorkout, isTrue);
        expect(state.activeWorkout!.id, 'w-done');
        expect(state.activeWorkout!.completedAt, isNull);
        expect(state.setsByExercise[exercise.id], hasLength(1));

        // Persisted back as in-progress.
        final active = await workoutRepo.getActiveWorkout();
        expect(active!.id, 'w-done');
      });

      test('returns false when another workout is already active', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();
        final activeId = readState().activeWorkout!.id;

        final now = DateTime.now().toUtc();
        await workoutRepo.createWorkout(
          Workout(
            id: 'w-old',
            startedAt: now.subtract(const Duration(days: 1)),
            completedAt: now.subtract(const Duration(days: 1)),
            clientId: kSelfClientId,
            updatedAt: now,
          ),
        );

        final reopened = await controller.reopenWorkout('w-old');

        expect(reopened, isFalse);
        // The currently active workout is untouched and 'w-old' stays completed.
        expect(readState().activeWorkout!.id, activeId);
        expect((await workoutRepo.getWorkout('w-old'))!.completedAt, isNotNull);
      });

      test('returns false for an unknown workout id', () async {
        await waitForInit();
        final controller = readController();

        final reopened = await controller.reopenWorkout('does-not-exist');

        expect(reopened, isFalse);
        expect(readState().hasActiveWorkout, isFalse);
      });
    });

    group('startFromTemplate', () {
      test('adds template exercises to workout', () async {
        await waitForInit();
        final controller = readController();

        // Create a template referencing default exercises '1' and '2'.
        final now = DateTime.now().toUtc();
        final template = WorkoutTemplate.create(
          name: 'Push Day',
          exercises: [
            TemplateExercise(
              id: 'te1',
              templateId: '',
              exerciseId: '1',
              exerciseName: 'Barbell Bench Press',
              targetSets: 3,
              targetReps: 10,
              orderIndex: 0,
              updatedAt: now,
            ),
            TemplateExercise(
              id: 'te2',
              templateId: '',
              exerciseId: '2',
              exerciseName: 'Barbell Squat',
              targetSets: 3,
              targetReps: 10,
              orderIndex: 1,
              updatedAt: now,
            ),
          ],
        );
        await templateRepo.createTemplate(template);

        await controller.startFromTemplate(template);

        expect(readState().hasActiveWorkout, isTrue);
        expect(readState().exerciseIds, contains('1'));
        expect(readState().exerciseIds, contains('2'));
      });
    });

    group('linkSuperset & unlinkSuperset', () {
      test('links and unlinks two exercises', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final exercises = await exerciseRepo.getAllExercises();
        final e1 = exercises[0];
        final e2 = exercises[1];
        await controller.addExercise(e1);
        await controller.addExercise(e2);

        // Must log at least one set per exercise for linking to be meaningful.
        await controller.logSet(
          exerciseId: e1.id,
          weight: 100,
          reps: 10,
        );
        await controller.logSet(
          exerciseId: e2.id,
          weight: 60,
          reps: 12,
        );

        await controller.linkSuperset(e1.id, e2.id);

        final groups = getSupersetGroups(readState().setsByExercise);
        expect(groups.values.first, containsAll([e1.id, e2.id]));

        await controller.unlinkSuperset(e1.id);

        final groupsAfter = getSupersetGroups(readState().setsByExercise);
        expect(groupsAfter, isEmpty);
      });
    });

    group('clearPR', () {
      test('clears latestPR from state', () async {
        await waitForInit();
        final controller = readController();
        await controller.startWorkout();

        final exercises = await exerciseRepo.getAllExercises();
        final exercise = exercises.first;
        await controller.addExercise(exercise);

        // Log a set — first ever set triggers PR.
        await controller.logSet(
          exerciseId: exercise.id,
          weight: 100,
          reps: 5,
        );

        // PR may or may not be set depending on repository state.
        // Either way, clearPR should ensure it's null.
        controller.clearPR();
        expect(readState().latestPR, isNull);
      });
    });

    group('clearError', () {
      test('clears error from state', () async {
        await waitForInit();
        final controller = readController();
        // Manually verify clearError works on any error state.
        controller.clearError();
        expect(readState().error, isNull);
      });
    });
  });
}
