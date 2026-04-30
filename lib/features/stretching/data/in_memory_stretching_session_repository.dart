import 'dart:async';

import '../domain/models/stretching_session.dart';
import '../domain/repositories/stretching_session_repository.dart';

/// In-memory implementation for use-case and controller tests.
class InMemoryStretchingSessionRepository
    implements StretchingSessionRepository {
  final List<StretchingSession> _sessions = [];
  final _controller = StreamController<void>.broadcast();

  List<StretchingSession> _live() =>
      _sessions.where((s) => !s.isDeleted).toList();

  @override
  Future<StretchingSession> createSession(StretchingSession session) async {
    _sessions.add(session);
    _controller.add(null);
    return session;
  }

  @override
  Future<StretchingSession?> getSession(String id) async {
    return _live().where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<List<StretchingSession>> getSessionsForWorkout(
    String workoutId,
  ) async {
    return _live().where((s) => s.workoutId == workoutId).toList();
  }

  @override
  Future<List<StretchingSession>> getRecentSessions({int limit = 20}) async {
    final live = _live();
    live.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return live.take(limit).toList();
  }

  @override
  Future<List<StretchingSession>> getSessionsByType(
    String type, {
    int limit = 50,
  }) async {
    return _live().where((s) => s.type == type).take(limit).toList();
  }

  @override
  Future<StretchingSession> updateSession(StretchingSession session) async {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx == -1) throw StateError('Stretching session not found');
    _sessions[idx] = session;
    _controller.add(null);
    return session;
  }

  @override
  Future<void> deleteSession(String id) async {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _sessions[idx] = _sessions[idx].copyWith(
      deletedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    _controller.add(null);
  }

  @override
  Stream<List<StretchingSession>> watchSessionsForWorkout(String workoutId) {
    Future.microtask(() => _controller.add(null));
    return _controller.stream.map(
      (_) => _live().where((s) => s.workoutId == workoutId).toList(),
    );
  }
}
