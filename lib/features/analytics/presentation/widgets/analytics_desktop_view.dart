import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/widgets/desktop_top_bar.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../../core/widgets/kpi_strip.dart';
import '../../../history/presentation/providers/workout_history_provider.dart';
import '../providers/weekly_volume_provider.dart';
import '../providers/muscle_balance_provider.dart';
import '../providers/pr_timeline_provider.dart';
import '../providers/training_load_provider.dart';
import '../screens/analytics_screen.dart';

/// Desktop "power layout" for Analytics — a multi-chart dashboard with a KPI
/// strip on top and every chart visible at once in a two-column grid, so
/// trends can be compared without drilling in.
class AnalyticsDesktopView extends ConsumerWidget {
  const AnalyticsDesktopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;

    final volumeAsync = ref.watch(weeklyVolumeProvider);
    final balanceAsync = ref.watch(muscleBalanceProvider);
    final prAsync = ref.watch(prTimelineProvider);
    final loadAsync = ref.watch(trainingLoadProvider);
    final historyAsync = ref.watch(workoutHistoryWithSetsProvider);

    return Scaffold(
      body: Column(
        children: [
          DesktopTopBar(
            eyebrow: s.analyticsTitle,
            title: s.analyticsTitle,
            subtitle: s.trainingLoadSubtitle,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 40),
              children: [
                _KpiRow(
                  volume: volumeAsync.asData?.value ?? const [],
                  prCount: prAsync.asData?.value.length ?? 0,
                  workoutCount: historyAsync.asData?.value.length ?? 0,
                ),
                const SizedBox(height: 18),

                // Weekly volume — full width.
                _DashCard(
                  title: s.weeklyVolumeTitle,
                  child: volumeAsync.when(
                    data: (d) => d.isEmpty
                        ? const _NoData()
                        : WeeklyVolumeChart(data: d),
                    loading: () => const ChartLoading(),
                    error: (e, _) => ChartError(message: e.toString()),
                  ),
                ),
                const SizedBox(height: 16),

                // Muscle balance + training load — two columns.
                _TwoColumn(
                  left: _DashCard(
                    title: s.muscleBalanceTitle,
                    child: balanceAsync.when(
                      data: (d) => d.isEmpty
                          ? const _NoData()
                          : MuscleBalanceChart(data: d),
                      loading: () => const ChartLoading(),
                      error: (e, _) => ChartError(message: e.toString()),
                    ),
                  ),
                  right: _DashCard(
                    title: s.trainingLoadTitle,
                    subtitle: s.trainingLoadSubtitle,
                    child: loadAsync.when(
                      data: (d) => d.isEmpty
                          ? const _NoData()
                          : TrainingLoadChart(data: d),
                      loading: () => const ChartLoading(),
                      error: (e, _) => ChartError(message: e.toString()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PR timeline — full width.
                _DashCard(
                  title: s.prTimelineTitle,
                  child: prAsync.when(
                    data: (d) =>
                        d.isEmpty ? const _NoData() : PrTimeline(entries: d),
                    loading: () => const ChartLoading(),
                    error: (e, _) => ChartError(message: e.toString()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI strip ─────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.volume,
    required this.prCount,
    required this.workoutCount,
  });

  final List<WeeklyVolume> volume;
  final int prCount;
  final int workoutCount;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final totalVolume = volume.fold<double>(0, (sum, w) => sum + w.totalVolume);
    final avgSession = workoutCount > 0 ? totalVolume / workoutCount : 0.0;

    return KpiStrip(
      tiles: [
        KineticStatTile(
          label: s.desktopTotalVolume,
          value: _formatKg(totalVolume),
          unit: 'kg',
          valueSize: 26,
        ),
        KineticStatTile(
          label: s.desktopWorkoutsLabel,
          value: '$workoutCount',
          valueSize: 26,
        ),
        KineticStatTile(
          label: s.desktopAvgSessionLabel,
          value: _formatKg(avgSession),
          unit: 'kg',
          valueSize: 26,
        ),
        KineticStatTile(
          label: s.desktopPrsLabel,
          value: '$prCount',
          valueSize: 26,
        ),
      ],
    );
  }
}

// ── Layout helpers ────────────────────────────────────────────────────────

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KineticText.display(
              size: 16,
              weight: FontWeight.w700,
              letterSpacing: -0.2,
              color: cs.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          s.noAnalyticsData,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

String _formatKg(double kg) {
  final rounded = kg.round();
  if (rounded >= 1000) {
    final thousands = rounded ~/ 1000;
    final remainder = (rounded % 1000).toString().padLeft(3, '0');
    return '$thousands,$remainder';
  }
  return rounded.toString();
}
