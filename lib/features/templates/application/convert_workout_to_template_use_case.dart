import 'package:uuid/uuid.dart';

import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../workout/domain/models/workout_set.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../domain/models/workout_template.dart';
import '../domain/repositories/workout_template_repository.dart';

class ConvertWorkoutToTemplateException implements Exception {
  final String message;
  const ConvertWorkoutToTemplateException(this.message);

  @override
  String toString() => 'ConvertWorkoutToTemplateException: $message';
}

/// Converts a logged workout into a reusable [WorkoutTemplate].
///
/// Groups the workout's sets by exercise (preserving the order each exercise
/// first appears) and derives planning metadata: [TemplateExercise.targetSets]
/// is the number of working sets logged for that exercise, and
/// [TemplateExercise.targetReps] is the most common rep count among them.
class ConvertWorkoutToTemplateUseCase {
  final WorkoutRepository _workoutRepository;
  final ExerciseRepository _exerciseRepository;
  final WorkoutTemplateRepository _templateRepository;

  const ConvertWorkoutToTemplateUseCase({
    required WorkoutRepository workoutRepository,
    required ExerciseRepository exerciseRepository,
    required WorkoutTemplateRepository templateRepository,
  })  : _workoutRepository = workoutRepository,
        _exerciseRepository = exerciseRepository,
        _templateRepository = templateRepository;

  Future<WorkoutTemplate> execute({
    required String workoutId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ConvertWorkoutToTemplateException('Name cannot be empty');
    }

    final workout = await _workoutRepository.getWorkout(workoutId);
    if (workout == null) {
      throw const ConvertWorkoutToTemplateException('Workout not found');
    }

    final sets = await _workoutRepository.getSetsForWorkout(workoutId);
    if (sets.isEmpty) {
      throw const ConvertWorkoutToTemplateException('Workout has no sets');
    }

    final Map<String, List<WorkoutSet>> byExercise = {};
    for (final set in sets) {
      byExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    final exercises = await _exerciseRepository.getAllExercises();
    final exercisesById = {for (final e in exercises) e.id: e};

    final now = DateTime.now().toUtc();
    final templateId = const Uuid().v4();

    var orderIndex = 0;
    final templateExercises = <TemplateExercise>[];
    for (final entry in byExercise.entries) {
      final exerciseSets = entry.value;
      final working = exerciseSets.where((s) => !s.isWarmUp).toList();
      final counted = working.isNotEmpty ? working : exerciseSets;

      templateExercises.add(
        TemplateExercise(
          id: const Uuid().v4(),
          templateId: templateId,
          exerciseId: entry.key,
          exerciseName: exercisesById[entry.key]?.name ?? entry.key,
          targetSets: counted.length,
          targetReps: _mostCommonReps(counted),
          orderIndex: orderIndex++,
          updatedAt: now,
        ),
      );
    }

    final template = WorkoutTemplate(
      id: templateId,
      name: trimmedName,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );

    return _templateRepository.createTemplate(template);
  }

  /// Returns the most frequent rep count, breaking ties by first occurrence.
  int _mostCommonReps(List<WorkoutSet> sets) {
    final counts = <int, int>{};
    for (final set in sets) {
      counts[set.reps] = (counts[set.reps] ?? 0) + 1;
    }
    var best = sets.first.reps;
    var bestCount = 0;
    for (final set in sets) {
      final count = counts[set.reps]!;
      if (count > bestCount) {
        bestCount = count;
        best = set.reps;
      }
    }
    return best;
  }
}
