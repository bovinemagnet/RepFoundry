import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/stretching_session.dart';
import '../domain/repositories/stretching_session_repository.dart';

class DriftStretchingSessionRepository implements StretchingSessionRepository {
  final db.AppDatabase _db;

  DriftStretchingSessionRepository(this._db);

  @override
  Future<StretchingSession> createSession(StretchingSession session) async {
    await _db.into(_db.stretchingSessions).insert(_toCompanion(session));
    return session;
  }

  @override
  Future<StretchingSession?> getSession(String id) async {
    final q = _db.select(_db.stretchingSessions)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<StretchingSession>> getSessionsForWorkout(
    String workoutId,
  ) async {
    final q = _db.select(_db.stretchingSessions)
      ..where((t) => t.workoutId.equals(workoutId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<StretchingSession>> getRecentSessions({int limit = 20}) async {
    final q = _db.select(_db.stretchingSessions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<StretchingSession>> getAllSessions() async {
    final q = _db.select(_db.stretchingSessions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<StretchingSession>> getSessionsByType(
    String type, {
    int limit = 50,
  }) async {
    final q = _db.select(_db.stretchingSessions)
      ..where((t) => t.type.equals(type) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<StretchingSession> updateSession(StretchingSession session) async {
    await (_db.update(_db.stretchingSessions)
          ..where((t) => t.id.equals(session.id)))
        .write(
      db.StretchingSessionsCompanion(
        type: Value(session.type),
        customName: Value(session.customName),
        bodyArea: Value(session.bodyArea?.name),
        side: Value(session.side?.name),
        durationSeconds: Value(session.durationSeconds),
        startedAt: Value(nullableDateTimeToEpochMs(session.startedAt)),
        endedAt: Value(nullableDateTimeToEpochMs(session.endedAt)),
        entryMethod: Value(session.entryMethod.name),
        notes: Value(session.notes),
        updatedAt: Value(dateTimeToEpochMs(session.updatedAt)),
        deletedAt: Value(nullableDateTimeToEpochMs(session.deletedAt)),
      ),
    );
    return session;
  }

  @override
  Future<void> deleteSession(String id) async {
    final now = dateTimeToEpochMs(DateTime.now().toUtc());
    await (_db.update(_db.stretchingSessions)..where((t) => t.id.equals(id)))
        .write(
      db.StretchingSessionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Stream<List<StretchingSession>> watchSessionsForWorkout(String workoutId) {
    final q = _db.select(_db.stretchingSessions)
      ..where((t) => t.workoutId.equals(workoutId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  db.StretchingSessionsCompanion _toCompanion(StretchingSession s) {
    return db.StretchingSessionsCompanion.insert(
      id: s.id,
      workoutId: s.workoutId,
      type: s.type,
      customName: Value(s.customName),
      bodyArea: Value(s.bodyArea?.name),
      side: Value(s.side?.name),
      durationSeconds: s.durationSeconds,
      startedAt: Value(nullableDateTimeToEpochMs(s.startedAt)),
      endedAt: Value(nullableDateTimeToEpochMs(s.endedAt)),
      entryMethod: s.entryMethod.name,
      notes: Value(s.notes),
      updatedAt: Value(dateTimeToEpochMs(s.updatedAt)),
      deletedAt: Value(nullableDateTimeToEpochMs(s.deletedAt)),
    );
  }

  StretchingSession _toDomain(db.StretchingSession row) {
    return StretchingSession(
      id: row.id,
      workoutId: row.workoutId,
      type: row.type,
      customName: row.customName,
      bodyArea: row.bodyArea == null
          ? null
          : enumFromString(StretchingBodyArea.values, row.bodyArea!),
      side: row.side == null
          ? null
          : enumFromString(StretchingSide.values, row.side!),
      durationSeconds: row.durationSeconds,
      startedAt: nullableDateTimeFromEpochMs(row.startedAt),
      endedAt: nullableDateTimeFromEpochMs(row.endedAt),
      entryMethod: enumFromString(
        StretchingEntryMethod.values,
        row.entryMethod,
      ),
      notes: row.notes,
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }
}
