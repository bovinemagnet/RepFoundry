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
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    int limit = 50,
  });
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId);
  Future<WorkoutSet> updateSet(WorkoutSet set);
  Future<void> deleteSet(String setId);
  Future<List<WorkoutSet>> getSetsFromLastSession(
    String exerciseId,
    String clientId,
  );

  Stream<List<Workout>> watchWorkoutHistory(String clientId);
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId);
}
