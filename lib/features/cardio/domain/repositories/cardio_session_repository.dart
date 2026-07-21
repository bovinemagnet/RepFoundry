import '../models/cardio_session.dart';

abstract class CardioSessionRepository {
  Future<CardioSession> createSession(CardioSession session);
  Future<CardioSession?> getSession(String id);
  Future<List<CardioSession>> getSessionsForWorkout(String workoutId);
  Future<List<CardioSession>> getSessionsForExercise(
    String exerciseId,
    String clientId,
  );
  Future<void> deleteSession(String id);

  Future<List<CardioSession>> getAllSessions(String clientId);
  Future<CardioSession?> getLastSessionForExercise(
    String exerciseId,
    String clientId,
  );

  Stream<List<CardioSession>> watchSessionsForWorkout(String workoutId);
}
