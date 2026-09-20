import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/cardio_heart_rate_sample.dart';
import '../domain/models/cardio_session.dart';
import '../domain/models/cardio_track_point.dart';
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
            clientId: Value(session.clientId),
            updatedAt: Value(dateTimeToEpochMs(session.updatedAt)),
          ),
        );
    return session;
  }

  @override
  Future<void> saveTrackPoints(
    String sessionId,
    List<CardioTrackPoint> points,
  ) async {
    await _db.batch((b) {
      b.insertAll(_db.cardioTrackPoints, [
        for (final p in points)
          db.CardioTrackPointsCompanion.insert(
            id: const Uuid().v4(),
            sessionId: sessionId,
            timestamp: dateTimeToEpochMs(p.timestamp),
            latitude: p.latitude,
            longitude: p.longitude,
            altitude: Value(p.altitude),
            accuracy: Value(p.accuracy),
          ),
      ]);
    });
  }

  @override
  Future<List<CardioTrackPoint>> getTrackPoints(String sessionId) async {
    final q = _db.select(_db.cardioTrackPoints)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    final rows = await q.get();
    return [
      for (final r in rows)
        CardioTrackPoint(
          timestamp: dateTimeFromEpochMs(r.timestamp),
          latitude: r.latitude,
          longitude: r.longitude,
          altitude: r.altitude,
          accuracy: r.accuracy,
        ),
    ];
  }

  @override
  Future<void> saveHeartRateSamples(
    String sessionId,
    List<CardioHeartRateSample> samples,
  ) async {
    await _db.batch((b) {
      b.insertAll(_db.cardioHeartRateSamples, [
        for (final s in samples)
          db.CardioHeartRateSamplesCompanion.insert(
            id: const Uuid().v4(),
            sessionId: sessionId,
            timestamp: dateTimeToEpochMs(s.timestamp),
            bpm: s.bpm,
          ),
      ]);
    });
  }

  @override
  Future<List<CardioHeartRateSample>> getHeartRateSamples(
    String sessionId,
  ) async {
    final q = _db.select(_db.cardioHeartRateSamples)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    final rows = await q.get();
    return [
      for (final r in rows)
        CardioHeartRateSample(
          timestamp: dateTimeFromEpochMs(r.timestamp),
          bpm: r.bpm,
        ),
    ];
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
    String exerciseId,
    String clientId,
  ) async {
    final q = _db.select(_db.cardioSessions)
      ..where((t) =>
          t.exerciseId.equals(exerciseId) &
          t.clientId.equals(clientId) &
          t.deletedAt.isNull());
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<CardioSession>> getAllSessions(String clientId) async {
    final q = _db.select(_db.cardioSessions)
      ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull());
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<CardioSession?> getLastSessionForExercise(
    String exerciseId,
    String clientId,
  ) async {
    final q = _db.select(_db.cardioSessions).join([
      innerJoin(
        _db.workouts,
        _db.workouts.id.equalsExp(_db.cardioSessions.workoutId),
      ),
    ])
      ..where(_db.cardioSessions.exerciseId.equals(exerciseId) &
          _db.cardioSessions.clientId.equals(clientId) &
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
      clientId: row.clientId,
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }
}
