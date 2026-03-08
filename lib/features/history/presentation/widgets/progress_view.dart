import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/progress_chart_widget.dart';
import '../providers/trained_exercises_provider.dart';
import '../providers/workout_volume_chart_provider.dart';
import '../providers/workout_frequency_provider.dart';
import '../providers/workout_duration_chart_provider.dart';
import 'calendar_heatmap.dart';
import 'exercise_progress_tile.dart';
import 'muscle_group_chart.dart';
import 'streak_card.dart';

class ProgressView extends ConsumerWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final volumeAsync = ref.watch(workoutVolumeChartProvider);
    final frequencyAsync = ref.watch(workoutFrequencyProvider);
    final durationAsync = ref.watch(workoutDurationChartProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak tracker
        const StreakCard(),
        const SizedBox(height: 16),
        // Calendar heatmap
        const CalendarHeatmap(),
        const SizedBox(height: 24),
        // Volume trend chart
        volumeAsync.when(
          data: (data) {
            if (data.isEmpty) return const SizedBox.shrink();
            return ProgressChartWidget(
              label: s.volumeTrendTitle,
              dataPoints: data,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        // Duration trend chart
        durationAsync.when(
          data: (data) {
            if (data.isEmpty) return const SizedBox.shrink();
            return ProgressChartWidget(
              label: s.durationTrendTitle,
              dataPoints: data,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        // Frequency bar chart
        frequencyAsync.when(
          data: (weeks) => _FrequencyChart(weeks: weeks),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        // Muscle group distribution
        const MuscleGroupChart(),
        const SizedBox(height: 24),
        // Exercise progress list
        _ExerciseProgressList(),
      ],
    );
  }
}

class _FrequencyChart extends StatelessWidget {
  const _FrequencyChart({required this.weeks});

  final List<WeeklyFrequency> weeks;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurfaceVariant;

    final maxCount =
        weeks.fold<int>(0, (max, w) => w.count > max ? w.count : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.frequencyTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxCount + 1).toDouble(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final week = weeks[groupIndex];
                    final label = DateFormat.MMMd().format(week.weekStart);
                    return BarTooltipItem(
                      '$label\n${week.count} ${s.workoutsPerWeek}',
                      TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(color: textColor, fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= weeks.length) {
                        return const SizedBox.shrink();
                      }
                      // Show label every 3 weeks to avoid crowding
                      if (idx % 3 != 0 && idx != weeks.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat.MMMd().format(weeks[idx].weekStart),
                          style: TextStyle(color: textColor, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.surfaceContainerHighest,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < weeks.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeks[i].count.toDouble(),
                        color: primaryColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseProgressList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final async = ref.watch(trainedExercisesProvider);

    return async.when(
      data: (exercises) {
        if (exercises.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.exerciseProgressListTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...exercises.map(
              (e) => ExerciseProgressTile(trainedExercise: e),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
