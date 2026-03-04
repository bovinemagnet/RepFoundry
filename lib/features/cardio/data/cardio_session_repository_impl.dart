import 'dart:async';

import '../domain/models/cardio_session.dart';
import '../domain/repositories/cardio_session_repository.dart';

/// In-memory implementation for use-case tests.
class InMemoryCardioSessionRepository implements CardioSessionRepository {
  final List<CardioSession> _sessions = [];
  final _controller = StreamController<void>.broadcast();

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
    String exerciseId, {
    int limit = 50,
  }) async {
    return _sessions
        .where((s) => s.exerciseId == exerciseId)
        .take(limit)
        .toList();
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
