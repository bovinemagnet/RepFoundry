import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../domain/models/workout_set.dart';
import '../domain/repositories/workout_repository.dart';
import 'personal_record_detection.dart';

class ReviseSetResult {
  final WorkoutSet set;
  final List<PersonalRecord> newPersonalRecords;

  const ReviseSetResult({
    required this.set,
    this.newPersonalRecords = const [],
  });
}

/// Edits or deletes an already-logged set and keeps personal records honest:
/// the records the old set earned are withdrawn, and an edited set is
/// re-evaluated against the remaining bests. Without this a mistaken entry
/// stays the all-time best after it is corrected or removed.
class ReviseSetUseCase {
  final WorkoutRepository _workoutRepository;
  final PersonalRecordRepository _personalRecordRepository;

  const ReviseSetUseCase({
    required WorkoutRepository workoutRepository,
    required PersonalRecordRepository personalRecordRepository,
  })  : _workoutRepository = workoutRepository,
        _personalRecordRepository = personalRecordRepository;

  Future<ReviseSetResult> update(
    WorkoutSet set, {
    required String clientId,
  }) async {
    final saved = await _workoutRepository.updateSet(set);
    await _personalRecordRepository.deleteRecordsForSet(set.id);

    final prs = set.isWarmUp
        ? <PersonalRecord>[]
        : await detectPersonalRecords(
            set: saved,
            clientId: clientId,
            repository: _personalRecordRepository,
          );
    for (final pr in prs) {
      await _personalRecordRepository.createRecord(pr);
    }
    return ReviseSetResult(set: saved, newPersonalRecords: prs);
  }

  Future<void> delete(String setId) async {
    await _workoutRepository.deleteSet(setId);
    await _personalRecordRepository.deleteRecordsForSet(setId);
  }
}
