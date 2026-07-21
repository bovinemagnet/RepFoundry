import 'package:uuid/uuid.dart';

import '../../../clients/domain/models/client.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../exercises/domain/repositories/exercise_repository.dart';
import '../../../history/domain/models/personal_record.dart';
import '../../../history/domain/repositories/personal_record_repository.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../workout/domain/repositories/workout_repository.dart';
import '../import_data_use_case.dart';
import 'parsed_history.dart';

/// Fixed namespace for deterministic import IDs. Re-importing the same file
/// regenerates identical UUIDs, which is what makes import idempotent.
const _importNamespace = 'e64c1c74-4b1e-4f42-9dfb-1f4d1d1e68aa';

String _importId(String seed) => const Uuid().v5(_importNamespace, seed);

/// Persists a [ParsedHistory]: resolves exercise names to library entries
/// (creating custom exercises for strangers), inserts workouts and sets
/// under deterministic IDs, skips anything already present, and backfills
/// personal records the imported history beats.
///
/// Writes are additive-only inserts, so a partial failure cannot corrupt
/// existing data and a re-run completes the remainder.
class CsvImportEngine {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final PersonalRecordRepository personalRecordRepository;

  const CsvImportEngine({
    required this.workoutRepository,
    required this.exerciseRepository,
    required this.personalRecordRepository,
  });

  Future<ImportResult> import(ParsedHistory history) async {
    var workoutsImported = 0;
    var setsImported = 0;
    var exercisesCreated = 0;
    var duplicatesSkipped = 0;
    var prsImported = 0;

    // Exercise-name resolution table, case-insensitive.
    final library = await exerciseRepository.getAllExercises();
    final byName = <String, Exercise>{
      for (final e in library) e.name.trim().toLowerCase(): e,
    };

    // Working sets that landed (or already existed), grouped by exercise,
    // feeding PR backfill afterwards.
    final setsByExercise = <String, List<WorkoutSet>>{};

    for (final parsedWorkout in history.workouts) {
      final workoutKey = '${history.source}|${parsedWorkout.sourceKey}';
      final workoutId = _importId(workoutKey);

      if (await workoutRepository.getWorkout(workoutId) == null) {
        try {
          await workoutRepository.createWorkout(Workout(
            id: workoutId,
            startedAt: parsedWorkout.startedAt,
            completedAt: parsedWorkout.completedAt,
            notes: parsedWorkout.name,
            clientId: kSelfClientId,
            updatedAt: parsedWorkout.startedAt,
          ));
          workoutsImported++;
        } catch (_) {
          duplicatesSkipped++;
        }
      } else {
        duplicatesSkipped++;
      }

      final existingSetIds =
          (await workoutRepository.getSetsForWorkout(workoutId))
              .map((s) => s.id)
              .toSet();

      for (var i = 0; i < parsedWorkout.sets.length; i++) {
        final parsed = parsedWorkout.sets[i];

        final nameKey = parsed.exerciseName.trim().toLowerCase();
        var exercise = byName[nameKey];
        if (exercise == null) {
          exercise = Exercise(
            id: _importId('exercise|$nameKey'),
            name: parsed.exerciseName.trim(),
            category: ExerciseCategory.strength,
            muscleGroup: MuscleGroup.fullBody,
            equipmentType: EquipmentType.other,
            isCustom: true,
            updatedAt: parsed.timestamp,
          );
          if (await exerciseRepository.getExercise(exercise.id) == null) {
            try {
              await exerciseRepository.createExercise(exercise);
              exercisesCreated++;
            } catch (_) {
              duplicatesSkipped++;
            }
          } else {
            duplicatesSkipped++;
          }
          byName[nameKey] = exercise;
        }

        final set = WorkoutSet(
          id: _importId(
            '$workoutKey|set|$i|$nameKey|${parsed.weightKg}|${parsed.reps}',
          ),
          workoutId: workoutId,
          exerciseId: exercise.id,
          setOrder: i + 1,
          weight: parsed.weightKg,
          reps: parsed.reps,
          rpe: parsed.rpe,
          timestamp: parsed.timestamp,
          isWarmUp: parsed.isWarmUp,
          updatedAt: parsed.timestamp,
        );

        if (existingSetIds.contains(set.id)) {
          duplicatesSkipped++;
        } else {
          try {
            await workoutRepository.addSet(set);
            setsImported++;
          } catch (_) {
            duplicatesSkipped++;
            continue;
          }
        }
        if (!set.isWarmUp) {
          setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
        }
      }
    }

    prsImported = await _backfillPersonalRecords(setsByExercise);

    return ImportResult(
      workoutsImported: workoutsImported,
      setsImported: setsImported,
      exercisesCreated: exercisesCreated,
      rowsSkipped: history.rowsSkipped,
      duplicatesSkipped: duplicatesSkipped,
      personalRecordsImported: prsImported,
    );
  }

  /// Creates PR rows where the imported history strictly beats the stored
  /// all-time best, dated to the historical set that achieved them. Strict
  /// comparison makes a re-run a no-op.
  Future<int> _backfillPersonalRecords(
    Map<String, List<WorkoutSet>> setsByExercise,
  ) async {
    var created = 0;
    for (final entry in setsByExercise.entries) {
      final candidates = <(RecordType, WorkoutSet, double)>[];
      for (final set in entry.value) {
        candidates.addAll([
          (RecordType.estimatedOneRepMax, set, set.estimatedOneRepMax),
          (RecordType.maxWeight, set, set.weight),
          (RecordType.maxReps, set, set.reps.toDouble()),
          (RecordType.maxVolume, set, set.volume),
        ]);
      }

      for (final type in RecordType.values) {
        final ofType = candidates.where((c) => c.$1 == type).toList();
        if (ofType.isEmpty) continue;
        ofType.sort((a, b) => b.$3.compareTo(a.$3));
        final (_, bestSet, bestValue) = ofType.first;

        final stored = await personalRecordRepository.getBestRecord(
          entry.key,
          type,
          kSelfClientId,
        );
        if (stored != null && stored.value >= bestValue) continue;

        try {
          await personalRecordRepository.createRecord(PersonalRecord(
            id: _importId('pr|${entry.key}|${type.name}|$bestValue'),
            exerciseId: entry.key,
            recordType: type,
            value: bestValue,
            achievedAt: bestSet.timestamp,
            workoutSetId: bestSet.id,
            clientId: kSelfClientId,
            updatedAt: bestSet.timestamp,
          ));
          created++;
        } catch (_) {
          // Duplicate record id — already backfilled.
        }
      }
    }
    return created;
  }
}
