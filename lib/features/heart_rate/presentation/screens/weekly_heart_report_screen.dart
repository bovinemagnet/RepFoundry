import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../application/weekly_heart_report.dart';
import '../providers/weekly_heart_report_provider.dart';
import '../providers/zone_configuration_provider.dart';

/// The last seven days of heart-rate activity: headline figures, the
/// highest reading each day, time in each training zone, and every
/// session that carried heart-rate data.
class WeeklyHeartReportScreen extends ConsumerWidget {
  const WeeklyHeartReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final reportAsync = ref.watch(weeklyHeartReportProvider);
    final zones = ref.watch(zoneConfigurationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.weeklyHeartReportTitle),
        leading: BackButton(onPressed: () => context.go('/heart-rate')),
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
        data: (report) {
          if (report.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monitor_heart, size: 72, color: cs.outline),
                    const SizedBox(height: 16),
                    Text(
                      s.weeklyHeartReportEmpty,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.weeklyHeartReportEmptyHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              KineticEyebrow(s.weeklyHeartReportSubtitle),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KineticStatTile(
                      label: s.weeklyHeartReportSessions,
                      value: '${report.sessions.length}',
                      valueSize: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KineticStatTile(
                      label: s.weeklyHeartReportAvg,
                      value: '${report.avgBpm}',
                      unit: 'bpm',
                      valueSize: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KineticStatTile(
                      label: s.weeklyHeartReportPeak,
                      value: '${report.peakBpm}',
                      unit: 'bpm',
                      valueSize: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Card(
                title: s.weeklyHeartReportDailyPeak,
                trailing: 'bpm',
                child: _DailyPeakChart(peaks: report.dailyPeakBpm),
              ),
              if (zones != null && report.secondsInZone.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Card(
                  title: s.weeklyHeartReportTimeInZone,
                  trailing: '',
                  child: _TimeInZone(
                    zones: zones,
                    secondsInZone: report.secondsInZone,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _Card(
                title: s.weeklyHeartReportSessionsTitle,
                trailing: '',
                child: Column(
                  children: [
                    for (final session in report.sessions)
                      _SessionRow(session: session),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: KineticText.mono(
                      size: 11,
                      letterSpacing: 1.9,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  trailing,
                  style: KineticText.mono(size: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DailyPeakChart extends StatelessWidget {
  const _DailyPeakChart({required this.peaks});

  final List<int?> peaks;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final maxY = peaks.whereType<int>().fold<int>(0, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: (maxY == 0 ? 100 : maxY * 1.2).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  final day = today.subtract(
                    Duration(days: peaks.length - 1 - v.toInt()),
                  );
                  return Text(
                    DateFormat.E().format(day).substring(0, 2),
                    style:
                        KineticText.mono(size: 10, color: cs.onSurfaceVariant),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < peaks.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (peaks[i] ?? 0).toDouble(),
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                    color: i == peaks.length - 1
                        ? cs.primary
                        : cs.surfaceContainerHigh,
                  ),
                ],
                showingTooltipIndicators: peaks[i] != null ? [0] : const [],
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeInZone extends StatelessWidget {
  const _TimeInZone({required this.zones, required this.secondsInZone});

  final ZoneConfiguration zones;
  final Map<int, int> secondsInZone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = secondsInZone.values.fold<int>(0, (a, b) => a + b);

    return Column(
      children: [
        for (final zone in zones.zones)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    '${zone.label} · ${zone.effortLabel}',
                    overflow: TextOverflow.ellipsis,
                    style: KineticText.mono(size: 11, color: cs.onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: total == 0
                          ? 0
                          : (secondsInZone[zone.zoneNumber] ?? 0) / total,
                      backgroundColor: cs.surfaceContainerHigh,
                      color: Color(zone.color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    _minutes(secondsInZone[zone.zoneNumber] ?? 0),
                    textAlign: TextAlign.right,
                    style: KineticText.mono(
                      size: 12,
                      weight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _minutes(int seconds) {
    final m = (seconds / 60).round();
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final HeartSessionSummary session;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final local = session.startedAt.toLocal();
    final title = session.kind == HeartSessionKind.cardio
        ? session.title
        : s.weeklyHeartReportStrengthSession;

    return InkWell(
      onTap: () => context.go('/history/${session.workoutId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              session.kind == HeartSessionKind.cardio
                  ? Icons.directions_run
                  : Icons.fitness_center,
              size: 20,
              color: cs.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${local.relativeLabel} · ${local.timeOfDay}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              s.weeklyHeartReportAvgPeak(session.avgBpm, session.peakBpm),
              style: KineticText.mono(size: 12, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
