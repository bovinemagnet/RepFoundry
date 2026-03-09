import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../history/domain/models/personal_record.dart';

class PrTimelineEntry {
  final PersonalRecord record;
  final String exerciseName;

  const PrTimelineEntry({required this.record, required this.exerciseName});
}

final prTimelineProvider = FutureProvider.autoDispose<List<PrTimelineEntry>>((ref) async {
  final prRepo = ref.watch(personalRecordRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final records = await prRepo.getAllRecords(limit: 200);
  final exercises = await exerciseRepo.getAllExercises();
  final exerciseMap = {for (final e in exercises) e.id: e};

  return records
      .map((r) => PrTimelineEntry(record: r, exerciseName: exerciseMap[r.exerciseId]?.name ?? 'Unknown'))
      .toList()
    ..sort((a, b) => b.record.achievedAt.compareTo(a.record.achievedAt));
});
