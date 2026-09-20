import 'dart:async';

import '../domain/models/cardio_heart_rate_sample.dart';
import '../domain/models/cardio_session.dart';
import '../domain/models/cardio_track_point.dart';
import '../domain/repositories/cardio_session_repository.dart';

/// In-memory implementation for use-case tests.
class InMemoryCardioSessionRepository implements CardioSessionRepository {
  final List<CardioSession> _sessions = [];
  final Map<String, List<CardioTrackPoint>> _trackPoints = {};
  final Map<String, List<CardioHeartRateSample>> _heartRateSamples = {};
  final _controller = StreamController<void>.broadcast();

  @override
  Future<void> saveTrackPoints(
    String sessionId,
    List<CardioTrackPoint> points,
  ) async {
    (_trackPoints[sessionId] ??= []).addAll(points);
  }

  @override
  Future<List<CardioTrackPoint>> getTrackPoints(String sessionId) async {
    return [...?_trackPoints[sessionId]]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<void> saveHeartRateSamples(
    String sessionId,
    List<CardioHeartRateSample> samples,
  ) async {
    (_heartRateSamples[sessionId] ??= []).addAll(samples);
  }

  @override
  Future<List<CardioHeartRateSample>> getHeartRateSamples(
    String sessionId,
  ) async {
    return [...?_heartRateSamples[sessionId]]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<CardioSession> createSession(CardioSession session) async {
    _sessions.add(session);
    _controller.add(null);
    return session;
  }

  @override
  Future<CardioSession?> getSession(String id) async {
    return _sessions.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<List<CardioSession>> getSessionsForWorkout(String workoutId) async {
    return _sessions.where((s) => s.workoutId == workoutId).toList();
  }

  @override
  Future<List<CardioSession>> getSessionsForExercise(
    String exerciseId,
    String clientId,
  ) async {
    return _sessions
        .where((s) => s.exerciseId == exerciseId && s.clientId == clientId)
        .toList();
  }

  @override
  Future<List<CardioSession>> getAllSessions(String clientId) async {
    return List.unmodifiable(
      _sessions.where((s) => s.clientId == clientId),
    );
  }

  @override
  Future<CardioSession?> getLastSessionForExercise(
    String exerciseId,
    String clientId,
  ) async {
    final matching = _sessions
        .where((s) => s.exerciseId == exerciseId && s.clientId == clientId)
        .toList();
    if (matching.isEmpty) return null;
    return matching.last;
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    _controller.add(null);
  }

  @override
  Stream<List<CardioSession>> watchSessionsForWorkout(String workoutId) {
    return _controller.stream.map(
      (_) => _sessions.where((s) => s.workoutId == workoutId).toList(),
    );
  }
}
