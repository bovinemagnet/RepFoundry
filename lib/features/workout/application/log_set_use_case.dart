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

  const LogSetInput({
    required this.workoutId,
    required this.exerciseId,
    required this.setOrder,
    required this.weight,
    required this.reps,
    this.rpe,
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
    );

    final savedSet = await _workoutRepository.addSet(set);
    final prs = await _checkForPersonalRecords(savedSet);

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
    final previousSets = await _workoutRepository.getSetsForExercise(
      set.exerciseId,
      limit: 100,
    );

    final others = previousSets.where((s) => s.id != set.id);
    final records = <PersonalRecord>[];

    // e1RM PR
    final bestE1rm = others.fold<double>(
      0,
      (max, s) => s.estimatedOneRepMax > max ? s.estimatedOneRepMax : max,
    );
    if (set.estimatedOneRepMax > bestE1rm) {
      records.add(PersonalRecord.create(
        exerciseId: set.exerciseId,
        recordType: RecordType.estimatedOneRepMax,
        value: set.estimatedOneRepMax,
        workoutSetId: set.id,
      ));
    }

    // Max weight PR
    final bestWeight = others.fold<double>(
      0,
      (max, s) => s.weight > max ? s.weight : max,
    );
    if (set.weight > bestWeight) {
      records.add(PersonalRecord.create(
        exerciseId: set.exerciseId,
        recordType: RecordType.maxWeight,
        value: set.weight,
        workoutSetId: set.id,
      ));
    }

    // Max reps PR
    final bestReps = others.fold<int>(
      0,
      (max, s) => s.reps > max ? s.reps : max,
    );
    if (set.reps > bestReps) {
      records.add(PersonalRecord.create(
        exerciseId: set.exerciseId,
        recordType: RecordType.maxReps,
        value: set.reps.toDouble(),
        workoutSetId: set.id,
      ));
    }

    // Max volume PR
    final bestVolume = others.fold<double>(
      0,
      (max, s) => s.volume > max ? s.volume : max,
    );
    if (set.volume > bestVolume) {
      records.add(PersonalRecord.create(
        exerciseId: set.exerciseId,
        recordType: RecordType.maxVolume,
        value: set.volume,
        workoutSetId: set.id,
      ));
    }

    return records;
  }
}
