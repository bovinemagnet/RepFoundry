import '../models/exercise.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> getAllExercises();
  Future<List<Exercise>> searchExercises(String query);
  Future<List<Exercise>> getExercisesByMuscleGroup(MuscleGroup muscleGroup);
  Future<Exercise?> getExercise(String id);
  Future<Exercise> createExercise(Exercise exercise);
  Future<Exercise> updateExercise(Exercise exercise);
  Future<void> deleteExercise(String id);

  Stream<List<Exercise>> watchAllExercises();
}
