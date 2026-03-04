import '../models/personal_record.dart';

abstract class PersonalRecordRepository {
  Future<PersonalRecord> createRecord(PersonalRecord record);
  Future<List<PersonalRecord>> getRecordsForExercise(
    String exerciseId, {
    RecordType? recordType,
  });
  Future<PersonalRecord?> getBestRecord(
    String exerciseId,
    RecordType recordType,
  );
  Future<List<PersonalRecord>> getAllRecords({int limit = 50});

  Stream<List<PersonalRecord>> watchRecordsForExercise(String exerciseId);
}
