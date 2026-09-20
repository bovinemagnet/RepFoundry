import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../cardio/application/cardio_history_entry.dart';
import '../../../cardio/application/cardio_progress.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';

/// Every saved cardio session for the active client, newest first.
final cardioHistoryProvider =
    FutureProvider.autoDispose<List<CardioHistoryEntry>>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  return ref.watch(buildCardioHistoryUseCaseProvider).execute(
        clientId: clientId,
      );
});

/// The sport (exercise id) the Cardio views are filtered to; null = all.
class CardioSportFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? exerciseId) => state = exerciseId;
}

final cardioSportFilterProvider =
    NotifierProvider<CardioSportFilter, String?>(CardioSportFilter.new);

/// History entries after the sport filter.
final filteredCardioHistoryProvider =
    FutureProvider.autoDispose<List<CardioHistoryEntry>>((ref) async {
  final entries = await ref.watch(cardioHistoryProvider.future);
  final sport = ref.watch(cardioSportFilterProvider);
  if (sport == null) return entries;
  return entries.where((e) => e.exerciseId == sport).toList();
});

const kCardioProgressWeeks = 6;

/// Progress figures for the filtered history over the last six weeks.
final cardioProgressProvider =
    FutureProvider.autoDispose<CardioProgress>((ref) async {
  final entries = await ref.watch(filteredCardioHistoryProvider.future);
  return CardioProgress.compute(
    entries,
    now: DateTime.now(),
    weeks: kCardioProgressWeeks,
  );
});
