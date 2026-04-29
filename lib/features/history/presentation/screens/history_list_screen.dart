import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../providers/volume_sparkline_provider.dart';
import '../widgets/date_group_header.dart';
import '../widgets/workout_history_tile.dart';
import '../widgets/progress_view.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/bar_sparkline_widget.dart';
import '../../../../core/widgets/loading_widget.dart';

class _WorkoutWithSets {
  final Workout workout;
  final List<WorkoutSet> sets;

  const _WorkoutWithSets({required this.workout, required this.sets});

  double get totalVolume => sets.fold<double>(0, (sum, s) => sum + s.volume);
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

// ── Date grouping helpers ──────────────────────────────────────────────

String _dateGroupLabel(DateTime date, S s) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final workoutDate = DateTime(date.year, date.month, date.day);
  final diff = today.difference(workoutDate).inDays;

  if (diff < 7) return s.thisWeek;
  if (diff < 14) return s.lastWeek;

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final label = months[date.month - 1];
  if (date.year != now.year) return '$label ${date.year}';
  return label;
}

/// Groups workouts by date bucket, preserving order (newest first).
List<(String label, List<_WorkoutWithSets> items)> _groupByDate(
  List<_WorkoutWithSets> workouts,
  S s,
) {
  final groups = <String, List<_WorkoutWithSets>>{};
  final groupOrder = <String>[];

  for (final w in workouts) {
    final label = _dateGroupLabel(w.workout.startedAt.toLocal(), s);
    if (!groups.containsKey(label)) {
      groups[label] = [];
      groupOrder.add(label);
    }
    groups[label]!.add(w);
  }

  return [
    for (final label in groupOrder) (label, groups[label]!),
  ];
}

// ── History tab ────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final historyAsync = ref.watch(_workoutHistoryProvider);

    return historyAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState();
        }

        final groups = _groupByDate(items, s);

        // Build a flat list of widgets: header + search + groups of tiles.
        final widgets = <Widget>[
          _EditorialHeader(),
          _SearchBar(),
          _VolumeTrendHeader(),
        ];

        for (final (label, groupItems) in groups) {
          widgets.add(DateGroupHeader(label: label));
          for (final item in groupItems) {
            // Per-set volumes for the sparkline (chronological order).
            final setVolumes = item.sets.map((s) => s.volume).toList();

            widgets.add(
              WorkoutHistoryTile(
                workout: item.workout,
                setCount: item.sets.length,
                totalVolume: item.totalVolume,
                sparklineData: setVolumes.length > 1 ? setVolumes : null,
                onTap: () => context.go('/history/${item.workout.id}'),
              ),
            );
          }
        }

        // Bottom padding for nav bar clearance.
        widgets.add(const SizedBox(height: 80));

        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: widgets,
        );
      },
      loading: () => LoadingWidget(message: s.loadingHistory),
      error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
    );
  }
}

// ── Editorial header ───────────────────────────────────────────────────

class _EditorialHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.trainingHistoryTitle,
            style: tt.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.trainingHistorySubtitle,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: s.searchSessionsHint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Volume trend header ────────────────────────────────────────────────

class _VolumeTrendHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final volumeAsync = ref.watch(volumeSparklineProvider);

    return volumeAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.volumeTrend(data.length).toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: BarSparklineWidget(data: data),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: cs.outline),
          const SizedBox(height: 16),
          Text(s.noWorkoutsYet, style: tt.headlineSmall),
          const SizedBox(height: 8),
          Text(
            s.noWorkoutsYetSubtitle,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
