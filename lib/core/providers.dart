import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database_provider.dart';
import '../features/exercises/data/drift_exercise_repository.dart';
import '../features/exercises/domain/repositories/exercise_repository.dart';
import '../features/workout/data/drift_workout_repository.dart';
import '../features/workout/domain/repositories/workout_repository.dart';
import '../features/workout/application/log_set_use_case.dart';
import '../features/workout/application/start_workout_use_case.dart';
import '../features/history/application/calculate_progress_use_case.dart';

// Repositories
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return DriftExerciseRepository(ref.watch(databaseProvider));
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return DriftWorkoutRepository(ref.watch(databaseProvider));
});

// Use cases
final logSetUseCaseProvider = Provider<LogSetUseCase>((ref) {
  return LogSetUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
  );
});

final startWorkoutUseCaseProvider = Provider<StartWorkoutUseCase>((ref) {
  return StartWorkoutUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
  );
});

final calculateProgressUseCaseProvider =
    Provider<CalculateProgressUseCase>((ref) {
  return CalculateProgressUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
  );
});
