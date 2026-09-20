import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../cardio/application/cardio_history_entry.dart';
import '../../../cardio/application/cardio_progress.dart';
import '../providers/cardio_history_provider.dart';
import 'date_group_header.dart';

/// The Cardio section of the History tab: a History | Progress segmented
/// control over the active client's saved cardio sessions, filtered by
/// sport. Tapping a session opens its workout in History, where the
/// session's recordings can be reviewed and exported.
class CardioHistoryView extends ConsumerStatefulWidget {
  const CardioHistoryView({super.key});

  @override
  ConsumerState<CardioHistoryView> createState() => _CardioHistoryViewState();
}

enum _Segment { history, progress }

class _CardioHistoryViewState extends ConsumerState<CardioHistoryView> {
  _Segment _segment = _Segment.history;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(cardioHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
      data: (all) {
        if (all.isEmpty) return _EmptyState(s: s, cs: cs);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            KineticEyebrow(s.cardioTab),
            const SizedBox(height: 6),
            Text(
              _segment == _Segment.history
                  ? s.cardioHistoryTitle
                  : s.cardioProgressTitle,
              style: KineticText.display(size: 34, color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            _SegmentedControl(
              segment: _segment,
              onChanged: (v) => setState(() => _segment = v),
            ),
            const SizedBox(height: 16),
            _SportChips(entries: all),
            const SizedBox(height: 16),
            if (_segment == _Segment.history)
              const _HistoryList()
            else
              const _ProgressPanel(),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s, required this.cs});

  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run, size: 72, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              s.noCardioSessions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              s.noCardioSessionsHint,
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
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.segment, required this.onChanged});

  final _Segment segment;
  final ValueChanged<_Segment> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    Widget pill(_Segment value, String label) {
      final selected = value == segment;
      return Expanded(
        child: Material(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: KineticText.mono(
                  size: 13,
                  weight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          pill(_Segment.history, s.historyTab),
          const SizedBox(width: 4),
          pill(_Segment.progress, s.progressTab),
        ],
      ),
    );
  }
}

/// One chip per sport that has a session, plus "All sports".
class _SportChips extends ConsumerWidget {
  const _SportChips({required this.entries});

  final List<CardioHistoryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final selected = ref.watch(cardioSportFilterProvider);
    final sports = <String, String>{};
    for (final e in entries) {
      sports.putIfAbsent(e.exerciseId, () => e.exerciseName);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(s.allSports),
            selected: selected == null,
            onSelected: (_) =>
                ref.read(cardioSportFilterProvider.notifier).select(null),
          ),
          for (final sport in sports.entries) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(sport.value),
              selected: selected == sport.key,
              onSelected: (_) => ref
                  .read(cardioSportFilterProvider.notifier)
                  .select(sport.key),
            ),
          ],
        ],
      ),
    );
  }
}

// ── History segment ───────────────────────────────────────────────────

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final entriesAsync = ref.watch(filteredCardioHistoryProvider);
    final progressAsync = ref.watch(cardioProgressProvider);

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(s.errorPrefix(e.toString())),
      data: (entries) {
        final groups = _groupByWeek(entries, s);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            progressAsync.maybeWhen(
              data: (p) => _SummaryStrip(progress: p),
              orElse: () => const SizedBox.shrink(),
            ),
            for (final group in groups) ...[
              DateGroupHeader(label: group.label),
              for (final entry in group.items) _SessionCard(entry: entry),
            ],
          ],
        );
      },
    );
  }
}

class _WeekGroup {
  final String label;
  final List<CardioHistoryEntry> items;
  const _WeekGroup(this.label, this.items);
}

