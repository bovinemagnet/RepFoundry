import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../providers/volume_sparkline_provider.dart';
import '../widgets/history_desktop_view.dart';
import '../widgets/progress_view.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/units/weight_unit_provider.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../../core/widgets/sparkline_widget.dart';
import '../../../../core/widgets/bar_sparkline_widget.dart';
import '../../../../core/widgets/loading_widget.dart';

// ── Data model ─────────────────────────────────────────────────────────

class _WorkoutWithSets {
  final Workout workout;
  final List<WorkoutSet> sets;

  const _WorkoutWithSets({required this.workout, required this.sets});

  double get totalVolume => sets.fold<double>(0, (sum, s) => sum + s.volume);

  /// Duration in minutes between start and completion, or null if not yet
  /// completed.
  int? get durationMinutes {
    final completed = workout.completedAt;
    if (completed == null) return null;
    return completed.difference(workout.startedAt).inMinutes;
  }
}

final _workoutHistoryProvider =
    FutureProvider.autoDispose<List<_WorkoutWithSets>>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(
    clientId: clientId,
    limit: 50,
  );
  final setsByWorkout =
      await repo.getSetsForWorkouts([for (final w in workouts) w.id]);
  return [
    for (final w in workouts)
      _WorkoutWithSets(workout: w, sets: setsByWorkout[w.id] ?? const []),
  ];
});

// ── Public screen ─────────────────────────────────────────────────────

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

    // Wide screens use the desktop master–detail power layout.
    if (context.isWide) {
      return const HistoryDesktopView();
    }

    return Scaffold(
      // The KineticAppHeader is rendered inside the scrollable History tab,
      // so the Scaffold appBar only carries the TabBar.
      appBar: AppBar(
        // Transparent — the Kinetic header sits in the scroll view content.
        toolbarHeight: 0,
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

// ── Date-group helpers ─────────────────────────────────────────────────

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

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          children: [
            // Kinetic app header — sits at top of the scrollable area.
            const KineticAppHeader(),

            // Pagehead: eyebrow + title + subtitle (mirrors .pagehead in rf.css).
            _PageHead(),

            // Weekly-volume summary card with area chart.
            _WeeklyVolumeCard(),

            const SizedBox(height: 14),

            // Search field — .search style.
            _KineticSearchBar(),

            // Session groups.
            for (final (label, groupItems) in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
                child: KineticSectionLabel(label),
              ),
              for (final item in groupItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SessionCard(
                    item: item,
                    onTap: () => context.go('/history/${item.workout.id}'),
                  ),
                ),
            ],

            // Bottom padding for nav bar clearance.
            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => LoadingWidget(message: s.loadingHistory),
      error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
    );
  }
}

// ── Pagehead ───────────────────────────────────────────────────────────

