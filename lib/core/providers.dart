import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/exercises/data/exercise_repository_impl.dart';
import '../features/exercises/domain/repositories/exercise_repository.dart';
import '../features/workout/data/workout_repository_impl.dart';
import '../features/workout/domain/repositories/workout_repository.dart';
import '../features/workout/application/log_set_use_case.dart';
import '../features/workout/application/start_workout_use_case.dart';
import '../features/history/application/calculate_progress_use_case.dart';

// Repositories
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return InMemoryExerciseRepository();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return InMemoryWorkoutRepository();
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
