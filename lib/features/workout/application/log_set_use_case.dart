import '../domain/models/workout_set.dart';
import '../domain/repositories/workout_repository.dart';
import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';

class LogSetResult {
  final WorkoutSet set;
  final List<PersonalRecord> newPersonalRecords;

  const LogSetResult({required this.set, this.newPersonalRecords = const []});
}

class LogSetInput {
  final String workoutId;
  final String exerciseId;
  final int setOrder;
  final double weight;
  final int reps;
  final double? rpe;
  final bool isWarmUp;

  const LogSetInput({
    required this.workoutId,
    required this.exerciseId,
    required this.setOrder,
    required this.weight,
    required this.reps,
    this.rpe,
    this.isWarmUp = false,
  });
}

class LogSetException implements Exception {
  final String message;
  const LogSetException(this.message);

  @override
  String toString() => 'LogSetException: $message';
}

class LogSetUseCase {
  final WorkoutRepository _workoutRepository;
  final PersonalRecordRepository? _personalRecordRepository;

  const LogSetUseCase({
    required WorkoutRepository workoutRepository,
    PersonalRecordRepository? personalRecordRepository,
  })  : _workoutRepository = workoutRepository,
        _personalRecordRepository = personalRecordRepository;

  Future<LogSetResult> execute(LogSetInput input) async {
    _validate(input);

    final set = WorkoutSet.create(
      workoutId: input.workoutId,
      exerciseId: input.exerciseId,
      setOrder: input.setOrder,
      weight: input.weight,
      reps: input.reps,
      rpe: input.rpe,
      isWarmUp: input.isWarmUp,
    );

    final savedSet = await _workoutRepository.addSet(set);

    // Warm-up sets do not count towards personal records.
    final prs = input.isWarmUp
        ? <PersonalRecord>[]
        : await _checkForPersonalRecords(savedSet);

    for (final pr in prs) {
      await _personalRecordRepository?.createRecord(pr);
    }

    return LogSetResult(set: savedSet, newPersonalRecords: prs);
  }

  void _validate(LogSetInput input) {
    if (input.weight < 0) {
      throw const LogSetException('Weight cannot be negative');
    }
    if (input.reps <= 0) {
      throw const LogSetException('Reps must be greater than zero');
    }
    if (input.rpe != null && (input.rpe! < 1 || input.rpe! > 10)) {
      throw const LogSetException('RPE must be between 1 and 10');
    }
  }

  Future<List<PersonalRecord>> _checkForPersonalRecords(WorkoutSet set) async {
    final repository = _personalRecordRepository;
    // Without a record store there is no authoritative all-time best to
    // compare against, so PR detection is skipped.
    if (repository == null) return const [];

    final candidates = <(RecordType, double)>[
      (RecordType.estimatedOneRepMax, set.estimatedOneRepMax),
      (RecordType.maxWeight, set.weight),
      (RecordType.maxReps, set.reps.toDouble()),
      (RecordType.maxVolume, set.volume),
    ];

    final records = <PersonalRecord>[];
    for (final (recordType, value) in candidates) {
      final best = await repository.getBestRecord(set.exerciseId, recordType);
      if (best == null || value > best.value) {
        records.add(PersonalRecord.create(
          exerciseId: set.exerciseId,
          recordType: recordType,
          value: value,
          workoutSetId: set.id,
        ));
      }
    }

    return records;
  }
}
