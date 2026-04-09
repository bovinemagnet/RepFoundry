import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';

void main() {
  group('PersonalRecord', () {
    test('RecordType enum has exactly 4 values', () {
      expect(RecordType.values, hasLength(4));
      expect(
          RecordType.values,
          containsAllInOrder([
            RecordType.estimatedOneRepMax,
            RecordType.maxWeight,
            RecordType.maxReps,
            RecordType.maxVolume,
          ]));
    });

    test(
        'create_withoutWorkoutSetId_idIsNonEmptyAchievedAtIsUtcWorkoutSetIdIsNull',
        () {
      final record = PersonalRecord.create(
        exerciseId: 'ex-1',
        recordType: RecordType.maxWeight,
        value: 100.0,
      );

      expect(record.id, isNotEmpty);
      expect(record.achievedAt.isUtc, isTrue);
      expect(record.updatedAt.isUtc, isTrue);
      expect(record.workoutSetId, isNull);
    });

    test('create_withWorkoutSetId_workoutSetIdIsPreserved', () {
      const setId = 'set-abc-123';

      final record = PersonalRecord.create(
        exerciseId: 'ex-2',
        recordType: RecordType.maxReps,
        value: 20.0,
        workoutSetId: setId,
      );

      expect(record.workoutSetId, equals(setId));
    });

    test('create_calledTwice_producesDifferentIds', () {
      final first = PersonalRecord.create(
        exerciseId: 'ex-1',
        recordType: RecordType.maxVolume,
        value: 500.0,
      );
      final second = PersonalRecord.create(
        exerciseId: 'ex-1',
        recordType: RecordType.maxVolume,
        value: 500.0,
      );

      expect(first.id, isNot(equals(second.id)));
    });

    test('equality_sameId_recordsAreEqual', () {
      const sharedId = 'fixed-id-001';
      final now = DateTime.now().toUtc();

      final a = PersonalRecord(
        id: sharedId,
        exerciseId: 'ex-1',
        recordType: RecordType.maxWeight,
        value: 80.0,
        achievedAt: now,
        updatedAt: now,
      );
      final b = PersonalRecord(
        id: sharedId,
        exerciseId: 'ex-2',
        recordType: RecordType.maxReps,
        value: 15.0,
        achievedAt: now,
        updatedAt: now,
      );

      expect(a, equals(b));
    });

    test('equality_differentId_recordsAreNotEqual', () {
      final now = DateTime.now().toUtc();

      final a = PersonalRecord(
        id: 'id-aaa',
        exerciseId: 'ex-1',
        recordType: RecordType.maxWeight,
        value: 80.0,
        achievedAt: now,
        updatedAt: now,
      );
      final b = PersonalRecord(
        id: 'id-bbb',
        exerciseId: 'ex-1',
        recordType: RecordType.maxWeight,
        value: 80.0,
        achievedAt: now,
        updatedAt: now,
      );

      expect(a, isNot(equals(b)));
    });

    test('hashCode_isBasedOnId', () {
      const fixedId = 'fixed-id-hash';
      final now = DateTime.now().toUtc();

      final record = PersonalRecord(
        id: fixedId,
        exerciseId: 'ex-1',
        recordType: RecordType.estimatedOneRepMax,
        value: 120.0,
        achievedAt: now,
        updatedAt: now,
      );

      expect(record.hashCode, equals(fixedId.hashCode));
    });
  });
}
