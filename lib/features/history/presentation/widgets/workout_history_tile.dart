import 'package:flutter/material.dart';
import '../../domain/models/personal_record.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../../core/extensions/datetime_extensions.dart';

class WorkoutHistoryTile extends StatelessWidget {
  const WorkoutHistoryTile({
    super.key,
    required this.workout,
    required this.setCount,
    this.personalRecord,
    this.onTap,
  });

  final Workout workout;
  final int setCount;
  final PersonalRecord? personalRecord;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final duration = workout.completedAt != null
        ? workout.startedAt.durationUntil(workout.completedAt!)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    workout.startedAt.toLocal().relativeLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    workout.startedAt.toLocal().timeOfDay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.fitness_center,
                    label: '$setCount sets',
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: duration,
                    ),
                  ],
                  if (personalRecord != null) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.emoji_events,
                      label: 'PR!',
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: effectiveColor,
              ),
        ),
      ],
    );
  }
}
