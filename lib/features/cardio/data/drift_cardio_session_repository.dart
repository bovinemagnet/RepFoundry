import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/cardio_session.dart';
import '../domain/repositories/cardio_session_repository.dart';

class DriftCardioSessionRepository implements CardioSessionRepository {
  final db.AppDatabase _db;

  DriftCardioSessionRepository(this._db);

  @override
  Future<CardioSession> createSession(CardioSession session) async {
    await _db.into(_db.cardioSessions).insert(
          db.CardioSessionsCompanion.insert(
            id: session.id,
            workoutId: session.workoutId,
            exerciseId: session.exerciseId,
            durationSeconds: session.durationSeconds,
            distanceMeters: Value(session.distanceMeters),
            incline: Value(session.incline),
            avgHeartRate: Value(session.avgHeartRate),
            updatedAt: Value(dateTimeToEpochMs(session.updatedAt)),
          ),
        );
    return session;
  }

  @override
  Future<CardioSession?> getSession(String id) async {
    final q = _db.select(_db.cardioSessions)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<CardioSession>> getSessionsForWorkout(String workoutId) async {
    final q = _db.select(_db.cardioSessions)
      ..where((t) => t.workoutId.equals(workoutId) & t.deletedAt.isNull());
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<CardioSession>> getSessionsForExercise(
    String exerciseId, {
    int limit = 50,
  }) async {
    final q = _db.select(_db.cardioSessions)
      ..where((t) => t.exerciseId.equals(exerciseId) & t.deletedAt.isNull())
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<CardioSession>> getAllSessions() async {
    final q = _db.select(_db.cardioSessions)
      ..where((t) => t.deletedAt.isNull());
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<CardioSession?> getLastSessionForExercise(String exerciseId) async {
    final q = _db.select(_db.cardioSessions).join([
      innerJoin(
        _db.workouts,
        _db.workouts.id.equalsExp(_db.cardioSessions.workoutId),
      ),
    ])
      ..where(_db.cardioSessions.exerciseId.equals(exerciseId) &
          _db.cardioSessions.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(_db.workouts.startedAt)])
      ..limit(1);
    final rows = await q.get();
    if (rows.isEmpty) return null;
    return _toDomain(rows.first.readTable(_db.cardioSessions));
  }

  @override
  Future<void> deleteSession(String id) async {
    final now = dateTimeToEpochMs(DateTime.now().toUtc());
    await (_db.update(_db.cardioSessions)..where((t) => t.id.equals(id)))
        .write(db.CardioSessionsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  @override
  Stream<List<CardioSession>> watchSessionsForWorkout(String workoutId) {
    final q = _db.select(_db.cardioSessions)
      ..where((t) => t.workoutId.equals(workoutId) & t.deletedAt.isNull());
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  CardioSession _toDomain(db.CardioSession row) {
    return CardioSession(
      id: row.id,
      workoutId: row.workoutId,
      exerciseId: row.exerciseId,
      durationSeconds: row.durationSeconds,
      distanceMeters: row.distanceMeters,
      incline: row.incline,
      avgHeartRate: row.avgHeartRate,
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }
}
