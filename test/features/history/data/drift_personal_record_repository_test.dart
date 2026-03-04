import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/history/data/drift_personal_record_repository.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';

void main() {
  late db.AppDatabase database;
  late DriftPersonalRecordRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftPersonalRecordRepository(database);
  });

  tearDown(() => database.close());

  PersonalRecord newRecord({
    String exerciseId = '1', // Barbell Bench Press (seeded)
    RecordType recordType = RecordType.estimatedOneRepMax,
    double value = 120.0,
    String? workoutSetId,
  }) {
    return PersonalRecord.create(
      exerciseId: exerciseId,
      recordType: recordType,
      value: value,
      workoutSetId: workoutSetId,
    );
  }

  group('DriftPersonalRecordRepository', () {
    group('createRecord & getRecordsForExercise', () {
      test('persists and retrieves a record', () async {
        final record = newRecord();
        await repo.createRecord(record);

        final records = await repo.getRecordsForExercise('1');
        expect(records, hasLength(1));
        expect(records.first.id, record.id);
        expect(records.first.exerciseId, '1');
        expect(records.first.recordType, RecordType.estimatedOneRepMax);
        expect(records.first.value, 120.0);
      });

      test('filters by recordType', () async {
        await repo.createRecord(newRecord(
          recordType: RecordType.estimatedOneRepMax,
          value: 120,
        ));
        await repo.createRecord(newRecord(
          recordType: RecordType.maxWeight,
          value: 100,
        ));

        final e1rmRecords = await repo.getRecordsForExercise(
          '1',
          recordType: RecordType.estimatedOneRepMax,
        );
        expect(e1rmRecords, hasLength(1));
        expect(
          e1rmRecords.first.recordType,
          RecordType.estimatedOneRepMax,
        );
      });
    });

    group('getBestRecord', () {
      test('returns the highest-value record', () async {
        await repo.createRecord(newRecord(value: 100));
        await repo.createRecord(newRecord(value: 150));
        await repo.createRecord(newRecord(value: 120));

        final best = await repo.getBestRecord(
          '1',
          RecordType.estimatedOneRepMax,
        );
        expect(best, isNotNull);
        expect(best!.value, 150.0);
      });

      test('returns null when no records exist', () async {
        final best = await repo.getBestRecord(
          '1',
          RecordType.estimatedOneRepMax,
        );
        expect(best, isNull);
      });
    });

    group('getAllRecords', () {
      test('returns records newest first with limit', () async {
        for (var i = 0; i < 5; i++) {
          await repo.createRecord(newRecord(value: 100.0 + i));
        }

        final all = await repo.getAllRecords(limit: 3);
        expect(all, hasLength(3));
      });
    });

    group('watchRecordsForExercise', () {
      test('emits when records change', () async {
        final emissions = <List<PersonalRecord>>[];
        final sub = repo.watchRecordsForExercise('1').listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        expect(emissions, hasLength(1));
        expect(emissions.first, isEmpty);

        await repo.createRecord(newRecord());
        await pumpEventQueue();

        expect(emissions.last, hasLength(1));
      });
    });
  });
}
