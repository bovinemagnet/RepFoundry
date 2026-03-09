import 'package:uuid/uuid.dart';

enum RecordType {
  estimatedOneRepMax,
  maxWeight,
  maxReps,
  maxVolume,
}

class PersonalRecord {
  final String id;
  final String exerciseId;
  final RecordType recordType;
  final double value;
  final DateTime achievedAt;
  final String? workoutSetId;
  final DateTime updatedAt;

  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.recordType,
    required this.value,
    required this.achievedAt,
    this.workoutSetId,
    required this.updatedAt,
  });

  static PersonalRecord create({
    required String exerciseId,
    required RecordType recordType,
    required double value,
    String? workoutSetId,
  }) {
    final now = DateTime.now().toUtc();
    return PersonalRecord(
      id: const Uuid().v4(),
      exerciseId: exerciseId,
      recordType: recordType,
      value: value,
      achievedAt: now,
      workoutSetId: workoutSetId,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PersonalRecord(exerciseId: $exerciseId, type: $recordType, value: $value)';
}
