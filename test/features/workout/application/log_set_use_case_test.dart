import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/application/log_set_use_case.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/domain/repositories/workout_repository.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';

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
    return _sets.where((s) => s.exerciseId == exerciseId).take(limit).toList();
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
  Future<List<WorkoutSet>> getSetsFromLastSession(String exerciseId) async =>
      [];
  @override
  Stream<List<Workout>> watchWorkoutHistory() => const Stream.empty();
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

  test('execute() detects all PR types on first set', () async {
    final result = await useCase.execute(validInput);
    expect(result.newPersonalRecords, isNotEmpty);

    final types = result.newPersonalRecords.map((pr) => pr.recordType).toSet();
    expect(types, contains(RecordType.estimatedOneRepMax));
    expect(types, contains(RecordType.maxWeight));
    expect(types, contains(RecordType.maxReps));
    expect(types, contains(RecordType.maxVolume));
  });

  test('execute() detects e1RM PR when e1RM exceeds previous', () async {
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
    final e1rmPR = result.newPersonalRecords
        .where((pr) => pr.recordType == RecordType.estimatedOneRepMax)
        .firstOrNull;
    expect(e1rmPR, isNotNull);
    expect(e1rmPR!.value, greaterThan(50 * (1 + 5 / 30.0)));
  });

  test('execute() detects maxWeight PR', () async {
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e3',
        setOrder: 1,
        weight: 80,
        reps: 10,
      ),
    );
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e3',
        setOrder: 2,
        weight: 100,
        reps: 3,
      ),
    );
    final weightPR = result.newPersonalRecords
        .where((pr) => pr.recordType == RecordType.maxWeight)
        .firstOrNull;
    expect(weightPR, isNotNull);
    expect(weightPR!.value, 100.0);
  });

  test('execute() detects maxReps PR', () async {
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e4',
        setOrder: 1,
        weight: 60,
        reps: 5,
      ),
    );
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e4',
        setOrder: 2,
        weight: 40,
        reps: 15,
      ),
    );
    final repsPR = result.newPersonalRecords
        .where((pr) => pr.recordType == RecordType.maxReps)
        .firstOrNull;
    expect(repsPR, isNotNull);
    expect(repsPR!.value, 15.0);
  });

  test('execute() detects maxVolume PR', () async {
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e5',
        setOrder: 1,
        weight: 100,
        reps: 3, // volume = 300
      ),
    );
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e5',
        setOrder: 2,
        weight: 60,
        reps: 10, // volume = 600
      ),
    );
    final volumePR = result.newPersonalRecords
        .where((pr) => pr.recordType == RecordType.maxVolume)
        .firstOrNull;
    expect(volumePR, isNotNull);
    expect(volumePR!.value, 600.0);
  });

  test('execute() can return multiple PRs in one set', () async {
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e6',
        setOrder: 1,
        weight: 50,
        reps: 5,
      ),
    );
    // Heavier + more reps = PRs in all categories
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e6',
        setOrder: 2,
        weight: 100,
        reps: 10,
      ),
    );
    expect(result.newPersonalRecords.length, 4);
  });

  test('execute() does not detect PR when below previous', () async {
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e7',
        setOrder: 1,
        weight: 100,
        reps: 10,
      ),
    );
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e7',
        setOrder: 2,
        weight: 50,
        reps: 5,
      ),
    );
    expect(result.newPersonalRecords, isEmpty);
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
