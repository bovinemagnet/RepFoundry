import '../models/stretching_session.dart';

abstract class StretchingSessionRepository {
  Future<StretchingSession> createSession(StretchingSession session);
  Future<StretchingSession?> getSession(String id);
  Future<List<StretchingSession>> getSessionsForWorkout(String workoutId);
  Future<List<StretchingSession>> getRecentSessions({int limit = 20});

  /// All non-deleted sessions, used by export-data and similar bulk paths.
  Future<List<StretchingSession>> getAllSessions();

  Future<List<StretchingSession>> getSessionsByType(
    String type, {
    int limit = 50,
  });
  Future<StretchingSession> updateSession(StretchingSession session);

  /// Soft-deletes the session by setting `deletedAt`.
  Future<void> deleteSession(String id);

  Stream<List<StretchingSession>> watchSessionsForWorkout(String workoutId);
}
