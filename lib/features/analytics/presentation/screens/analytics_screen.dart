import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../providers/weekly_volume_provider.dart';
import '../providers/muscle_balance_provider.dart';
import '../providers/pr_timeline_provider.dart';
import '../providers/training_load_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final theme = Theme.of(context);

    final volumeAsync = ref.watch(weeklyVolumeProvider);
    final balanceAsync = ref.watch(muscleBalanceProvider);
    final prAsync = ref.watch(prTimelineProvider);
    final loadAsync = ref.watch(trainingLoadProvider);

    // Check if all providers have loaded with empty data
    final allEmpty = volumeAsync.whenOrNull(data: (d) => d.isEmpty) == true &&
        balanceAsync.whenOrNull(data: (d) => d.isEmpty) == true &&
        prAsync.whenOrNull(data: (d) => d.isEmpty) == true &&
        loadAsync.whenOrNull(data: (d) => d.isEmpty) == true;

    if (allEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(s.analyticsTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(s.noAnalyticsData, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                s.noAnalyticsDataSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.analyticsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Weekly Volume Trend
          _buildSection(
            context: context,
            title: s.weeklyVolumeTitle,
            child: volumeAsync.when(
              data: (data) => data.isEmpty
                  ? const SizedBox.shrink()
                  : _WeeklyVolumeChart(data: data),
              loading: () => const _ChartLoading(),
              error: (e, _) => _ChartError(message: e.toString()),
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Muscle Group Balance
          _buildSection(
            context: context,
            title: s.muscleBalanceTitle,
            child: balanceAsync.when(
              data: (data) => data.isEmpty
                  ? const SizedBox.shrink()
                  : _MuscleBalanceChart(data: data),
              loading: () => const _ChartLoading(),
              error: (e, _) => _ChartError(message: e.toString()),
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: PR Timeline
          _buildSection(
            context: context,
            title: s.prTimelineTitle,
            child: prAsync.when(
              data: (data) => data.isEmpty
                  ? const SizedBox.shrink()
                  : _PrTimeline(entries: data),
              loading: () => const _ChartLoading(),
              error: (e, _) => _ChartError(message: e.toString()),
            ),
          ),
          const SizedBox(height: 16),

          // Section 4: Training Load
          _buildSection(
            context: context,
            title: s.trainingLoadTitle,
            subtitle: s.trainingLoadSubtitle,
            child: loadAsync.when(
              data: (data) => data.isEmpty
                  ? const SizedBox.shrink()
                  : _TrainingLoadChart(data: data),
              loading: () => const _ChartLoading(),
              error: (e, _) => _ChartError(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// --- Weekly Volume Line Chart ---

class _WeeklyVolumeChart extends StatelessWidget {
  const _WeeklyVolumeChart({required this.data});

  final List<WeeklyVolume> data;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurfaceVariant;

    final maxVolume = data.fold<double>(
        0, (max, w) => w.totalVolume > max ? w.totalVolume : max);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxVolume * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].totalVolume),
              ],
              isCurved: true,
              color: primaryColor,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final week = data[spot.spotIndex];
                  final dateLabel = DateFormat.MMMd().format(week.weekStart);
                  final changeText = week.percentChange != null
                      ? '\n${s.weeklyVolumeChange(week.percentChange!.toStringAsFixed(1))}'
                      : '';
                  return LineTooltipItem(
                    '$dateLabel\n${week.totalVolume.toStringAsFixed(0)} kg$changeText',
                    TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
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
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
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
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  if (idx % 3 != 0 && idx != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat.MMMd().format(data[idx].weekStart),
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
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.surfaceContainerHighest,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

// --- Muscle Balance Radar Chart ---

class _MuscleBalanceChart extends StatelessWidget {
  const _MuscleBalanceChart({required this.data});

  final List<MuscleBalance> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SizedBox(
      height: 280,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
          tickBorderData: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
          gridBorderData: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) {
            if (index < 0 || index >= data.length) {
              return const RadarChartTitle(text: '');
            }
            return RadarChartTitle(
              text: data[index].group.name,
              angle: 0,
            );
          },
          dataSets: [
            RadarDataSet(
              dataEntries: [
                for (final d in data) RadarEntry(value: d.volumePercent),
              ],
              fillColor: primaryColor.withValues(alpha: 0.2),
              borderColor: primaryColor,
              borderWidth: 2,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

// --- PR Timeline ---

class _PrTimeline extends StatelessWidget {
  const _PrTimeline({required this.entries});

  final List<PrTimelineEntry> entries;

  String _recordTypeLabel(String name) {
    switch (name) {
      case 'estimatedOneRepMax':
        return 'Est. 1RM';
      case 'maxWeight':
        return 'Max Weight';
      case 'maxReps':
        return 'Max Reps';
      case 'maxVolume':
        return 'Max Volume';
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return SizedBox(
            width: 160,
            child: Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.exerciseName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recordTypeLabel(entry.record.recordType.name),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.record.value.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(entry.record.achievedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Training Load Bar Chart ---

class _TrainingLoadChart extends StatelessWidget {
  const _TrainingLoadChart({required this.data});

  final List<WeeklyLoad> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurfaceVariant;

    final maxLoad =
        data.fold<double>(0, (max, w) => w.load > max ? w.load : max);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxLoad * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final week = data[groupIndex];
                final dateLabel = DateFormat.MMMd().format(week.weekStart);
                return BarTooltipItem(
                  '$dateLabel\n${week.setCount} sets\nLoad: ${week.load.toStringAsFixed(1)}',
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
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${data[idx].setCount}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
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
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  if (idx % 3 != 0 && idx != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat.MMMd().format(data[idx].weekStart),
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
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.surfaceContainerHighest,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].load,
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
    );
  }
}

// --- Helper widgets ---

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
