import 'dart:async';

import '../domain/models/personal_record.dart';
import '../domain/repositories/personal_record_repository.dart';

/// In-memory implementation for use-case tests.
class InMemoryPersonalRecordRepository implements PersonalRecordRepository {
  final List<PersonalRecord> _records = [];
  final _controller = StreamController<void>.broadcast();

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) async {
    _records.add(record);
    _controller.add(null);
    return record;
  }

  @override
  Future<List<PersonalRecord>> getRecordsForExercise(
    String exerciseId,
    String clientId,
  ) async {
    return _records
        .where((r) => r.exerciseId == exerciseId && r.clientId == clientId)
        .toList();
  }

  @override
  Future<PersonalRecord?> getBestRecord(
    String exerciseId,
    RecordType recordType,
    String clientId,
  ) async {
    final matching = _records
        .where(
          (r) =>
              r.exerciseId == exerciseId &&
              r.recordType == recordType &&
              r.clientId == clientId,
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return matching.firstOrNull;
  }

  @override
  Future<List<PersonalRecord>> getAllRecords({
    required String clientId,
    int limit = 50,
  }) async {
    final sorted = _records.where((r) => r.clientId == clientId).toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return sorted.take(limit).toList();
  }

  @override
  Stream<List<PersonalRecord>> watchRecordsForExercise(String exerciseId) {
    return _controller.stream.map(
      (_) => _records.where((r) => r.exerciseId == exerciseId).toList(),
    );
  }
}