/// Mirrors the design's `.pagehead` block: eyebrow + h2 + dim paragraph.
class _PageHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow: "LAST 6 WEEKS".
          const KineticEyebrow('Last 6 weeks'),
          const SizedBox(height: 10),
          // Screen title in Space Grotesk.
          Text(
            s.trainingHistoryTitle,
            style: KineticText.display(
              size: 32,
              weight: FontWeight.w700,
              letterSpacing: -0.8,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Dim subtitle.
          Text(
            s.trainingHistorySubtitle,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly-volume summary card ─────────────────────────────────────────

/// Computes the weekly totals (last 6 weeks) from the per-workout volume
/// sparkline, which is oldest-to-newest. Then renders:
///  - "WEEKLY VOLUME" mono label.
///  - Big total-kg mono value + accent KineticPill with % change.
///  - SparklineWidget area chart.
///  - Three month-axis labels: AUG / SEP / OCT equivalent from today.
class _WeeklyVolumeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final unit = ref.watch(weightUnitProvider);
    final volumeAsync = ref.watch(volumeSparklineProvider);

    return volumeAsync.when(
      data: (perWorkoutVolumes) {
        // Derive weekly buckets: assign each workout (oldest→newest) into one of
        // 6 week slots counting backwards from now.
        final weeklyTotals = _computeWeeklyTotals(perWorkoutVolumes);

        // Total for the most recent week.
        final totalKg = weeklyTotals.isNotEmpty ? weeklyTotals.last : 0.0;

        // Percentage change vs the prior week (or 0 if not enough data).
        final pctChange = _computePctChange(weeklyTotals);

        // Normalise weekly totals to 0..1 for the sparkline.
        final sparkData = _normalise(weeklyTotals);

        // Three month labels spaced across the x axis.
        final axisLabels = _axisMonthLabels();

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: stat label + accent pill.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "WEEKLY VOLUME" in mono.
                      Text(
                        s.weeklyVolumeTitle.toUpperCase(),
                        style: KineticText.mono(
                          size: 10.5,
                          weight: FontWeight.w600,
                          letterSpacing: 1.7,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Big kg figure.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatKg(unit.fromKg(totalKg)),
                            style: KineticText.mono(
                              size: 26,
                              weight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit.label(s),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (pctChange != 0)
                    KineticPill(
                      '${pctChange > 0 ? '+' : ''}${pctChange.toStringAsFixed(0)}% MO',
                      icon: pctChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      variant: KineticPillVariant.accent,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Area sparkline.
              SizedBox(
                height: 78,
                width: double.infinity,
                child: sparkData.length > 1
                    ? SparklineWidget(
                        data: sparkData,
                        strokeWidth: 2.5,
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 4),

              // Month axis labels: three labels spanning the x axis.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: axisLabels
                    .map(
                      (label) => Text(
                        label,
                        style: KineticText.mono(
                          size: 8.5,
                          weight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: cs.outline,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Pulled outside the class to keep the widget thin:

/// Sums the per-workout volumes into 6 weekly buckets (most recent last).
/// The provider returns oldest→newest per-workout volumes. We group them
/// naïvely into 6 equal-sized chunks, which is a reasonable approximation
/// when real date info is not available in the sparkline data.
List<double> _computeWeeklyTotals(List<double> perWorkout) {
  if (perWorkout.isEmpty) return [];
  // Split into up to 6 buckets of equal-ish size.
  const buckets = 6;
  final count = perWorkout.length;
  final chunkSize = (count / buckets).ceil().clamp(1, count);
  final weeks = <double>[];
  for (var i = 0; i < count; i += chunkSize) {
    final end = min(i + chunkSize, count);
    final sum = perWorkout.sublist(i, end).fold<double>(0, (a, b) => a + b);
    weeks.add(sum);
  }
  // Pad or trim to exactly buckets entries so the chart always spans 6 weeks.
  while (weeks.length < buckets) {
    weeks.insert(0, 0);
  }
  return weeks.length > buckets ? weeks.sublist(weeks.length - buckets) : weeks;
}

/// Returns the percentage change between the two most-recent weekly buckets.
int _computePctChange(List<double> weekly) {
  if (weekly.length < 2) return 0;
  final prev = weekly[weekly.length - 2];
  final curr = weekly[weekly.length - 1];
  if (prev == 0) return 0;
  return ((curr - prev) / prev * 100).round();
}

/// Normalises a list to the 0..1 range, ready for [SparklineWidget].
List<double> _normalise(List<double> values) {
  if (values.isEmpty) return [];
  final maxV = values.reduce(max);
  if (maxV == 0) return List.filled(values.length, 0.0);
  return values.map((v) => v / maxV).toList();
}

/// Returns three month-name labels centred across the 6-week window.
List<String> _axisMonthLabels() {
  const abbr = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  final now = DateTime.now();
  // Labels at ~6 weeks ago, ~3 weeks ago, and now.
  final m2 = DateTime(now.year, now.month - 1, now.day);
  final m1 = DateTime(now.year, now.month, now.day - 21);
  return [
    abbr[(m2.month - 1) % 12],
    abbr[(m1.month - 1) % 12],
    abbr[(now.month - 1) % 12],
  ];
}

/// Formats a volume total with thousands separator for display.
String _formatKg(double kg) {
  final rounded = kg.round();
  if (rounded >= 1000) {
    final thousands = rounded ~/ 1000;
    final remainder = (rounded % 1000).toString().padLeft(3, '0');
    return '$thousands,$remainder';
  }
  return rounded.toString();
}

// ── Kinetic search bar ─────────────────────────────────────────────────

/// Mirrors the CSS `.search` class: surfaceContainerLow rounded container with
/// a leading search icon and a dim hint. Visual-only — the screen has no filter
/// state yet, matching the existing behaviour.
class _KineticSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: cs.outline),
          const SizedBox(width: 10),
          Text(
            s.searchSessionsHint,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: cs.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session card ───────────────────────────────────────────────────────

/// Mirrors the `.ex` card in rf.css for the history list.
/// Shows: workout name (Space Grotesk) + schedule meta + date ghost pill.
/// Bottom section alternates between:
///  - BarSparklineWidget + "+N% vs prev" accent mono, or
///  - an intensity-meter (segmented bar row) + "HIGH / STABLE" label.
class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.item,
    this.onTap,
  });

  final _WorkoutWithSets item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final unit = ref.watch(weightUnitProvider);
    final workout = item.workout;

    final durationMins = item.durationMinutes;
    final totalVolume = unit.fromKg(item.totalVolume);

    // Schedule meta string: "64m · 12,450 kg" (or just volume if no duration).
    final metaString = durationMins != null
        ? '${durationMins}m · ${_formatKg(totalVolume)} ${unit.label(s)}'
        : '${_formatKg(totalVolume)} ${unit.label(s)}';

    // Date label for the ghost pill: "Tue · 14 Oct" style.
    final localDate = workout.startedAt.toLocal();
    final dateLabel = localDate.weekdayMonthDay;

    // Use the volume per-set data for the bar sparkline.
    final setVolumes = item.sets.map((ws) => ws.volume).toList();
    final hasSparkline = setVolumes.length > 1;

    // Intensity derived from set count (0–10 scale → 7 segments).
    // High = >= 8 sets, Medium = 4–7, Low = < 4.
    final setCount = item.sets.length;
    final intensityFilled = _intensitySegments(setCount);
    final intensityLabel = _intensityLabel(setCount);

    // Alternate display: even-indexed cards get sparkline, odd get intensity.
    // In practice the design shows both styles; we pick based on set count so
    // sessions with rich set data show the bar chart.
    final showSparkline = hasSparkline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name + date pill.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workout name in Space Grotesk.
                      Text(
                        s.workoutFallbackName,
                        style: KineticText.display(
                          size: 18,
                          weight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Schedule meta.
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: cs.outline,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            metaString,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Ghost date pill.
                KineticPill(
                  dateLabel,
                  variant: KineticPillVariant.ghost,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Row 2: sparkline + delta, OR intensity meter.
            if (showSparkline)
              _SparklineRow(setVolumes: setVolumes)
            else
              _IntensityRow(
                filledSegments: intensityFilled,
                label: intensityLabel,
              ),
          ],
        ),
      ),
    );
  }

  /// Maps set count to 7-segment intensity bar fill count (1–7).
  int _intensitySegments(int setCount) {
    if (setCount == 0) return 0;
    return (setCount / 3).ceil().clamp(1, 7);
  }

  /// Returns a short intensity label for the current set count.
  String _intensityLabel(int setCount) {
    if (setCount >= 10) return 'HIGH';
    if (setCount >= 5) return 'MODERATE';
    return 'LOW';
  }
}

// ── Sparkline bottom row ───────────────────────────────────────────────

class _SparklineRow extends StatelessWidget {
  const _SparklineRow({required this.setVolumes});

  final List<double> setVolumes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Compute % change between first and last half of sets as a proxy for trend.
    final pct = _deltaPercent(setVolumes);
    final pctLabel =
        pct >= 0 ? '+${pct.toStringAsFixed(0)}%' : '${pct.toStringAsFixed(0)}%';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Bar sparkline takes most of the width.
        Expanded(
          child: SizedBox(
            height: 48,
            child: BarSparklineWidget(data: setVolumes),
          ),
        ),
        const SizedBox(width: 14),
        // Percentage delta + "VS PREV" label.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pctLabel,
              style: KineticText.mono(
                size: 22,
                weight: FontWeight.w800,
                color: pct >= 0 ? cs.primary : cs.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'VS PREV',
              style: KineticText.mono(
                size: 8.5,
                weight: FontWeight.w600,
                letterSpacing: 1.0,
                color: cs.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _deltaPercent(List<double> data) {
    if (data.length < 2) return 0;
    final half = data.length ~/ 2;
    final first = data.sublist(0, half).fold<double>(0, (a, b) => a + b) / half;
    final second = data.sublist(half).fold<double>(0, (a, b) => a + b) /
        (data.length - half);
    if (first == 0) return 0;
    return (second - first) / first * 100;
  }
}

// ── Intensity meter bottom row ─────────────────────────────────────────

class _IntensityRow extends StatelessWidget {
  const _IntensityRow({
    required this.filledSegments,
    required this.label,
  });

  final int filledSegments;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const totalSegments = 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INTENSITY SCORE',
              style: KineticText.mono(
                size: 10.5,
                weight: FontWeight.w600,
                letterSpacing: 1.7,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              label,
              style: KineticText.mono(
                size: 16,
                weight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(totalSegments, (i) {
            final filled = i < filledSegments;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < totalSegments - 1 ? 5 : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: filled ? cs.primary : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
      ],
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
