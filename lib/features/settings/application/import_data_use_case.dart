import 'dart:convert';

import '../../cardio/domain/models/cardio_session.dart';
import '../../cardio/domain/repositories/cardio_session_repository.dart';
import '../../exercises/domain/models/exercise.dart';
import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../../stretching/domain/models/stretching_session.dart';
import '../../stretching/domain/repositories/stretching_session_repository.dart';
import '../../workout/domain/models/workout.dart';
import '../../workout/domain/models/workout_set.dart';
import '../../workout/domain/repositories/workout_repository.dart';

class ImportResult {
  final int exercisesImported;
  final int workoutsImported;
  final int setsImported;
  final int cardioSessionsImported;
  final int personalRecordsImported;
  final int stretchingSessionsImported;
  final int stretchingSessionsSkipped;

  const ImportResult({
    this.exercisesImported = 0,
    this.workoutsImported = 0,
    this.setsImported = 0,
    this.cardioSessionsImported = 0,
    this.personalRecordsImported = 0,
    this.stretchingSessionsImported = 0,
    this.stretchingSessionsSkipped = 0,
  });
}

class ImportDataUseCase {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final CardioSessionRepository cardioSessionRepository;
  final PersonalRecordRepository personalRecordRepository;
  final StretchingSessionRepository stretchingSessionRepository;

  const ImportDataUseCase({
    required this.workoutRepository,
    required this.exerciseRepository,
    required this.cardioSessionRepository,
    required this.personalRecordRepository,
    required this.stretchingSessionRepository,
  });

  Future<ImportResult> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    int exercisesImported = 0;
    int workoutsImported = 0;
    int setsImported = 0;
    int cardioSessionsImported = 0;
    int prsImported = 0;
    int stretchingImported = 0;
    int stretchingSkipped = 0;

    // Track which workout ids landed locally; stretching sessions that
    // reference a missing parent are skipped rather than failing the whole
    // import. Pre-load by querying each candidate; the per-row lookup is
    // cheap on import which is a one-shot operation.
    final landedWorkoutIds = <String>{};

    // Import custom exercises.
    final exercisesList = data['exercises'] as List<dynamic>? ?? [];
    for (final exerciseMap in exercisesList) {
      final map = exerciseMap as Map<String, dynamic>;
      if (map['isCustom'] == true) {
        final exercise = Exercise(
          id: map['id'] as String,
          name: map['name'] as String,
          category:
              _parseEnum(ExerciseCategory.values, map['category'] as String),
          muscleGroup:
              _parseEnum(MuscleGroup.values, map['muscleGroup'] as String),
          equipmentType:
              _parseEnum(EquipmentType.values, map['equipmentType'] as String),
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
        landedWorkoutIds.add(workout.id);
      } catch (_) {
        // Duplicate parent: still treat its id as valid so child rows can
        // attach to the existing workout (matches user expectation that a
        // re-import doesn't orphan child entities).
        landedWorkoutIds.add(workout.id);
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

    // Import cardio sessions.
    final cardioList = data['cardioSessions'] as List<dynamic>? ?? [];
    for (final cardioMap in cardioList) {
      final map = cardioMap as Map<String, dynamic>;
      final session = CardioSession(
        id: map['id'] as String,
        workoutId: map['workoutId'] as String,
        exerciseId: map['exerciseId'] as String,
        durationSeconds: map['durationSeconds'] as int,
        distanceMeters: map['distanceMeters'] != null
            ? (map['distanceMeters'] as num).toDouble()
            : null,
        incline:
            map['incline'] != null ? (map['incline'] as num).toDouble() : null,
        avgHeartRate: map['avgHeartRate'] as int?,
        updatedAt: DateTime.now().toUtc(),
      );
      try {
        await cardioSessionRepository.createSession(session);
        cardioSessionsImported++;
      } catch (_) {
        // Skip duplicates.
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

    // Import stretching sessions.
    //
    // Older exports won't have this key — `?? []` handles that. Sessions
    // whose parent workout did not land locally are skipped (counted in
    // stretchingSessionsSkipped) rather than failing the whole import.
    final stretchingList = data['stretchingSessions'] as List<dynamic>? ?? [];
    for (final entry in stretchingList) {
      final map = entry as Map<String, dynamic>;
      final workoutId = map['workoutId'] as String;

      // If the workout did not arrive in this import, also accept the
      // case where it already existed locally before the import started.
      if (!landedWorkoutIds.contains(workoutId)) {
        final existing = await workoutRepository.getWorkout(workoutId);
        if (existing == null) {
          stretchingSkipped++;
          continue;
        }
        landedWorkoutIds.add(workoutId);
      }

      final session = StretchingSession(
        id: map['id'] as String,
        workoutId: workoutId,
        type: map['type'] as String,
        customName: map['customName'] as String?,
        bodyArea: map['bodyArea'] != null
            ? _parseEnum(
                StretchingBodyArea.values,
                map['bodyArea'] as String,
              )
            : null,
        side: map['side'] != null
            ? _parseEnum(StretchingSide.values, map['side'] as String)
            : null,
        durationSeconds: map['durationSeconds'] as int,
        startedAt: map['startedAt'] != null
            ? DateTime.parse(map['startedAt'] as String)
            : null,
        endedAt: map['endedAt'] != null
            ? DateTime.parse(map['endedAt'] as String)
            : null,
        entryMethod: _parseEnum(
          StretchingEntryMethod.values,
          map['entryMethod'] as String,
        ),
        notes: map['notes'] as String?,
        updatedAt: DateTime.now().toUtc(),
      );
      try {
        await stretchingSessionRepository.createSession(session);
        stretchingImported++;
      } catch (_) {
        // Skip duplicates.
      }
    }

    return ImportResult(
      exercisesImported: exercisesImported,
      workoutsImported: workoutsImported,
      setsImported: setsImported,
      cardioSessionsImported: cardioSessionsImported,
      personalRecordsImported: prsImported,
      stretchingSessionsImported: stretchingImported,
      stretchingSessionsSkipped: stretchingSkipped,
    );
  }

  T _parseEnum<T extends Enum>(List<T> values, String name) {
    return values.firstWhere((v) => v.name == name);
  }
}
