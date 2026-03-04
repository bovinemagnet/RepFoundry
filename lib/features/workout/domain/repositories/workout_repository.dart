import '../models/workout.dart';
import '../models/workout_set.dart';

abstract class WorkoutRepository {
  Future<Workout> createWorkout(Workout workout);
  Future<Workout?> getWorkout(String id);
  Future<Workout?> getActiveWorkout();
  Future<List<Workout>> getWorkoutHistory({int limit = 20, DateTime? before});
  Future<Workout> updateWorkout(Workout workout);
  Future<void> deleteWorkout(String id);

  Future<WorkoutSet> addSet(WorkoutSet set);
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId);
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    int limit = 50,
  });
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId);
  Future<void> deleteSet(String setId);

  Stream<List<Workout>> watchWorkoutHistory();
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId);
}
