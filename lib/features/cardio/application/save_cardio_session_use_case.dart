import 'package:uuid/uuid.dart';

import '../domain/models/cardio_session.dart';
import '../domain/repositories/cardio_session_repository.dart';
import '../../workout/domain/models/workout.dart';
import '../../workout/domain/repositories/workout_repository.dart';

class SaveCardioSessionInput {
  final String exerciseId;
  final String exerciseName;
  final int durationSeconds;
  final double? distanceMeters;
  final double? incline;
  final int? avgHeartRate;

  const SaveCardioSessionInput({
    required this.exerciseId,
    required this.exerciseName,
    required this.durationSeconds,
    this.distanceMeters,
    this.incline,
    this.avgHeartRate,
  });
}

class SaveCardioSessionResult {
  final CardioSession session;
  final Workout workout;

  const SaveCardioSessionResult({
    required this.session,
    required this.workout,
  });
}

class SaveCardioSessionException implements Exception {
  final String message;
  const SaveCardioSessionException(this.message);

  @override
  String toString() => 'SaveCardioSessionException: $message';
}

class SaveCardioSessionUseCase {
  final CardioSessionRepository _cardioRepository;
  final WorkoutRepository _workoutRepository;

  const SaveCardioSessionUseCase({
    required CardioSessionRepository cardioRepository,
    required WorkoutRepository workoutRepository,
  })  : _cardioRepository = cardioRepository,
        _workoutRepository = workoutRepository;

  Future<SaveCardioSessionResult> execute(SaveCardioSessionInput input) async {
    _validate(input);

    final now = DateTime.now().toUtc();
    final workout = Workout(
      id: const Uuid().v4(),
      startedAt: now.subtract(Duration(seconds: input.durationSeconds)),
      completedAt: now,
      notes: 'Cardio: ${input.exerciseName}',
    );

    final createdWorkout = await _workoutRepository.createWorkout(workout);

    final session = CardioSession.create(
      workoutId: createdWorkout.id,
      exerciseId: input.exerciseId,
      durationSeconds: input.durationSeconds,
      distanceMeters: input.distanceMeters,
      incline: input.incline,
      avgHeartRate: input.avgHeartRate,
    );

    await _cardioRepository.createSession(session);

    return SaveCardioSessionResult(
      session: session,
      workout: createdWorkout,
    );
  }

  void _validate(SaveCardioSessionInput input) {
    if (input.exerciseId.isEmpty) {
      throw const SaveCardioSessionException('Exercise ID cannot be empty');
    }
    if (input.durationSeconds <= 0) {
      throw const SaveCardioSessionException(
        'Duration must be greater than zero',
      );
    }
    if (input.distanceMeters != null && input.distanceMeters! < 0) {
      throw const SaveCardioSessionException(
        'Distance cannot be negative',
      );
    }
    if (input.avgHeartRate != null &&
        (input.avgHeartRate! < 30 || input.avgHeartRate! > 250)) {
      throw const SaveCardioSessionException(
        'Heart rate must be between 30 and 250',
      );
    }
    if (input.incline != null && input.incline! < 0) {
      throw const SaveCardioSessionException(
        'Incline cannot be negative',
      );
    }
  }
}
