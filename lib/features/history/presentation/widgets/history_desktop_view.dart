import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/bar_sparkline_widget.dart';
import '../../../../core/widgets/desktop_top_bar.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../../core/widgets/kpi_strip.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../providers/workout_history_provider.dart';

/// Desktop "power layout" for History — a master–detail split: a filterable
/// session list on the left and the selected workout's full breakdown on the
/// right. Selection is handled in-pane (no route navigation), so the rail and
/// list stay put while you browse sessions.
class HistoryDesktopView extends ConsumerStatefulWidget {
  const HistoryDesktopView({super.key});

  @override
  ConsumerState<HistoryDesktopView> createState() => _HistoryDesktopViewState();
}

class _HistoryDesktopViewState extends ConsumerState<HistoryDesktopView> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(workoutHistoryWithSetsProvider);

    return Scaffold(
      body: Column(
        children: [
          DesktopTopBar(
            eyebrow: s.lastWeek,
            title: s.trainingHistoryTitle,
            subtitle: s.trainingHistorySubtitle,
            actions: [
              _TopBarIconButton(
                icon: Icons.emoji_events_outlined,
                tooltip: s.prHistoryTitle,
                onPressed: () => context.push('/pr-history'),
              ),
            ],
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => LoadingWidget(message: s.loadingHistory),
              error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
              data: (items) {
                if (items.isEmpty) return _EmptyHistory();

                // Default selection: most recent session.
                final selected = items.firstWhere(
                  (w) => w.workout.id == _selectedId,
                  orElse: () => items.first,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Master list shrinks with the pane so the layout survives
                    // a forced-desktop view on a narrow tablet.
                    final masterWidth =
                        (constraints.maxWidth * 0.42).clamp(0.0, 420.0);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: masterWidth,
                          child: _SessionList(
                            items: items,
                            selectedId: selected.workout.id,
                            onSelect: (id) => setState(() => _selectedId = id),
                          ),
                        ),
                        Container(width: 1, color: cs.outlineVariant),
                        Expanded(child: _DetailPane(item: selected)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left pane: session list ───────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final List<WorkoutWithSets> items;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: KineticSectionLabel(
              '${s.desktopSessionsLabel} · ${items.length}'),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SessionRow(
              item: item,
              selected: item.workout.id == selectedId,
              onTap: () => onSelect(item.workout.id),
            ),
          ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final WorkoutWithSets item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final duration = item.durationMinutes;
    final meta = duration != null
        ? '${duration}m · ${_formatKg(item.totalVolume)} kg'
        : '${_formatKg(item.totalVolume)} kg';

    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.12)
          : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.workoutFallbackName,
                      style: KineticText.display(
                        size: 16,
                        weight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              KineticPill(
                item.workout.startedAt.toLocal().relativeLabel,
                variant: KineticPillVariant.ghost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Right pane: workout detail ────────────────────────────────────────────

class _DetailPane extends ConsumerWidget {
  const _DetailPane({required this.item});

  final WorkoutWithSets item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final lookupAsync = ref.watch(exerciseLookupProvider);
    final lookup = lookupAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <String, Exercise>{},
    );

    final duration = item.durationMinutes;
    final setVolumes = item.sets.map((set) => set.volume).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 40),
      children: [
        // Header.
        Text(
          s.workoutFallbackName,
          style: KineticText.display(
            size: 24,
            weight: FontWeight.w700,
            letterSpacing: -0.4,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.workout.startedAt.toLocal().weekdayMonthDay,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),

        // KPI strip (reflows 4 → 2 → 1 columns as the pane narrows).
        KpiStrip(
          tiles: [
            KineticStatTile(
              label: s.desktopVolumeLabel,
              value: _formatKg(item.totalVolume),
              unit: 'kg',
              valueSize: 26,
            ),
            KineticStatTile(
              label: s.desktopDurationLabel,
              value: duration != null ? '$duration' : '—',
              unit: duration != null ? 'min' : null,
              valueSize: 26,
            ),
            KineticStatTile(
              label: s.desktopSetsLabel,
              value: '${item.setCount}',
              valueSize: 26,
            ),
            KineticStatTile(
              label: s.desktopExercisesLabel,
              value: '${item.exerciseCount}',
              valueSize: 26,
            ),
          ],
        ),

        if (setVolumes.length > 1) ...[
          const SizedBox(height: 26),
          KineticSectionLabel(s.desktopPerSetVolume),
          const SizedBox(height: 14),
          SizedBox(height: 120, child: BarSparklineWidget(data: setVolumes)),
        ],

        const SizedBox(height: 26),
        KineticSectionLabel(s.desktopExerciseBreakdown),
        const SizedBox(height: 14),
        ..._buildBreakdown(context, lookup),
      ],
    );
  }

  List<Widget> _buildBreakdown(
    BuildContext context,
    Map<String, Exercise> lookup,
  ) {
    // Group sets by exercise, preserving first-seen order.
    final order = <String>[];
    final byExercise = <String, List<WorkoutSet>>{};
    for (final set in item.sets) {
      byExercise.putIfAbsent(set.exerciseId, () {
        order.add(set.exerciseId);
        return <WorkoutSet>[];
      }).add(set);
    }

    return [
      for (final exerciseId in order)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ExerciseBreakdownCard(
            name: lookup[exerciseId]?.name ?? '—',
            sets: byExercise[exerciseId]!,
          ),
        ),
    ];
  }
}

class _ExerciseBreakdownCard extends StatelessWidget {
  const _ExerciseBreakdownCard({required this.name, required this.sets});

  final String name;
  final List<WorkoutSet> sets;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bestE1rm = sets.fold<double>(
      0,
      (best, set) =>
          set.estimatedOneRepMax > best ? set.estimatedOneRepMax : best,
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: KineticText.display(
                    size: 16,
                    weight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                ),
              ),
              KineticPill(
                'e1RM ${bestE1rm.toStringAsFixed(0)}',
                variant: KineticPillVariant.volt,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < sets.length; i++)
                _SetChip(index: i + 1, set: sets[i]),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({required this.index, required this.set});

  final int index;
  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warm = set.isWarmUp;
    final reps = set.reps;
    final weight = set.weight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: warm ? cs.surfaceContainerHigh : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${warm ? 'W' : index} · ${_trimWeight(weight)}kg · ×$reps'
        '${set.rpe != null ? ' · @${set.rpe!.toStringAsFixed(0)}' : ''}',
        style: KineticText.mono(
          size: 12,
          weight: FontWeight.w600,
          color: warm ? cs.onSurfaceVariant : cs.onSurface,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 72, color: cs.outline),
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

// ── Shared bits ───────────────────────────────────────────────────────────

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
          ),
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

String _trimWeight(double weight) {
  if (weight == weight.roundToDouble()) return weight.toStringAsFixed(0);
  return weight.toStringAsFixed(1);
}
