import 'dart:convert';

import '../../exercises/domain/models/exercise.dart';
import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../../workout/domain/models/workout.dart';
import '../../workout/domain/models/workout_set.dart';
import '../../workout/domain/repositories/workout_repository.dart';

class ImportResult {
  final int exercisesImported;
  final int workoutsImported;
  final int setsImported;
  final int personalRecordsImported;

  const ImportResult({
    this.exercisesImported = 0,
    this.workoutsImported = 0,
    this.setsImported = 0,
    this.personalRecordsImported = 0,
  });
}

class ImportDataUseCase {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final PersonalRecordRepository personalRecordRepository;

  const ImportDataUseCase({
    required this.workoutRepository,
    required this.exerciseRepository,
    required this.personalRecordRepository,
  });

  Future<ImportResult> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    int exercisesImported = 0;
    int workoutsImported = 0;
    int setsImported = 0;
    int prsImported = 0;

    // Import custom exercises.
    final exercisesList = data['exercises'] as List<dynamic>? ?? [];
    for (final exerciseMap in exercisesList) {
      final map = exerciseMap as Map<String, dynamic>;
      if (map['isCustom'] == true) {
        final exercise = Exercise(
          id: map['id'] as String,
          name: map['name'] as String,
          category: _parseEnum(ExerciseCategory.values, map['category'] as String),
          muscleGroup: _parseEnum(MuscleGroup.values, map['muscleGroup'] as String),
          equipmentType: _parseEnum(EquipmentType.values, map['equipmentType'] as String),
          isCustom: true,
          updatedAt: DateTime.now().toUtc(),
        );
        try {
          await exerciseRepository.createExercise(exercise);
          exercisesImported++;
        } catch (_) {
          // Skip duplicates.
        }
      }
    }

    // Import workouts and their sets.
    final workoutsList = data['workouts'] as List<dynamic>? ?? [];
    for (final workoutMap in workoutsList) {
      final map = workoutMap as Map<String, dynamic>;
      final workout = Workout(
        id: map['id'] as String,
        startedAt: DateTime.parse(map['startedAt'] as String),
        completedAt: map['completedAt'] != null
            ? DateTime.parse(map['completedAt'] as String)
            : null,
        templateId: map['templateId'] as String?,
        notes: map['notes'] as String?,
        updatedAt: DateTime.now().toUtc(),
      );
      try {
        await workoutRepository.createWorkout(workout);
        workoutsImported++;
      } catch (_) {
        // Skip duplicates.
        continue;
      }

      final setsList = map['sets'] as List<dynamic>? ?? [];
      for (final setMap in setsList) {
        final s = setMap as Map<String, dynamic>;
        final workoutSet = WorkoutSet(
          id: s['id'] as String,
          workoutId: workout.id,
          exerciseId: s['exerciseId'] as String,
          setOrder: s['setOrder'] as int,
          weight: (s['weight'] as num).toDouble(),
          reps: s['reps'] as int,
          rpe: s['rpe'] != null ? (s['rpe'] as num).toDouble() : null,
          timestamp: DateTime.parse(s['timestamp'] as String),
          isWarmUp: s['isWarmUp'] as bool? ?? false,
          groupId: s['groupId'] as String?,
          updatedAt: DateTime.now().toUtc(),
        );
        try {
          await workoutRepository.addSet(workoutSet);
          setsImported++;
        } catch (_) {
          // Skip duplicates.
        }
      }
    }

    // Import personal records.
    final prsList = data['personalRecords'] as List<dynamic>? ?? [];
    for (final prMap in prsList) {
      final map = prMap as Map<String, dynamic>;
      final pr = PersonalRecord(
        id: map['id'] as String,
        exerciseId: map['exerciseId'] as String,
        recordType: _parseEnum(RecordType.values, map['recordType'] as String),
        value: (map['value'] as num).toDouble(),
        achievedAt: DateTime.parse(map['achievedAt'] as String),
        workoutSetId: map['workoutSetId'] as String?,
        updatedAt: DateTime.now().toUtc(),
      );
      try {
        await personalRecordRepository.createRecord(pr);
        prsImported++;
      } catch (_) {
        // Skip duplicates.
      }
    }

    return ImportResult(
      exercisesImported: exercisesImported,
      workoutsImported: workoutsImported,
      setsImported: setsImported,
      personalRecordsImported: prsImported,
    );
  }

  T _parseEnum<T extends Enum>(List<T> values, String name) {
    return values.firstWhere((v) => v.name == name);
  }
}
