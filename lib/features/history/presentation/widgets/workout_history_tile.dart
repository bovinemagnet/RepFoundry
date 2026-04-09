import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../domain/models/personal_record.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/widgets/bar_sparkline_widget.dart';

class WorkoutHistoryTile extends StatelessWidget {
  const WorkoutHistoryTile({
    super.key,
    required this.workout,
    required this.setCount,
    this.personalRecord,
    this.onTap,
    this.workoutName,
    this.totalVolume,
    this.sparklineData,
  });

  final Workout workout;
  final int setCount;
  final PersonalRecord? personalRecord;
  final VoidCallback? onTap;
  final String? workoutName;
  final double? totalVolume;
  final List<double>? sparklineData;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final duration = workout.completedAt != null
        ? workout.startedAt.durationUntil(workout.completedAt!)
        : null;
    final name = workoutName ?? s.workoutFallbackName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // PR corner accent.
              if (personalRecord != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Transform.rotate(
                    angle: 0.785, // 45 degrees
                    child: Container(
                      width: 32,
                      height: 32,
                      color: cs.tertiary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Workout name + date pill.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DatePill(date: workout.startedAt.toLocal()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: Metric chips.
                    Row(
                      children: [
                        if (duration != null)
                          _MetricChip(
                            icon: Icons.schedule,
                            label: duration,
                          ),
                        if (duration != null) const SizedBox(width: 12),
                        _MetricChip(
                          icon: Icons.fitness_center,
                          label: totalVolume != null
                              ? s.totalVolumeKg(
                                  totalVolume!.toStringAsFixed(0))
                              : s.setsCount(setCount),
                        ),
                        if (personalRecord != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.prBadge,
                              style: tt.labelSmall?.copyWith(
                                color: cs.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Row 3: Embedded sparkline area.
                    if (sparklineData != null &&
                        sparklineData!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  s.volumeProgress.toUpperCase(),
                                  style: tt.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: BarSparklineWidget(
                                data: sparklineData!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        date.weekdayMonthDay.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}
