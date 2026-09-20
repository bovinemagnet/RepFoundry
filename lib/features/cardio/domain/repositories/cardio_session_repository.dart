import '../models/cardio_heart_rate_sample.dart';
import '../models/cardio_session.dart';
import '../models/cardio_track_point.dart';

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

  /// Recordings captured during the session, kept so it can be reviewed
  /// and exported afterwards. Reads return points in timestamp order.
  Future<void> saveTrackPoints(String sessionId, List<CardioTrackPoint> points);
  Future<List<CardioTrackPoint>> getTrackPoints(String sessionId);
  Future<void> saveHeartRateSamples(
    String sessionId,
    List<CardioHeartRateSample> samples,
  );
  Future<List<CardioHeartRateSample>> getHeartRateSamples(String sessionId);
}
