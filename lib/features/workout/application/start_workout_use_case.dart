import '../../clients/domain/models/client.dart';
import '../domain/models/workout.dart';
import '../domain/repositories/workout_repository.dart';

class StartWorkoutUseCase {
  final WorkoutRepository _workoutRepository;

  const StartWorkoutUseCase({required WorkoutRepository workoutRepository})
      : _workoutRepository = workoutRepository;

  Future<Workout> execute({
    String? templateId,
    String? notes,
    String clientId = kSelfClientId,
  }) async {
    final existing = await _workoutRepository.getActiveWorkout();
    if (existing != null) return existing;

    final workout = Workout.create(
      templateId: templateId,
      notes: notes,
      clientId: clientId,
    );
    return _workoutRepository.createWorkout(workout);
  }
}