List<_WeekGroup> _groupByWeek(List<CardioHistoryEntry> entries, S s) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final groups = <String, List<CardioHistoryEntry>>{};
  for (final e in entries) {
    final local = e.startedAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    final String label;
    if (diff < 7) {
      label = s.thisWeek;
    } else if (diff < 14) {
      label = s.lastWeek;
    } else {
      label = DateFormat.yMMMM().format(local);
    }
    groups.putIfAbsent(label, () => []).add(e);
  }
  return [for (final g in groups.entries) _WeekGroup(g.key, g.value)];
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.progress});

  final CardioProgress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Row(
      children: [
        Expanded(
          child: KineticStatTile(
            label: s.cardioLastWeeks(kCardioProgressWeeks),
            value: progress.totalDistanceKm.toStringAsFixed(1),
            unit: 'km',
            valueSize: 22,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KineticStatTile(
            label: s.cardioSessionsLabel,
            value: '${progress.sessionCount}',
            valueSize: 22,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KineticStatTile(
            label: s.cardioTimeLabel,
            value: _hoursMinutes(progress.totalDuration),
            valueSize: 22,
          ),
        ),
      ],
    );
  }

  static String _hoursMinutes(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h == 0 ? '${m}m' : '${h}h ${m}m';
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.entry});

  final CardioHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = entry.session;
    final local = entry.startedAt.toLocal();
    final hasRecordings = session.distanceMeters != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/history/${session.workoutId}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasRecordings
                          ? cs.primaryContainer
                          : cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_run,
                      size: 20,
                      color: hasRecordings
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.exerciseName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(value: session.duration.formatted, label: 'TIME'),
                  _Stat(
                    value: entry.distanceKm?.toStringAsFixed(2) ?? '—',
                    label: 'KM',
                  ),
                  _Stat(
                    value: entry.paceMinutesPerKm == null
                        ? '—'
                        : formatPace(entry.paceMinutesPerKm!),
                    label: 'MIN/KM',
                  ),
                  _Stat(
                    value: session.avgHeartRate?.toString() ?? '—',
                    label: 'AVG BPM',
                    color: session.avgHeartRate == null ? null : cs.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: KineticText.mono(
              size: 15,
              weight: FontWeight.w600,
              color: color ?? cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: KineticText.mono(
              size: 9,
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// `m:ss` for a pace in minutes per km.
String formatPace(double minutesPerKm) {
  final mins = minutesPerKm.floor();
  final secs = ((minutesPerKm - mins) * 60).round();
  if (secs == 60) return '${mins + 1}:00';
  return '$mins:${secs.toString().padLeft(2, '0')}';
}

// ── Progress segment ──────────────────────────────────────────────────

class _ProgressPanel extends ConsumerWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final progressAsync = ref.watch(cardioProgressProvider);

    return progressAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(s.errorPrefix(e.toString())),
      data: (p) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: KineticStatTile(
                  label: s.cardioDistanceLabel,
                  value: p.totalDistanceKm.toStringAsFixed(1),
                  unit: 'km',
                  valueSize: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KineticStatTile(
                  label: s.cardioBestPaceLabel,
                  value: p.bestPaceMinutesPerKm == null
                      ? '—'
                      : formatPace(p.bestPaceMinutesPerKm!),
                  unit: p.bestPaceMinutesPerKm == null ? null : '/km',
                  valueSize: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KineticStatTile(
                  label: s.cardioAvgHrLabel,
                  value: p.avgHeartRate?.toString() ?? '—',
                  unit: p.avgHeartRate == null ? null : 'bpm',
                  valueSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: s.cardioWeeklyDistanceTitle,
            trailing: 'km',
            child: _WeeklyDistanceChart(weekly: p.weeklyDistanceKm),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: s.cardioAveragePaceTitle,
            trailing: s.cardioPaceLowerIsFaster,
            child: p.paceTrend.length < 2
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      s.cardioNoPaceData,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : _PaceTrendChart(points: p.paceTrend),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
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

class _WeeklyDistanceChart extends StatelessWidget {
  const _WeeklyDistanceChart({required this.weekly});

  final List<double> weekly;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = weekly.fold<double>(0, (m, v) => v > m ? v : m);
    final last = weekly.length - 1;

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY * 1.25,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) => Text(
                  v.toInt() == last ? 'Now' : 'W-${last - v.toInt()}',
                  style: KineticText.mono(size: 10, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ),
          barTouchData: const BarTouchData(enabled: false),
          barGroups: [
            for (var i = 0; i < weekly.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: weekly[i],
                    width: 26,
                    borderRadius: BorderRadius.circular(6),
                    color: i == last ? cs.primary : cs.surfaceContainerHigh,
                  ),
                ],
                showingTooltipIndicators: weekly[i] > 0 ? [0] : const [],
              ),
          ],
        ),
      ),
    );
  }
}

class _PaceTrendChart extends StatelessWidget {
  const _PaceTrendChart({required this.points});

  final List<PacePoint> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paces = points.map((p) => p.minutesPerKm).toList();
    final minY = paces.reduce((a, b) => a < b ? a : b);
    final maxY = paces.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.3).clamp(0.25, 2.0);

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.surfaceContainer,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  formatPace(v),
                  style: KineticText.mono(size: 9, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < paces.length; i++)
                  FlSpot(i.toDouble(), paces[i]),
              ],
              isCurved: false,
              color: cs.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.x == paces.length - 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
