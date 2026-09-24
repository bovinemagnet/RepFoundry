import 'models/exercise.dart';

enum ExerciseSortOrder { mostUsed, alphabetical }

/// Orders [exercises] for the exercise picker.
///
/// Exercises in [sessionExerciseIds] (already part of the current workout) sink
/// to the bottom. Within each group, [ExerciseSortOrder.mostUsed] ranks by
/// [usageCounts] descending; ties and [ExerciseSortOrder.alphabetical] fall back
/// to name order.
List<Exercise> sortExercisesForPicker(
  List<Exercise> exercises, {
  required ExerciseSortOrder order,
  Map<String, int> usageCounts = const {},
  Set<String> sessionExerciseIds = const {},
}) {
  int inSession(Exercise e) => sessionExerciseIds.contains(e.id) ? 1 : 0;
  int usage(Exercise e) =>
      order == ExerciseSortOrder.mostUsed ? usageCounts[e.id] ?? 0 : 0;

  return [...exercises]..sort((a, b) {
      final bySession = inSession(a) - inSession(b);
      if (bySession != 0) return bySession;
      final byUsage = usage(b) - usage(a);
      if (byUsage != 0) return byUsage;
      return a.name.compareTo(b.name);
    });
}
