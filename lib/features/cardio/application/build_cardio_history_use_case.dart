import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../domain/repositories/cardio_session_repository.dart';
import 'cardio_history_entry.dart';

/// Assembles the cardio history for one client: every saved session with
/// its start time and sport name, newest first.
class BuildCardioHistoryUseCase {
  final WorkoutRepository _workoutRepository;
  final CardioSessionRepository _cardioSessionRepository;
  final ExerciseRepository _exerciseRepository;

  const BuildCardioHistoryUseCase({
    required WorkoutRepository workoutRepository,
    required CardioSessionRepository cardioSessionRepository,
    required ExerciseRepository exerciseRepository,
  })  : _workoutRepository = workoutRepository,
        _cardioSessionRepository = cardioSessionRepository,
        _exerciseRepository = exerciseRepository;

  Future<List<CardioHistoryEntry>> execute({required String clientId}) async {
    final sessions = await _cardioSessionRepository.getAllSessions(clientId);
    if (sessions.isEmpty) return const [];

    final exercises = await _exerciseRepository.getAllExercises();
    final names = {for (final e in exercises) e.id: e.name};

    final entries = <CardioHistoryEntry>[];
    for (final session in sessions) {
      final workout = await _workoutRepository.getWorkout(session.workoutId);
      if (workout == null) continue;
      entries.add(CardioHistoryEntry(
        session: session,
        startedAt: workout.startedAt,
        exerciseName: names[session.exerciseId] ?? session.exerciseId,
      ));
    }
    entries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return entries;
  }
}
