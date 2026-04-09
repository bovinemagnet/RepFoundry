import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/muscle_balance_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/pr_timeline_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/training_load_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/weekly_volume_provider.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with in-memory repository overrides and
/// registers [addTearDown] automatically.
ProviderContainer _makeContainer({
  InMemoryWorkoutRepository? workoutRepo,
  InMemoryExerciseRepository? exerciseRepo,
  InMemoryPersonalRecordRepository? prRepo,
}) {
  final container = ProviderContainer(
    overrides: [
      if (workoutRepo != null)
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
      if (exerciseRepo != null)
        exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
      if (prRepo != null)
        personalRecordRepositoryProvider.overrideWithValue(prRepo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Returns a completed [Workout] with [completedAt] set so it appears in
/// workout history queries.
Workout _completedWorkout() {
  final workout = Workout.create();
  return workout.copyWith(completedAt: DateTime.now().toUtc());
}

void main() {
  // =========================================================================
  // Existing pure-function tests (retained verbatim)
  // =========================================================================

  group('Weekly volume calculation', () {
    test('computeWeeklyVolume groups sets by week', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekStart =
          DateTime(thisWeek.year, thisWeek.month, thisWeek.day);

      final result = computeWeeklyVolume([
        SetData(date: thisWeekStart, volume: 1000, rpe: null),
        SetData(
            date: thisWeekStart.add(const Duration(days: 1)),
            volume: 500,
            rpe: null),
        SetData(
            date: thisWeekStart.subtract(const Duration(days: 7)),
            volume: 800,
            rpe: null),
      ]);

      expect(result, hasLength(2));
      expect(result.last.totalVolume, 1500);
    });

    test('computeWeeklyVolume calculates percent change', () {
      final week1 = DateTime(2026, 1, 5); // Monday
      final week2 = DateTime(2026, 1, 12); // Next Monday

      final result = computeWeeklyVolume([
        SetData(date: week1, volume: 1000, rpe: null),
        SetData(date: week2, volume: 1200, rpe: null),
      ]);

      expect(result, hasLength(2));
      expect(result.first.percentChange, isNull); // First week has no previous
      expect(result.last.percentChange,
          closeTo(20.0, 0.01)); // (1200-1000)/1000 * 100
    });
  });

  group('Training load calculation', () {
    test('computeTrainingLoad calculates sets * avg RPE', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekStart =
          DateTime(thisWeek.year, thisWeek.month, thisWeek.day);

      final result = computeTrainingLoad([
        SetData(date: thisWeekStart, volume: 100, rpe: 8.0),
        SetData(date: thisWeekStart, volume: 100, rpe: 7.0),
      ]);

      expect(result, hasLength(1));
      expect(result.first.setCount, 2);
      expect(result.first.avgRpe, 7.5);
      expect(result.first.load, closeTo(15.0, 0.01));
    });

    test('computeTrainingLoad handles sets without RPE', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekStart =
          DateTime(thisWeek.year, thisWeek.month, thisWeek.day);

      final result = computeTrainingLoad([
        SetData(date: thisWeekStart, volume: 100, rpe: null),
        SetData(date: thisWeekStart, volume: 100, rpe: null),
      ]);

      expect(result, hasLength(1));
      expect(result.first.setCount, 2);
      expect(result.first.avgRpe, 0.0);
      expect(result.first.load, 0.0);
    });
  });

  // =========================================================================
  // muscleBalanceProvider — provider-level tests
  // =========================================================================

  group('muscleBalanceProvider', () {
    test('returns empty list when no workouts exist', () async {
      final container = _makeContainer(
        workoutRepo: InMemoryWorkoutRepository(),
        exerciseRepo: InMemoryExerciseRepository(),
      );

      final result = await container.read(muscleBalanceProvider.future);

      expect(result, isEmpty);
    });

    test(
        'calculates volume percentages by muscle group from a completed workout',
        () async {
      final workoutRepo = InMemoryWorkoutRepository();
      final exerciseRepo = InMemoryExerciseRepository();
      final container = _makeContainer(
        workoutRepo: workoutRepo,
        exerciseRepo: exerciseRepo,
      );

      // Seed: one completed workout with a chest set (id '1', 100 kg × 5 reps
      // = 500 volume) and a quadriceps set (id '2', 80 kg × 10 reps = 800
      // volume). Total = 1300.
      final workout = _completedWorkout();
      await workoutRepo.createWorkout(workout);

      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '1', // Barbell Bench Press — chest
        setOrder: 1,
        weight: 100,
        reps: 5,
      ));
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '2', // Barbell Squat — quadriceps
        setOrder: 2,
        weight: 80,
        reps: 10,
      ));

      final result = await container.read(muscleBalanceProvider.future);

      // Both muscle groups should appear in the result.
      final groups = result.map((e) => e.group).toList();
      expect(groups, containsAll([MuscleGroup.chest, MuscleGroup.quadriceps]));

      // Percentages should sum to ~100 (within floating-point tolerance).
      final totalPercent = result.fold(0.0, (sum, e) => sum + e.volumePercent);
      expect(totalPercent, closeTo(100.0, 0.01));

      // chest: 500/1300 ≈ 38.46 %, quadriceps: 800/1300 ≈ 61.54 %
      final chest = result.firstWhere((e) => e.group == MuscleGroup.chest);
      final quads = result.firstWhere((e) => e.group == MuscleGroup.quadriceps);
      expect(chest.volumePercent, closeTo(38.46, 0.1));
      expect(quads.volumePercent, closeTo(61.54, 0.1));
    });

    test('excludes warm-up sets from volume calculation', () async {
      final workoutRepo = InMemoryWorkoutRepository();
      final exerciseRepo = InMemoryExerciseRepository();
      final container = _makeContainer(
        workoutRepo: workoutRepo,
        exerciseRepo: exerciseRepo,
      );

      final workout = _completedWorkout();
      await workoutRepo.createWorkout(workout);

      // One working set for chest (volume = 500) and one warm-up set for
      // quadriceps (volume = 400). The warm-up should be ignored, so only
      // chest volume contributes.
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '1', // chest
        setOrder: 1,
        weight: 100,
        reps: 5,
        isWarmUp: false,
      ));
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '2', // quadriceps — warm-up, must be excluded
        setOrder: 2,
        weight: 80,
        reps: 5,
        isWarmUp: true,
      ));

      final result = await container.read(muscleBalanceProvider.future);

      // Only the non-warm-up chest set contributes, so quadriceps must not appear.
      final groups = result.map((e) => e.group).toList();
      expect(groups, contains(MuscleGroup.chest));
      expect(groups, isNot(contains(MuscleGroup.quadriceps)));

      // With a single muscle group the percentage must be 100 %.
      expect(result.single.volumePercent, closeTo(100.0, 0.01));
    });

    test('excludes cardio muscle group from results', () async {
      final workoutRepo = InMemoryWorkoutRepository();
      final exerciseRepo = InMemoryExerciseRepository();
      final container = _makeContainer(
        workoutRepo: workoutRepo,
        exerciseRepo: exerciseRepo,
      );

      final workout = _completedWorkout();
      await workoutRepo.createWorkout(workout);

      // Exercise id '16' is Treadmill — MuscleGroup.cardio.
      // Exercise id '1' is Barbell Bench Press — MuscleGroup.chest.
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '16', // cardio
        setOrder: 1,
        weight: 0,
        reps: 1,
      ));
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '1', // chest
        setOrder: 2,
        weight: 100,
        reps: 5,
      ));

      final result = await container.read(muscleBalanceProvider.future);

      final groups = result.map((e) => e.group).toList();
      expect(groups, isNot(contains(MuscleGroup.cardio)));
      expect(groups, contains(MuscleGroup.chest));
    });
  });

  // =========================================================================
  // prTimelineProvider — provider-level tests
  // =========================================================================

  group('prTimelineProvider', () {
    test('returns empty list when no personal records exist', () async {
      final container = _makeContainer(
        prRepo: InMemoryPersonalRecordRepository(),
        exerciseRepo: InMemoryExerciseRepository(),
      );

      final result = await container.read(prTimelineProvider.future);

      expect(result, isEmpty);
    });

    test('returns entries sorted by achievedAt descending', () async {
      final prRepo = InMemoryPersonalRecordRepository();
      final exerciseRepo = InMemoryExerciseRepository();
      final container = _makeContainer(
        prRepo: prRepo,
        exerciseRepo: exerciseRepo,
      );

      final earlier = DateTime(2026, 1, 1).toUtc();
      final later = DateTime(2026, 3, 1).toUtc();
      final now = DateTime.now().toUtc();

      // Seed two records with explicit dates — use the full constructor so we
      // can control achievedAt.
      final olderRecord = PersonalRecord(
        id: 'pr-old',
        exerciseId: '1', // Barbell Bench Press
        recordType: RecordType.maxWeight,
        value: 100,
        achievedAt: earlier,
        updatedAt: now,
      );
      final newerRecord = PersonalRecord(
        id: 'pr-new',
        exerciseId: '2', // Barbell Squat
        recordType: RecordType.maxWeight,
        value: 120,
        achievedAt: later,
        updatedAt: now,
      );

      // Insert in chronological order; the provider must sort descending.
      await prRepo.createRecord(olderRecord);
      await prRepo.createRecord(newerRecord);

      final result = await container.read(prTimelineProvider.future);

      expect(result, hasLength(2));
      // Newest record must come first.
      expect(result.first.record.id, 'pr-new');
      expect(result.last.record.id, 'pr-old');
    });

    test("falls back to 'Unknown' exercise name when exercise id not found",
        () async {
      final prRepo = InMemoryPersonalRecordRepository();
      final exerciseRepo = InMemoryExerciseRepository();
      final container = _makeContainer(
        prRepo: prRepo,
        exerciseRepo: exerciseRepo,
      );

      final now = DateTime.now().toUtc();
      final orphanRecord = PersonalRecord(
        id: 'pr-orphan',
        exerciseId: 'nonexistent-exercise-id',
        recordType: RecordType.estimatedOneRepMax,
        value: 200,
        achievedAt: now,
        updatedAt: now,
      );
      await prRepo.createRecord(orphanRecord);

      final result = await container.read(prTimelineProvider.future);

      expect(result, hasLength(1));
      expect(result.single.exerciseName, 'Unknown');
    });
  });

  // =========================================================================
  // weeklyVolumeProvider — provider-level tests
  // =========================================================================

  group('weeklyVolumeProvider', () {
    test('returns empty list when no workouts exist', () async {
      final container = _makeContainer(
        workoutRepo: InMemoryWorkoutRepository(),
      );

      final result = await container.read(weeklyVolumeProvider.future);

      expect(result, isEmpty);
    });

    test('returns weekly volume entries from seeded workout data', () async {
      final workoutRepo = InMemoryWorkoutRepository();
      final container = _makeContainer(workoutRepo: workoutRepo);

      final workout = _completedWorkout();
      await workoutRepo.createWorkout(workout);

      // 100 kg × 5 reps = 500 volume; 80 kg × 10 reps = 800 volume.
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '1',
        setOrder: 1,
        weight: 100,
        reps: 5,
      ));
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '2',
        setOrder: 2,
        weight: 80,
        reps: 10,
      ));

      final result = await container.read(weeklyVolumeProvider.future);

      expect(result, isNotEmpty);
      // Both sets fall in the current week, so there should be exactly one
      // weekly bucket.
      expect(result, hasLength(1));
      expect(result.single.totalVolume, closeTo(1300, 0.01));
    });
  });

  // =========================================================================
  // trainingLoadProvider — provider-level tests
  // =========================================================================

  group('trainingLoadProvider', () {
    test('returns empty list when no workouts exist', () async {
      final container = _makeContainer(
        workoutRepo: InMemoryWorkoutRepository(),
      );

      final result = await container.read(trainingLoadProvider.future);

      expect(result, isEmpty);
    });

    test('returns weekly load entries with correct setCount and avgRpe',
        () async {
      final workoutRepo = InMemoryWorkoutRepository();
      final container = _makeContainer(workoutRepo: workoutRepo);

      final workout = _completedWorkout();
      await workoutRepo.createWorkout(workout);

      // Two working sets with RPE values — both fall in the current week.
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '1',
        setOrder: 1,
        weight: 100,
        reps: 5,
        rpe: 8.0,
      ));
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: '2',
        setOrder: 2,
        weight: 80,
        reps: 10,
        rpe: 7.0,
      ));

      final result = await container.read(trainingLoadProvider.future);

      expect(result, isNotEmpty);
      // Both sets are in the same week, producing a single bucket.
      expect(result, hasLength(1));
      expect(result.single.setCount, 2);
      expect(result.single.avgRpe, closeTo(7.5, 0.01));
      // load = setCount * avgRpe = 2 * 7.5 = 15
      expect(result.single.load, closeTo(15.0, 0.01));
    });
  });
}
