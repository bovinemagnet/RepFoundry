import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/application/log_set_use_case.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/domain/repositories/workout_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
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
    // Most recent first, matching the Drift implementation's
    // ORDER BY timestamp DESC LIMIT.
    final matching =
        _sets.where((s) => s.exerciseId == exerciseId).toList().reversed;
    return matching.take(limit).toList();
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
    required String clientId,
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
  Future<Map<String, List<WorkoutSet>>> getSetsForWorkouts(
    List<String> workoutIds,
  ) async =>
      {};
  @override
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId) async => null;
  @override
  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) async => set;
  @override
  Future<void> deleteSet(String setId) async {}
  @override
  Future<List<WorkoutSet>> getSetsFromLastSession(
    String exerciseId,
    String clientId,
  ) async =>
      [];
  @override
  Stream<List<Workout>> watchWorkoutHistory(String clientId) =>
      const Stream.empty();
  @override
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId) =>
      const Stream.empty();
}

void main() {
  late LogSetUseCase useCase;
  late _FakeWorkoutRepository repository;
  late InMemoryPersonalRecordRepository personalRecordRepository;

  setUp(() {
    repository = _FakeWorkoutRepository();
    personalRecordRepository = InMemoryPersonalRecordRepository();
    useCase = LogSetUseCase(
      workoutRepository: repository,
      personalRecordRepository: personalRecordRepository,
    );
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

  test('execute() stores heart rate summary fields when provided', () async {
    const input = LogSetInput(
      workoutId: 'w1',
      exerciseId: 'e1',
      setOrder: 1,
      weight: 100.0,
      reps: 5,
      avgHeartRate: 138,
      peakHeartRate: 171,
    );
    final result = await useCase.execute(input);
    expect(result.set.avgHeartRate, 138);
    expect(result.set.peakHeartRate, 171);
  });

  test('execute() leaves heart rate fields null when not provided', () async {
    final result = await useCase.execute(validInput);
    expect(result.set.avgHeartRate, isNull);
    expect(result.set.peakHeartRate, isNull);
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

  test('execute() does not report a PR when the stored all-time best is higher',
      () async {
    // Bests live in the PR repository but not in the recent sets window.
    for (final seeded in [
      (RecordType.estimatedOneRepMax, 300.0),
      (RecordType.maxWeight, 250.0),
      (RecordType.maxReps, 30.0),
      (RecordType.maxVolume, 3000.0),
    ]) {
      await personalRecordRepository.createRecord(PersonalRecord.create(
        exerciseId: 'e8',
        recordType: seeded.$1,
        value: seeded.$2,
      ));
    }

    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e8',
        setOrder: 1,
        weight: 150,
        reps: 5,
      ),
    );
    expect(result.newPersonalRecords, isEmpty);
  });

  test(
      'execute() does not report a PR when the all-time best is older than '
      'the last 100 sets', () async {
    // All-time best, logged first so it falls outside the recent window.
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e9',
        setOrder: 1,
        weight: 200,
        reps: 10,
      ),
    );
    // 100 light sets push the best out of any 100-set window.
    for (var i = 0; i < 100; i++) {
      await useCase.execute(
        LogSetInput(
          workoutId: 'w1',
          exerciseId: 'e9',
          setOrder: i + 2,
          weight: 50,
          reps: 5,
        ),
      );
    }
    // Beats everything in the window but not the all-time best.
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e9',
        setOrder: 102,
        weight: 100,
        reps: 5,
      ),
    );
    expect(result.newPersonalRecords, isEmpty);
  });

  test('execute() reports and persists a PR that beats the stored best',
      () async {
    for (final seeded in [
      (RecordType.estimatedOneRepMax, 200.0),
      (RecordType.maxWeight, 100.0),
      (RecordType.maxReps, 10.0),
      (RecordType.maxVolume, 1500.0),
    ]) {
      await personalRecordRepository.createRecord(PersonalRecord.create(
        exerciseId: 'e10',
        recordType: seeded.$1,
        value: seeded.$2,
      ));
    }

    // 120kg x 1: beats only the 100kg maxWeight best
    // (e1RM 124, reps 1, volume 120).
    final result = await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e10',
        setOrder: 1,
        weight: 120,
        reps: 1,
      ),
    );
    expect(result.newPersonalRecords.length, 1);
    expect(result.newPersonalRecords.single.recordType, RecordType.maxWeight);
    expect(result.newPersonalRecords.single.value, 120.0);

    final storedBest = await personalRecordRepository.getBestRecord(
      'e10',
      RecordType.maxWeight,
      kSelfClientId,
    );
    expect(storedBest!.value, 120.0);
  });

  test('execute() persists the first-ever set as the initial PRs', () async {
    await useCase.execute(
      const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e11',
        setOrder: 1,
        weight: 100,
        reps: 5,
      ),
    );
    for (final type in RecordType.values) {
      final best = await personalRecordRepository.getBestRecord(
          'e11', type, kSelfClientId);
      expect(best, isNotNull, reason: 'expected initial PR for $type');
    }
  });

  test(
      'execute() skips PR detection when no PersonalRecordRepository '
      'is provided', () async {
    final noRepoUseCase = LogSetUseCase(workoutRepository: repository);
    final result = await noRepoUseCase.execute(validInput);
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
