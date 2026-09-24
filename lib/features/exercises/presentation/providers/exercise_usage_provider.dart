import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';

/// Maps exercise id → number of workouts the active client has used it in.
final exerciseUsageCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  return repo.getExerciseUsageCounts(clientId);
});
