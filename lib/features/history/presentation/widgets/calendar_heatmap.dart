import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';

/// Provides a set of dates (normalised to midnight) on which workouts occurred
/// over the last 12 weeks.
final workoutDaysProvider =
    FutureProvider.autoDispose<Set<DateTime>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 200);

  final days = <DateTime>{};
  for (final w in workouts) {
    final local = w.startedAt.toLocal();
    days.add(DateTime(local.year, local.month, local.day));
  }
  return days;
});

/// A GitHub-style contribution heatmap showing workout days over the last
/// 12 weeks.
class CalendarHeatmap extends ConsumerWidget {
  const CalendarHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(workoutDaysProvider);

    return daysAsync.when(
      data: (workoutDays) {
        if (workoutDays.isEmpty) return const SizedBox.shrink();
        return _HeatmapGrid(workoutDays: workoutDays);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.workoutDays});

  final Set<DateTime> workoutDays;

  static const int _weeks = 12;
  static const int _daysPerWeek = 7;
  static const double _cellSize = 14;
  static const double _cellGap = 3;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final emptyColor = theme.colorScheme.surfaceContainerHighest;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start from the Monday of 12 weeks ago.
    final startOfCurrentWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final gridStart =
        startOfCurrentWeek.subtract(Duration(days: 7 * (_weeks - 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.calendarHeatmapTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day-of-week labels (Mon, Wed, Fri)
            Column(
              children: [
                for (int day = 0; day < _daysPerWeek; day++)
                  SizedBox(
                    height: _cellSize + _cellGap,
                    child: (day == 0 || day == 2 || day == 4)
                        ? Text(
                            DateFormat.E()
                                .format(gridStart.add(Duration(days: day))),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            // Grid of cells
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    for (int week = 0; week < _weeks; week++)
                      Column(
                        children: [
                          for (int day = 0; day < _daysPerWeek; day++)
                            _buildCell(
                              context,
                              gridStart
                                  .add(Duration(days: week * 7 + day)),
                              today,
                              primaryColor,
                              emptyColor,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              s.calendarHeatmapLess,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
            const SizedBox(width: 4),
            _legendCell(emptyColor),
            _legendCell(primaryColor.withValues(alpha: 0.3)),
            _legendCell(primaryColor.withValues(alpha: 0.6)),
            _legendCell(primaryColor),
            const SizedBox(width: 4),
            Text(
              s.calendarHeatmapMore,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    DateTime date,
    DateTime today,
    Color activeColor,
    Color emptyColor,
  ) {
    final isFuture = date.isAfter(today);
    final isWorkoutDay = workoutDays.contains(date);

    Color cellColor;
    if (isFuture) {
      cellColor = Colors.transparent;
    } else if (isWorkoutDay) {
      cellColor = activeColor;
    } else {
      cellColor = emptyColor;
    }

    return Padding(
      padding: const EdgeInsets.all(_cellGap / 2),
      child: Tooltip(
        message: isFuture
            ? ''
            : '${DateFormat.MMMd().format(date)}${isWorkoutDay ? ' ✓' : ''}',
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _legendCell(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
