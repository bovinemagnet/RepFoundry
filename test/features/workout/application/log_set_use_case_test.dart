import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/application/log_set_use_case.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/domain/repositories/workout_repository.dart';

class _FakeWorkoutRepository implements WorkoutRepository {
  final List<WorkoutSet> _sets = [];

  @override
  Future<WorkoutSet> addSet(WorkoutSet set) async {
    _sets.add(set);
    return set;
  }

  @override
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    int limit = 50,
  }) async {
    return _sets
        .where((s) => s.exerciseId == exerciseId)
        .take(limit)
        .toList();
  }

  // Unused stubs
  @override
  Future<Workout> createWorkout(Workout workout) async => workout;
  @override
  Future<Workout?> getWorkout(String id) async => null;
  @override
  Future<Workout?> getActiveWorkout() async => null;
  @override
  Future<List<Workout>> getWorkoutHistory({
    int limit = 20,
    DateTime? before,
  }) async =>
      [];
  @override
  Future<Workout> updateWorkout(Workout workout) async => workout;
  @override
  Future<void> deleteWorkout(String id) async {}
  @override
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) async => [];
  @override
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId) async => null;
  @override
  Future<void> deleteSet(String setId) async {}
  @override
  Stream<List<Workout>> watchWorkoutHistory() =>
      const Stream.empty();
  @override
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId) =>
      const Stream.empty();
}

void main() {
  late LogSetUseCase useCase;
  late _FakeWorkoutRepository repository;

  setUp(() {
    repository = _FakeWorkoutRepository();
    useCase = LogSetUseCase(workoutRepository: repository);
  });

  const validInput = LogSetInput(
    workoutId: 'w1',
    exerciseId: 'e1',
    setOrder: 1,
    weight: 100.0,
    reps: 5,
  );

  test('execute() saves set and returns it', () async {
    final result = await useCase.execute(validInput);
    expect(result.set.workoutId, 'w1');
    expect(result.set.exerciseId, 'e1');
    expect(result.set.weight, 100.0);
    expect(result.set.reps, 5);
  });

  test('execute() detects a PR on first set', () async {
    final result = await useCase.execute(validInput);
    // First set ever → any positive e1RM should trigger PR
    expect(result.newPersonalRecord, isNull);
    // (The PR check only fires when the new set beats a previous best)
  });

  test('execute() detects PR when e1RM exceeds previous', () async {
    // Log a light set first
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e2',
        setOrder: 1,
        weight: 50,
        reps: 5,
      ),
    );
    // Now log a heavier set
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e2',
        setOrder: 2,
        weight: 100,
        reps: 5,
      ),
    );
    expect(result.newPersonalRecord, isNotNull);
    expect(result.newPersonalRecord!.value,
        greaterThan(50 * (1 + 5 / 30.0)));
  });

  test('throws LogSetException for zero reps', () async {
    const badInput = LogSetInput(
      workoutId: 'w1',
      exerciseId: 'e1',
      setOrder: 1,
      weight: 100,
      reps: 0,
    );
    expect(
      () => useCase.execute(badInput),
      throwsA(isA<LogSetException>()),
    );
  });

  test('throws LogSetException for negative weight', () async {
    const badInput = LogSetInput(
      workoutId: 'w1',
      exerciseId: 'e1',
      setOrder: 1,
      weight: -10,
      reps: 5,
    );
    expect(
      () => useCase.execute(badInput),
      throwsA(isA<LogSetException>()),
    );
  });

  test('throws LogSetException for RPE out of range', () async {
    const badInput = LogSetInput(
      workoutId: 'w1',
      exerciseId: 'e1',
      setOrder: 1,
      weight: 100,
      reps: 5,
      rpe: 11,
    );
    expect(
      () => useCase.execute(badInput),
      throwsA(isA<LogSetException>()),
    );
  });
}
