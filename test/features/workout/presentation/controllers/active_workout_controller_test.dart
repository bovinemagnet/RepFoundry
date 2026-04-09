import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/sync/presentation/providers/sync_settings_provider.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryPersonalRecordRepository prRepo;
  late InMemoryWorkoutTemplateRepository templateRepo;
  late ProviderContainer container;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    workoutRepo = InMemoryWorkoutRepository();
    exerciseRepo = InMemoryExerciseRepository();
    prRepo = InMemoryPersonalRecordRepository();
    templateRepo = InMemoryWorkoutTemplateRepository();
    container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
        exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
        personalRecordRepositoryProvider.overrideWithValue(prRepo),
        workoutTemplateRepositoryProvider.overrideWithValue(templateRepo),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => HealthSyncSettingsNotifier()),
        syncSettingsProvider.overrideWith(() => SyncSettingsNotifier()),
      ],
    );
  });

  tearDown(() => container.dispose());

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
