import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

/// Provides the last 10 estimated 1RM values for an exercise (oldest → newest).
final exerciseSparklineProvider =
    FutureProvider.autoDispose.family<List<double>, String>(
  (ref, exerciseId) async {
    final repo = ref.watch(workoutRepositoryProvider);
    final sets = await repo.getSetsForExercise(exerciseId, limit: 10);
    if (sets.isEmpty) return const [];
    return sets.reversed.map((s) => s.estimatedOneRepMax).toList();
  },
);
