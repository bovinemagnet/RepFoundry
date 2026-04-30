import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../domain/models/stretching_session.dart';
import 'add_stretching_sheet.dart';
import 'stretching_entry_tile.dart';

/// Active-workout section listing stretching entries for the current workout
/// plus an Add Stretching CTA. Hidden when there is no active workout.
class StretchingSection extends ConsumerWidget {
  const StretchingSection({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sessionsAsync =
        ref.watch(stretchingSessionsForWorkoutProvider(workoutId));

    final sessions = sessionsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <StretchingSession>[],
    );

    // Untimed entries are excluded from the minute total — by definition
    // they have no recorded duration.
    final timedSessions = sessions
        .where((sn) => sn.entryMethod != StretchingEntryMethod.untimed);
    final totalSeconds =
        timedSessions.fold<int>(0, (sum, sn) => sum + sn.durationSeconds);
    final totalMinutes = (totalSeconds / 60).round();
    final hasAnyTimed = timedSessions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.self_improvement, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.stretchingSectionTitle,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (sessions.isNotEmpty)
                  Text(
                    hasAnyTimed
                        ? '${s.stretchingEntriesCount(sessions.length)} · '
                            '${s.stretchingTotalMinutes(totalMinutes.toString())}'
                        : s.stretchingEntriesCount(sessions.length),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (sessions.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.stretchingEmptySubtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ] else ...[
              const SizedBox(height: 8),
              for (final session in sessions)
                StretchingEntryTile(
                  session: session,
                  onDelete: () => _confirmDelete(context, ref, session),
                ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => AddStretchingSheet.show(context, workoutId),
                icon: const Icon(Icons.add),
                label: Text(
                  sessions.isEmpty ? s.addStretching : s.addStretchingShort,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StretchingSession session,
  ) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteStretchingTitle),
        content: Text(s.deleteStretchingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(deleteStretchingSessionUseCaseProvider)
          .execute(session.id);
    }
  }
}
