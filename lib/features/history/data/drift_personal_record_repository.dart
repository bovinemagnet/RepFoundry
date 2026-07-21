import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/personal_record.dart';
import '../domain/repositories/personal_record_repository.dart';

class DriftPersonalRecordRepository implements PersonalRecordRepository {
  final db.AppDatabase _db;

  DriftPersonalRecordRepository(this._db);

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) async {
    await _db.into(_db.personalRecords).insert(
          db.PersonalRecordsCompanion.insert(
            id: record.id,
            exerciseId: record.exerciseId,
            recordType: record.recordType.name,
            value: record.value,
            achievedAt: dateTimeToEpochMs(record.achievedAt),
            workoutSetId: Value(record.workoutSetId),
            clientId: Value(record.clientId),
            updatedAt: Value(dateTimeToEpochMs(record.updatedAt)),
          ),
        );
    return record;
  }

  @override
  Future<List<PersonalRecord>> getRecordsForExercise(
    String exerciseId,
    String clientId,
  ) async {
    final q = _db.select(_db.personalRecords)
      ..where((t) =>
          t.exerciseId.equals(exerciseId) &
          t.clientId.equals(clientId) &
          t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<PersonalRecord?> getBestRecord(
    String exerciseId,
    RecordType recordType,
    String clientId,
  ) async {
    final q = _db.select(_db.personalRecords)
      ..where(
        (t) =>
            t.exerciseId.equals(exerciseId) &
            t.recordType.equals(recordType.name) &
            t.clientId.equals(clientId) &
            t.deletedAt.isNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.value)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<PersonalRecord>> getAllRecords({
    required String clientId,
    int limit = 50,
  }) async {
    final q = _db.select(_db.personalRecords)
      ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<PersonalRecord>> watchRecordsForExercise(String exerciseId) {
    final q = _db.select(_db.personalRecords)
      ..where((t) => t.exerciseId.equals(exerciseId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  PersonalRecord _toDomain(db.PersonalRecord row) {
    return PersonalRecord(
      id: row.id,
      exerciseId: row.exerciseId,
      recordType: enumFromString(RecordType.values, row.recordType),
      value: row.value,
      achievedAt: dateTimeFromEpochMs(row.achievedAt),
      workoutSetId: row.workoutSetId,
      clientId: row.clientId,
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }
}
