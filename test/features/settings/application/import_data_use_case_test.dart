import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/history/domain/repositories/personal_record_repository.dart';
import 'package:rep_foundry/features/settings/application/import_data_use_case.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/domain/repositories/workout_repository.dart';

// ---------------------------------------------------------------------------
// File-local fake repositories
// ---------------------------------------------------------------------------

class _FakeExerciseRepository implements ExerciseRepository {
  final Map<String, Exercise> _exercises = {};

  @override
  Future<Exercise> createExercise(Exercise exercise) async {
    if (_exercises.containsKey(exercise.id)) {
      throw StateError('Duplicate exercise id: ${exercise.id}');
    }
    _exercises[exercise.id] = exercise;
    return exercise;
  }

  // Unused stubs
  @override
  Future<List<Exercise>> getAllExercises() async => _exercises.values.toList();
  @override
  Future<List<Exercise>> searchExercises(String query) async => [];
  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(
          MuscleGroup muscleGroup) async =>
      [];
  @override
  Future<Exercise?> getExercise(String id) async => _exercises[id];
  @override
  Future<Exercise> updateExercise(Exercise exercise) async => exercise;
  @override
  Future<void> deleteExercise(String id) async {}
  @override
  Stream<List<Exercise>> watchAllExercises() => const Stream.empty();
}

class _FakeWorkoutRepository implements WorkoutRepository {
  final Map<String, Workout> _workouts = {};
  final Map<String, WorkoutSet> _sets = {};

  @override
  Future<Workout> createWorkout(Workout workout) async {
    if (_workouts.containsKey(workout.id)) {
      throw StateError('Duplicate workout id: ${workout.id}');
    }
    _workouts[workout.id] = workout;
    return workout;
  }

  @override
  Future<WorkoutSet> addSet(WorkoutSet set) async {
    if (_sets.containsKey(set.id)) {
      throw StateError('Duplicate set id: ${set.id}');
    }
    _sets[set.id] = set;
    return set;
  }

  // Unused stubs
  @override
  Future<Workout?> getWorkout(String id) async => _workouts[id];
  @override
  Future<Workout?> getActiveWorkout() async => null;
  @override
  Future<List<Workout>> getWorkoutHistory(
          {int limit = 20, DateTime? before}) async =>
      [];
  @override
  Future<Workout> updateWorkout(Workout workout) async => workout;
  @override
  Future<void> deleteWorkout(String id) async {}
  @override
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) async => [];
  @override
  Future<List<WorkoutSet>> getSetsForExercise(String exerciseId,
          {int limit = 50}) async =>
      [];
  @override
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId) async => null;
  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) async => set;
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

class _FakePersonalRecordRepository implements PersonalRecordRepository {
  final Map<String, PersonalRecord> _records = {};

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) async {
    if (_records.containsKey(record.id)) {
      throw StateError('Duplicate personal record id: ${record.id}');
    }
    _records[record.id] = record;
    return record;
  }

  // Unused stubs
  @override
  Future<List<PersonalRecord>> getRecordsForExercise(
    String exerciseId, {
    RecordType? recordType,
  }) async =>
      [];
  @override
  Future<PersonalRecord?> getBestRecord(
          String exerciseId, RecordType recordType) async =>
      null;
  @override
  Future<List<PersonalRecord>> getAllRecords({int limit = 50}) async => [];
  @override
  Stream<List<PersonalRecord>> watchRecordsForExercise(String exerciseId) =>
      const Stream.empty();
}

// ---------------------------------------------------------------------------
// Helper builders
// ---------------------------------------------------------------------------

Map<String, dynamic> _customExerciseMap({String id = 'ex-1'}) => {
      'id': id,
      'name': 'Bench Press',
      'category': 'strength',
      'muscleGroup': 'chest',
      'equipmentType': 'barbell',
      'isCustom': true,
    };

Map<String, dynamic> _workoutMap({
  String id = 'w-1',
  List<Map<String, dynamic>> sets = const [],
}) =>
    {
      'id': id,
      'startedAt': '2024-01-15T10:00:00.000Z',
      'completedAt': '2024-01-15T11:00:00.000Z',
      'templateId': null,
      'notes': null,
      'sets': sets,
    };

Map<String, dynamic> _setMap({String id = 's-1', String workoutId = 'w-1'}) => {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': 'ex-1',
      'setOrder': 1,
      'weight': 100.0,
      'reps': 5,
      'rpe': 8.0,
      'timestamp': '2024-01-15T10:30:00.000Z',
      'isWarmUp': false,
      'groupId': null,
    };

