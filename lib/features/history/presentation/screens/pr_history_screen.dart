import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../domain/models/personal_record.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../../core/providers.dart';
import '../../../../core/extensions/datetime_extensions.dart';

class _PrsByExercise {
  final String exerciseName;
  final List<PersonalRecord> records;

  const _PrsByExercise({
    required this.exerciseName,
    required this.records,
  });
}

final _prHistoryProvider =
    FutureProvider.autoDispose<List<_PrsByExercise>>((ref) async {
  final prRepo = ref.watch(personalRecordRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final allRecords = await prRepo.getAllRecords(limit: 500);
  final allExercises = await exerciseRepo.getAllExercises();
  final exercisesById = <String, Exercise>{
    for (final e in allExercises) e.id: e,
  };

  final grouped = <String, List<PersonalRecord>>{};
  for (final record in allRecords) {
    grouped.putIfAbsent(record.exerciseId, () => []).add(record);
  }

  return grouped.entries.map((entry) {
    final name = exercisesById[entry.key]?.name ?? entry.key;
    return _PrsByExercise(exerciseName: name, records: entry.value);
  }).toList();
});

class PrHistoryScreen extends ConsumerWidget {
  const PrHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final dataAsync = ref.watch(_prHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.prHistoryTitle)),
      body: dataAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.prHistoryEmpty,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.prHistoryEmptySubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _ExercisePrCard(
                exerciseName: group.exerciseName,
                records: group.records,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
      ),
    );
  }
}

class _ExercisePrCard extends StatelessWidget {
  const _ExercisePrCard({
    required this.exerciseName,
    required this.records,
  });

  final String exerciseName;
  final List<PersonalRecord> records;

  String _recordTypeLabel(S s, RecordType type) {
    switch (type) {
      case RecordType.maxWeight:
        return s.prTypeWeight;
      case RecordType.maxReps:
        return s.prTypeReps;
      case RecordType.maxVolume:
        return s.prTypeVolume;
      case RecordType.estimatedOneRepMax:
        return s.prTypeE1rm;
    }
  }

  String _formattedValue(S s, RecordType type, double value) {
    final formatted = value.toStringAsFixed(1);
    switch (type) {
      case RecordType.maxWeight:
        return s.prValueWeight(formatted);
      case RecordType.maxReps:
        return s.prValueReps(value.round().toString());
      case RecordType.maxVolume:
        return s.prValueVolume(formatted);
      case RecordType.estimatedOneRepMax:
        return s.prValueE1rm(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exerciseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final record in records)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _recordTypeLabel(s, record.recordType),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      _formattedValue(s, record.recordType, record.value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.prAchievedOn(record.achievedAt.toLocal().relativeLabel),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
