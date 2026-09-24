import '../models/workout.dart';
import '../models/workout_set.dart';

abstract class WorkoutRepository {
  Future<Workout> createWorkout(Workout workout);
  Future<Workout?> getWorkout(String id);
  Future<Workout?> getActiveWorkout();
  Future<List<Workout>> getWorkoutHistory({
    required String clientId,
    int limit = 20,
    DateTime? before,
  });
  Future<Workout> updateWorkout(Workout workout);
  Future<void> deleteWorkout(String id);

  Future<WorkoutSet> addSet(WorkoutSet set);
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId);

  /// Returns sets for all [workoutIds] in a single query, grouped by
  /// workout id. Workouts with no sets are omitted from the map.
  Future<Map<String, List<WorkoutSet>>> getSetsForWorkouts(
    List<String> workoutIds,
  );

  /// Sets of [exerciseId] logged by [clientId] under non-deleted workouts,
  /// newest first.
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    required String clientId,
    int limit = 50,
  });
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId);

  /// Maps exercise id → the number of distinct non-deleted workouts owned by
  /// [clientId] that contain a live set of that exercise. Exercises never
  /// logged are omitted.
  Future<Map<String, int>> getExerciseUsageCounts(String clientId);
  Future<WorkoutSet> updateSet(WorkoutSet set);
  Future<void> deleteSet(String setId);
  Future<List<WorkoutSet>> getSetsFromLastSession(
    String exerciseId,
    String clientId,
  );

  Stream<List<Workout>> watchWorkoutHistory(String clientId);
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId);
}
