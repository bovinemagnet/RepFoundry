import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';

/// Provides the last 10 estimated 1RM values for an exercise (oldest → newest).
final exerciseSparklineProvider =
    FutureProvider.autoDispose.family<List<double>, String>(
  (ref, exerciseId) async {
    final repo = ref.watch(workoutRepositoryProvider);
    final clientId = (await ref.watch(activeClientProvider.future)).id;
    final sets = await repo.getSetsForExercise(
      exerciseId,
      clientId: clientId,
      limit: 10,
    );
    if (sets.isEmpty) return const [];
    return sets.reversed.map((s) => s.estimatedOneRepMax).toList();
  },
);
