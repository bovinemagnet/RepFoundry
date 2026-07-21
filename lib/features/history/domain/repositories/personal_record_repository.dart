import '../models/personal_record.dart';

abstract class PersonalRecordRepository {
  Future<PersonalRecord> createRecord(PersonalRecord record);
  Future<List<PersonalRecord>> getRecordsForExercise(
    String exerciseId,
    String clientId,
  );
  Future<PersonalRecord?> getBestRecord(
    String exerciseId,
    RecordType recordType,
    String clientId,
  );
  Future<List<PersonalRecord>> getAllRecords({
    required String clientId,
    int limit = 50,
  });

  Stream<List<PersonalRecord>> watchRecordsForExercise(String exerciseId);
}
