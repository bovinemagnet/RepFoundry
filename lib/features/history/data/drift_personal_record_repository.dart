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
          ),
        );
    return record;
  }

  @override
  Future<List<PersonalRecord>> getRecordsForExercise(
    String exerciseId, {
    RecordType? recordType,
  }) async {
    final q = _db.select(_db.personalRecords)
      ..where((t) {
        var cond = t.exerciseId.equals(exerciseId);
        if (recordType != null) {
          cond = cond & t.recordType.equals(recordType.name);
        }
        return cond;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<PersonalRecord?> getBestRecord(
    String exerciseId,
    RecordType recordType,
  ) async {
    final q = _db.select(_db.personalRecords)
      ..where(
        (t) =>
            t.exerciseId.equals(exerciseId) &
            t.recordType.equals(recordType.name),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.value)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<PersonalRecord>> getAllRecords({int limit = 50}) async {
    final q = _db.select(_db.personalRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<PersonalRecord>> watchRecordsForExercise(String exerciseId) {
    final q = _db.select(_db.personalRecords)
      ..where((t) => t.exerciseId.equals(exerciseId))
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
    );
  }
}
