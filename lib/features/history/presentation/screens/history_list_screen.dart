import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../providers/volume_sparkline_provider.dart';
import '../widgets/workout_history_tile.dart';
import '../widgets/progress_view.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/sparkline_widget.dart';

class _WorkoutWithSets {
  final Workout workout;
  final List<WorkoutSet> sets;

  const _WorkoutWithSets({required this.workout, required this.sets});
}

final _workoutHistoryProvider =
    FutureProvider.autoDispose<List<_WorkoutWithSets>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 50);
  final result = <_WorkoutWithSets>[];
  for (final w in workouts) {
    final sets = await repo.getSetsForWorkout(w.id);
    result.add(_WorkoutWithSets(workout: w, sets: sets));
  }
  return result;
});

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: s.prHistoryTitle,
            onPressed: () => context.push('/pr-history'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.historyTab),
            Tab(text: s.progressTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HistoryTab(),
          const ProgressView(),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final historyAsync = ref.watch(_workoutHistoryProvider);

    return historyAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  s.noWorkoutsYet,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  s.noWorkoutsYetSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _VolumeTrendHeader();
            }
            final item = items[index - 1];
            return WorkoutHistoryTile(
              workout: item.workout,
              setCount: item.sets.length,
              onTap: () => context.go('/history/${item.workout.id}'),
            );
          },
        );
      },
      loading: () => LoadingWidget(message: s.loadingHistory),
      error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
    );
  }
}

class _VolumeTrendHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final volumeAsync = ref.watch(volumeSparklineProvider);

    return volumeAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.volumeTrend(data.length),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: SparklineWidget(data: data),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
