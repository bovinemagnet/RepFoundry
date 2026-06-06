import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../screens/create_exercise_screen.dart';
import '../screens/edit_exercise_screen.dart';
import '../widgets/exercise_list_tile.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final _searchQueryProvider = NotifierProvider<_SearchQueryNotifier, String>(
  _SearchQueryNotifier.new,
);

class _SelectedMuscleGroupNotifier extends Notifier<MuscleGroup?> {
  @override
  MuscleGroup? build() => null;
  void set(MuscleGroup? value) => state = value;
}

final _selectedMuscleGroupProvider =
    NotifierProvider<_SelectedMuscleGroupNotifier, MuscleGroup?>(
  _SelectedMuscleGroupNotifier.new,
);

final _filteredExercisesProvider =
    FutureProvider.autoDispose<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final query = ref.watch(_searchQueryProvider);
  final group = ref.watch(_selectedMuscleGroupProvider);

  if (query.isNotEmpty) {
    return repo.searchExercises(query);
  }
  if (group != null) {
    return repo.getExercisesByMuscleGroup(group);
  }
  return repo.getAllExercises();
});

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final exercisesAsync = ref.watch(_filteredExercisesProvider);
    final selectedGroup = ref.watch(_selectedMuscleGroupProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      // Custom picker header (.pkhead) — back button tile + title.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: _PickerHeader(title: s.chooseExercise),
            ),
            // Search field (.search).
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: _SearchField(
                controller: _searchController,
                hint: s.searchExercisesHint,
                onChanged: (value) =>
                    ref.read(_searchQueryProvider.notifier).set(value),
                onClear: () {
                  _searchController.clear();
                  ref.read(_searchQueryProvider.notifier).set('');
                },
              ),
            ),
            // Filter chips (.fchips) — bleeds to screen edges.
            _MuscleGroupFilterBar(selectedGroup: selectedGroup),
            const SizedBox(height: 8),
            // Exercise list.
            Expanded(
              child: exercisesAsync.when(
                data: (exercises) => exercises.isEmpty
                    ? Center(child: Text(s.noExercisesFound))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 96),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Hairline divider between rows (.exrow + .exrow).
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: cs.outlineVariant,
                                ),
                              ExerciseListTile(
                                exercise: exercise,
                                onTap: () =>
                                    Navigator.of(context).pop(exercise),
                                trailing: exercise.isCustom
                                    ? IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () =>
                                            _editExercise(context, exercise),
                                      )
                                    : const Icon(Icons.chevron_right),
                              ),
                            ],
                          );
                        },
                      ),
                loading: () => LoadingWidget(message: s.loadingExercises),
                error: (e, _) =>
                    Center(child: Text(s.errorPrefix(e.toString()))),
              ),
            ),
          ],
        ),
      ),
      // "+ Custom" FAB in ghost variant (.fab--ghost).
      floatingActionButton: _GhostFab(
        label: s.customExercise,
        onPressed: () => _showCreateExerciseDialog(context),
      ),
    );
  }

  Future<void> _editExercise(BuildContext context, Exercise exercise) async {
    final updated = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => EditExerciseScreen(exercise: exercise),
      ),
    );

    if (updated != null) {
      ref.invalidate(_filteredExercisesProvider);
    }
  }

  Future<void> _showCreateExerciseDialog(BuildContext context) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => const CreateExerciseScreen(),
      ),
    );

    if (exercise != null && mounted) {
      Navigator.of(this.context).pop(exercise);
    }
  }
}

// ─── Picker header (.pkhead) ──────────────────────────────────────────────────

/// Back-button tile + screen title.  Mirrors rf.css `.pkhead`.
class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 38 px rounded tile (.pkhead__back).
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          // Screen title (.pkhead__t).
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.19,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search field (.search) ───────────────────────────────────────────────────

/// Styled search row.  Mirrors rf.css `.search`.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextField(
        controller: controller,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            fontSize: 14,
            color: cs.outline,
          ),
          prefixIcon: Icon(Icons.search, size: 20, color: cs.outline),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: cs.outline),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Filter chips (.fchips) ───────────────────────────────────────────────────

/// Horizontal scrolling filter-chip bar.  Bleeds to screen edges via negative
/// horizontal margin.  Mirrors rf.css `.fchips` / `.fchip` / `.fchip--on`.
///
/// Uses Flutter [FilterChip] so that the widget tests can locate chips by type
/// and check the [FilterChip.selected] property.
class _MuscleGroupFilterBar extends ConsumerWidget {
  const _MuscleGroupFilterBar({required this.selectedGroup});

  final MuscleGroup? selectedGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    const groups = MuscleGroup.values;

    // Shared chip shape — pill radius.
    const chipShape = StadiumBorder();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Bleed to screen edges: negative horizontal margin offset by 22 px.
        padding: const EdgeInsets.fromLTRB(22, 2, 22, 4),
        itemCount: groups.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isActive = isAll
              ? selectedGroup == null
              : groups[index - 1] == selectedGroup;
          final labelColour = isActive ? cs.onPrimary : cs.onSurfaceVariant;

          // Chip label text style (.fchip = mono 12/700, letter-spacing 0.02em).
          final labelTextStyle = GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.24,
            color: labelColour,
            fontFeatures: const [FontFeature.tabularFigures()],
          );

          // Active (.fchip--on): accent fill, no border.
          // Inactive (.fchip): transparent bg, 1.5 px outlineVariant border.
          final activeSide = BorderSide.none;
          final inactiveSide = BorderSide(color: cs.outlineVariant, width: 1.5);

          if (isAll) {
            return FilterChip(
              label: Text(s.filterAll, style: labelTextStyle),
              selected: selectedGroup == null,
              // Check icon for the active "All" chip (.fchip--on + check icon).
              avatar: isActive
                  ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                  : null,
              showCheckmark: false,
              backgroundColor: Colors.transparent,
              selectedColor: cs.primary,
              side: isActive ? activeSide : inactiveSide,
              shape: chipShape,
              onSelected: (_) {
                ref.read(_selectedMuscleGroupProvider.notifier).set(null);
              },
            );
          }

          final group = groups[index - 1];
          final groupActive = group == selectedGroup;
          return FilterChip(
            label: Text(group.name, style: labelTextStyle),
            selected: groupActive,
            showCheckmark: false,
            backgroundColor: Colors.transparent,
            selectedColor: cs.primary,
            side: groupActive ? activeSide : inactiveSide,
            shape: chipShape,
            onSelected: (_) {
              ref.read(_selectedMuscleGroupProvider.notifier).set(group);
            },
          );
        },
      ),
    );
  }
}

// ─── Ghost FAB (.fab--ghost) ──────────────────────────────────────────────────

/// "+ Custom" FAB in the ghost variant.  Mirrors rf.css `.fab--ghost`:
/// surfaceContainer background, text colour.
class _GhostFab extends StatelessWidget {
  const _GhostFab({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: cs.surfaceContainer,
      foregroundColor: cs.onSurface,
      elevation: 2,
      icon: const Icon(Icons.add),
      label: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