Map<String, dynamic> _prMap({String id = 'pr-1'}) => {
      'id': id,
      'exerciseId': 'ex-1',
      'recordType': 'maxWeight',
      'value': 100.0,
      'achievedAt': '2024-01-15T10:30:00.000Z',
      'workoutSetId': 's-1',
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ImportDataUseCase useCase;
  late _FakeExerciseRepository exerciseRepo;
  late _FakeWorkoutRepository workoutRepo;
  late _FakePersonalRecordRepository prRepo;

  setUp(() {
    exerciseRepo = _FakeExerciseRepository();
    workoutRepo = _FakeWorkoutRepository();
    prRepo = _FakePersonalRecordRepository();
    useCase = ImportDataUseCase(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
      personalRecordRepository: prRepo,
    );
  });

  group('ImportDataUseCase.importFromJson', () {
    test(
      'importFromJson_fullPayload_importsAllEntitiesAndReturnsCorrectCounts',
      () async {
        // Arrange
        final json = jsonEncode({
          'exercises': [_customExerciseMap()],
          'workouts': [
            _workoutMap(sets: [_setMap()]),
          ],
          'personalRecords': [_prMap()],
        });

        // Act
        final result = await useCase.importFromJson(json);

        // Assert
        expect(result.exercisesImported, 1);
        expect(result.workoutsImported, 1);
        expect(result.setsImported, 1);
        expect(result.personalRecordsImported, 1);
      },
    );

    test(
      'importFromJson_nonCustomExercise_isSkippedAndNotCounted',
      () async {
        // Arrange — exercise with isCustom: false should be ignored
        final json = jsonEncode({
          'exercises': [
            {
              'id': 'ex-builtin',
              'name': 'Squat',
              'category': 'strength',
              'muscleGroup': 'quadriceps',
              'equipmentType': 'barbell',
              'isCustom': false,
            }
          ],
          'workouts': [],
          'personalRecords': [],
        });

        // Act
        final result = await useCase.importFromJson(json);

        // Assert
        expect(result.exercisesImported, 0);
        expect(exerciseRepo._exercises, isEmpty);
      },
    );

    test(
      'importFromJson_duplicateExercise_secondIsSkippedAndCountIsOne',
      () async {
        // Arrange — same id submitted twice
        final json = jsonEncode({
          'exercises': [
            _customExerciseMap(),
            _customExerciseMap(), // duplicate
          ],
          'workouts': [],
          'personalRecords': [],
        });

        // Act
        final result = await useCase.importFromJson(json);

        // Assert — only the first insert succeeds; the StateError is swallowed
        expect(result.exercisesImported, 1);
        expect(exerciseRepo._exercises.length, 1);
      },
    );

    test(
      'importFromJson_duplicateWorkout_workoutAndItsSetsAreSkipped',
      () async {
        // Arrange — two workouts with the same id; second has 1 set
        final json = jsonEncode({
          'exercises': [],
          'workouts': [
            _workoutMap(id: 'w-1', sets: [_setMap(id: 's-1')]),
            // duplicate workout — its sets must also be skipped via continue
            _workoutMap(id: 'w-1', sets: [_setMap(id: 's-2')]),
          ],
          'personalRecords': [],
        });

        // Act
        final result = await useCase.importFromJson(json);

        // Assert
        expect(result.workoutsImported, 1);
        // Only the set belonging to the first (accepted) workout was inserted
        expect(result.setsImported, 1);
        expect(workoutRepo._sets.containsKey('s-1'), isTrue);
        expect(workoutRepo._sets.containsKey('s-2'), isFalse);
      },
    );

    test(
      'importFromJson_duplicateSet_secondIsSkippedAndCountIsOne',
      () async {
        // Arrange — one workout with two sets sharing the same id
        final json = jsonEncode({
          'exercises': [],
          'workouts': [
            _workoutMap(sets: [
              _setMap(id: 's-1'),
              _setMap(id: 's-1'), // duplicate set id
            ]),
          ],
          'personalRecords': [],
        });

        // Act
        final result = await useCase.importFromJson(json);

        // Assert — second set's StateError is swallowed; count stays at 1
        expect(result.setsImported, 1);
        expect(workoutRepo._sets.length, 1);
      },
    );

    test(
      'importFromJson_duplicatePersonalRecord_secondIsSkippedAndCountIsOne',
      () async {
        // Arrange — same PR id submitted twice
        final json = jsonEncode({
          'exercises': [],
          'workouts': [],
          'personalRecords': [
            _prMap(),
            _prMap(), // duplicate
          ],
        });

        // Act
        final result = await useCase.importFromJson(json);

        // Assert
        expect(result.personalRecordsImported, 1);
        expect(prRepo._records.length, 1);
      },
    );

    test(
      'importFromJson_missingTopLevelKeys_returnsZeroCountsWithoutThrowing',
      () async {
        // Arrange — JSON object with none of the expected top-level arrays
        final json = jsonEncode(<String, dynamic>{});

        // Act & Assert — must not throw; all counts default to 0
        final result = await useCase.importFromJson(json);
        expect(result.exercisesImported, 0);
        expect(result.workoutsImported, 0);
        expect(result.setsImported, 0);
        expect(result.personalRecordsImported, 0);
      },
    );

    test(
      'importFromJson_emptyLists_returnsZeroCounts',
      () async {
        // Arrange — all keys present but with empty arrays
        final json = jsonEncode({
          'exercises': <dynamic>[],
          'workouts': <dynamic>[],
          'personalRecords': <dynamic>[],
        });

        // Act
        final result = await useCase.importFromJson(json);

        // Assert
        expect(result.exercisesImported, 0);
        expect(result.workoutsImported, 0);
        expect(result.setsImported, 0);
        expect(result.personalRecordsImported, 0);
      },
    );
  });
}
