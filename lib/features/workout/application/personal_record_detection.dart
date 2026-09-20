import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../domain/models/workout_set.dart';

/// Returns the records [set] beats against the stored all-time bests for
/// [clientId]. Shared by set logging and set revision so both agree on what
/// counts as a personal record.
Future<List<PersonalRecord>> detectPersonalRecords({
  required WorkoutSet set,
  required String clientId,
  required PersonalRecordRepository repository,
}) async {
  final candidates = <(RecordType, double)>[
    (RecordType.estimatedOneRepMax, set.estimatedOneRepMax),
    (RecordType.maxWeight, set.weight),
    (RecordType.maxReps, set.reps.toDouble()),
    (RecordType.maxVolume, set.volume),
  ];

  final records = <PersonalRecord>[];
  for (final (recordType, value) in candidates) {
    final best = await repository.getBestRecord(
      set.exerciseId,
      recordType,
      clientId,
    );
    if (best == null || value > best.value) {
      records.add(PersonalRecord.create(
        exerciseId: set.exerciseId,
        recordType: recordType,
        value: value,
        workoutSetId: set.id,
        clientId: clientId,
      ));
    }
  }

  return records;
}
