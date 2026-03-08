import '../models/cardio_session.dart';

abstract class CardioSessionRepository {
  Future<CardioSession> createSession(CardioSession session);
  Future<CardioSession?> getSession(String id);
  Future<List<CardioSession>> getSessionsForWorkout(String workoutId);
  Future<List<CardioSession>> getSessionsForExercise(
    String exerciseId, {
    int limit = 50,
  });
  Future<void> deleteSession(String id);

  Future<List<CardioSession>> getAllSessions();
  Future<CardioSession?> getLastSessionForExercise(String exerciseId);

  Stream<List<CardioSession>> watchSessionsForWorkout(String workoutId);
}
