import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../controllers/active_workout_controller.dart';
import '../models/ghost_set.dart';
import '../widgets/pr_celebration_overlay.dart';
import '../widgets/edit_set_dialog.dart';
import '../widgets/set_input_card.dart';
import '../widgets/rest_timer_widget.dart';
import '../../domain/models/workout_set.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../programmes/domain/models/programme.dart';
import '../../../stretching/presentation/widgets/add_stretching_sheet.dart';
import '../../../stretching/presentation/widgets/stretching_section.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/units/weight_unit_provider.dart';
import '../../../../core/widgets/horizontal_swipe_navigator.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/sparkline_widget.dart';

final _templatePickerProvider =
    StreamProvider.autoDispose<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).watchAllTemplates();
});

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      ActiveWorkoutScreenState();
}

@visibleForTesting
class ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _exerciseKeys = {};

  /// ID of the most recently added exercise. Used by SetInputCard to
  /// autofocus its Weight field so the new exercise becomes the active
  /// input target instead of leaving focus on the prior exercise.
  String? _lastAddedExerciseId;

  /// ID of the exercise whose set-input card is currently expanded, or null
  /// when none is expanded. Only one exercise shows its input at a time so the
  /// screen is not crowded with multiple "Log Set" buttons. Adding an exercise
  /// expands it (collapsing any previous); the collapse control on the
  /// expanded card returns to the all-collapsed state.
  String? _expandedExerciseId;

  /// Whether the soft keyboard is currently open. Drives hiding the
  /// "Add Exercise" FAB so it cannot overlap the Log Set CTA. Read from the
  /// raw [FlutterView] insets (not [MediaQuery]) because the enclosing
  /// ScaffoldWithNavBar consumes the bottom viewInset for its body, leaving
  /// MediaQuery.viewInsetsOf permanently 0 for this screen.
  bool _keyboardVisible = false;

  @visibleForTesting
  ScrollController get scrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final visible = View.of(context).viewInsets.bottom > 0;
    if (visible != _keyboardVisible) {
      setState(() => _keyboardVisible = visible);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String exerciseId) =>
      _exerciseKeys.putIfAbsent(exerciseId, () => GlobalKey());

  void _pruneStaleKeys(List<String> currentExerciseIds) {
    final live = currentExerciseIds.toSet();
    _exerciseKeys.removeWhere((id, _) => !live.contains(id));
  }

  void _scrollToExercise(String exerciseId, {required double alignment}) {
    final ctx = _exerciseKeys[exerciseId]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: alignment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @visibleForTesting
  void scrollToExercise(String exerciseId, {required double alignment}) =>
      _scrollToExercise(exerciseId, alignment: alignment);

  @visibleForTesting
  Future<void> handleAddExercise(Exercise exercise) async {
    await ref
        .read(activeWorkoutControllerProvider.notifier)
        .addExercise(exercise);
    if (!mounted) return;
    setState(() {
      _lastAddedExerciseId = exercise.id;
      _expandedExerciseId = exercise.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToExercise(exercise.id, alignment: 1.0);
    });
  }

  /// Expands [exerciseId]'s set-input card, collapsing any other. Called when
  /// the user taps a collapsed exercise's "Add Set" affordance.
  void _expandExercise(String exerciseId) {
    if (_expandedExerciseId == exerciseId) return;
    setState(() => _expandedExerciseId = exerciseId);
  }

  /// Collapses the currently expanded set-input card and dismisses the
  /// keyboard — the "finish logging" action requested via the close button.
  void _collapseExercise() {
    FocusScope.of(context).unfocus();
    setState(() => _expandedExerciseId = null);
  }

  @visibleForTesting
  void handleLogSet({
    required String exerciseId,
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp = false,
  }) {
    ref
        .read(activeWorkoutControllerProvider.notifier)
        .logSet(
          exerciseId: exerciseId,
          weight: weight,
          reps: reps,
          rpe: rpe,
          isWarmUp: isWarmUp,
        )
        .then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToExercise(exerciseId, alignment: 1.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final state = ref.watch(activeWorkoutControllerProvider);
    final controller = ref.read(activeWorkoutControllerProvider.notifier);

    _pruneStaleKeys(state.exercises.map((e) => e.id).toList());

    ref.listen<ActiveWorkoutState>(
      activeWorkoutControllerProvider,
      (previous, next) {
        if (previous?.latestPR == null && next.latestPR != null) {
          _showPRCelebration(context, ref, next);
        }
      },
    );

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        controller.clearError();
      });
    }

    // The Scaffold has no AppBar; the Kinetic header is rendered inline.
    // The FAB is preserved as FloatingActionButton.extended so widget tests
    // can locate it with find.byType(FloatingActionButton).
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        // Swipe left to jump to the heart rate panel (issue #71).
        child: HorizontalSwipeNavigator(
          onSwipeLeft: () => context.go('/heart-rate'),
          child: state.isLoading
              ? LoadingWidget(message: s.loadingWorkout)
              : state.hasActiveWorkout
                  ? _buildActiveWorkout(context, ref, state, controller)
                  : _buildNoWorkout(context, ref, controller),
        ),
      ),
      floatingActionButton: state.hasActiveWorkout && !_keyboardVisible
          ? FloatingActionButton.extended(
              onPressed: () => _pickExercise(context, ref),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 6,
              icon: const Icon(Icons.add),
              label: Text(
                s.addExercise,
                style: KineticText.display(size: 13),
              ),
            )
          : null,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NO-WORKOUT (idle) state — Kinetic "Ready to train?" layout (screen 01).
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNoWorkout(
    BuildContext context,
    WidgetRef ref,
    ActiveWorkoutController controller,
  ) {
    final s = S.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KineticAppHeader(),
          // Idle hero: icon tile + eyebrow + title + sub
          _KineticIdleHero(eyebrowLabel: s.noActiveWorkout),
          const SizedBox(height: 20),
          // Primary start card (accent-filled CTA)
          _KineticStartCard(
            onPressed: controller.startWorkout,
            label: s.startWorkout,
          ),
          const SizedBox(height: 20),
          // "Or start from" — no dedicated ARB key; use inline design copy.
          const KineticSectionLabel('Or start from'),
          const SizedBox(height: 12),
          // Entry-point rows
          _KineticStartRow(
            icon: Icons.self_improvement,
            title: s.startStretching,
            subtitle: 'Mobility, warm-up or cool-down',
            onTap: () => _startStretchingSession(context, ref),
          ),
          const SizedBox(height: 8),
          _KineticStartRow(
            icon: Icons.view_list,
            title: s.startFromTemplate,
            subtitle: 'Reuse a saved workout',
            onTap: () => _showTemplatePicker(context, ref),
          ),
          const SizedBox(height: 8),
          _KineticStartRow(
            icon: Icons.calendar_month,
            title: s.startFromProgramme,
            subtitle: 'Follow your training plan',
            onTap: () => _showProgrammePicker(context, ref),
          ),
          const SizedBox(height: 28),
          // Tonal background for bottom of scroll
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 20,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE WORKOUT — dispatches to empty or populated sub-builds.
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActiveWorkout(
    BuildContext context,
    WidgetRef ref,
    ActiveWorkoutState state,
    ActiveWorkoutController controller,
  ) {
    if (state.exercises.isEmpty) {
      return _buildEmptyActiveWorkout(context, state, controller);
    }
    return _buildPopulatedActiveWorkout(context, state, controller);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMPTY ACTIVE SESSION — screen 03.
  // wkHeader + restTimer + stretchCard + dashed-ring empty prompt.
  // The FAB (scaffold-level) provides "+ Add Exercise".
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyActiveWorkout(
    BuildContext context,
    ActiveWorkoutState state,
    ActiveWorkoutController controller,
  ) {
    final s = S.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Workout header with live dot and Finish pill
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: _KineticWorkoutHeader(
            startedAt: state.activeWorkout!.startedAt,
            onFinish: () => _confirmFinish(context, controller),
            isLoading: state.isLoading,
          ),
        ),
        // Rest timer bar
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: RestTimerWidget(),
        ),
        // Stretching card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: StretchingSection(workoutId: state.activeWorkout!.id),
        ),
        // Empty prompt: dashed ring + hint text
        Expanded(
          child: Center(
            child: _KineticEmptyPrompt(hint: s.addExercisesHint),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POPULATED ACTIVE SESSION — screen 02 Kinetic layout.
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPopulatedActiveWorkout(
    BuildContext context,
    ActiveWorkoutState state,
    ActiveWorkoutController controller,
  ) {
    final s = S.of(context)!;

    final supersetGroups = getSupersetGroups(state.setsByExercise);
    final supersetExerciseIds =
        supersetGroups.values.expand((ids) => ids).toSet();
    final renderedGroups = <String>{};

    // Compute total session volume for the hero readout.
    final totalVolumeKg = state.setsByExercise.values
        .expand((sets) => sets)
        .fold<double>(0.0, (acc, set) => acc + set.weight * set.reps);

    final totalSets =
        state.setsByExercise.values.fold<int>(0, (a, s) => a + s.length);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 104),
      // Build all exercise sections even when off-screen so GlobalKey
      // contexts are available for auto-scroll. ~30 sections × ~330 px each.
      // ignore: deprecated_member_use
      cacheExtent: 9999,
      children: [
        // ── Kinetic header (not AppBar) ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: _KineticWorkoutHeader(
            startedAt: state.activeWorkout!.startedAt,
            onFinish: () => _confirmFinish(context, controller),
            isLoading: state.isLoading,
          ),
        ),
        // ── Rest timer ──────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: RestTimerWidget(),
        ),
        // ── Eyebrow: session phase ───────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 0),
          child: KineticEyebrow('Active Session'),
        ),
        // ── Volume hero ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: _KineticVolumeHero(
            volumeKg: totalVolumeKg,
            totalSets: totalSets,
            exerciseCount: state.exercises.length,
          ),
        ),
        // ── Area chart (volume sparkline) ────────────────────────────
        if (totalVolumeKg > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
            child: SizedBox(
              height: 80,
              child: SparklineWidget(
                data: _buildVolumeSeriesNormalised(state),
                lineColor: Theme.of(context).colorScheme.primary,
                fillColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.22),
                strokeWidth: 2.5,
              ),
            ),
          ),
        const SizedBox(height: 18),
        // ── Exercise sections ────────────────────────────────────────
        for (final exercise in state.exercises) ...[
          if (supersetExerciseIds.contains(exercise.id)) ...[
            () {
              final groupId =
                  state.setsByExercise[exercise.id]?.firstOrNull?.groupId;
              if (groupId != null && !renderedGroups.contains(groupId)) {
                renderedGroups.add(groupId);
                final groupExerciseIds = supersetGroups[groupId]!;
                final groupExercises = state.exercises
                    .where((e) => groupExerciseIds.contains(e.id))
                    .toList();
                return _SupersetGroup(
                  exercises: groupExercises,
                  state: state,
                  controller: controller,
                  onUnlink: (exerciseId) =>
                      controller.unlinkSuperset(exerciseId),
                  exerciseKeys: _exerciseKeys,
                  onLogSet: handleLogSet,
                  autofocusExerciseId: _lastAddedExerciseId,
                  expandedExerciseId: _expandedExerciseId,
                  onExpand: _expandExercise,
                  onCollapse: _collapseExercise,
                );
              }
              return const SizedBox.shrink();
            }(),
          ] else ...[
            KeyedSubtree(
              key: _keyFor(exercise.id),
              child: _ExerciseSection(
                exercise: exercise,
                sets: state.setsByExercise[exercise.id] ?? [],
                ghostSets: state.remainingGhosts(exercise.id),
                suggestion: state.nextGhostSet(exercise.id),
                autofocusWeight: exercise.id == _lastAddedExerciseId,
                expanded: exercise.id == _expandedExerciseId,
                onExpand: () => _expandExercise(exercise.id),
                onCollapse: _collapseExercise,
                onLogSet: ({
                  required double weight,
                  required int reps,
                  double? rpe,
                  bool isWarmUp = false,
                }) {
                  handleLogSet(
                    exerciseId: exercise.id,
                    weight: weight,
                    reps: reps,
                    rpe: rpe,
                    isWarmUp: isWarmUp,
                  );
                },
                onDeleteSet: (setId) =>
                    controller.deleteSet(setId, exercise.id),
                onEditSet: (updatedSet) => controller.updateSet(updatedSet),
                onLinkSuperset: () =>
                    _showSupersetPicker(context, ref, exercise, state),
              ),
            ),
          ],
        ],
        const SizedBox(height: 10),
        // ── Stretching section ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: StretchingSection(workoutId: state.activeWorkout!.id),
        ),
        const SizedBox(height: 16),
        // ── Complete Workout CTA ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: KineticCta(
            label: s.finishWorkoutTitle,
            icon: Icons.bolt,
            iconAfter: true,
            onPressed: state.isLoading
                ? null
                : () => _confirmFinish(context, controller),
          ),
        ),
      ],
    );
  }

  /// Builds a normalised 0–1 volume series for the sparkline, one entry per
  /// exercise section, using cumulative logged set count as a proxy.
  List<double> _buildVolumeSeriesNormalised(ActiveWorkoutState state) {
    final counts = state.exercises
        .map((e) => (state.setsByExercise[e.id]?.length ?? 0).toDouble())
        .toList();
    if (counts.isEmpty) return [];
    double cumulative = 0;
    final series = <double>[];
    for (final c in counts) {
      cumulative += c;
      series.add(cumulative);
    }
    final max = series.last;
    if (max == 0) return series.map((_) => 0.0).toList();
    return series.map((v) => v / max).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation helpers (unchanged from original)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await context.push<Exercise>('/exercises');
    if (exercise != null && mounted) {
      await handleAddExercise(exercise);
    }
  }

  Future<void> _startStretchingSession(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = ref.read(activeWorkoutControllerProvider.notifier);
    await controller.startWorkout();
    if (!context.mounted) return;
    final workoutId =
        ref.read(activeWorkoutControllerProvider).activeWorkout?.id;
    if (workoutId != null) {
      await AddStretchingSheet.show(context, workoutId);
    }
  }

  void _showTemplatePicker(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    showModalBottomSheet<WorkoutTemplate>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final templatesAsync = ref.watch(_templatePickerProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.chooseTemplate,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(s.noTemplatesAvailable),
                    );
                  }
                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (ctx, index) {
                        final template = templates[index];
                        return ListTile(
                          leading: const Icon(Icons.view_list),
                          title: Text(template.name),
                          subtitle: Text(
                            s.exerciseCount(template.exercises.length),
                          ),
                          onTap: () => Navigator.pop(ctx, template),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(s.noTemplatesAvailable),
                ),
              ),
            ],
          );
        },
      ),
    ).then((template) {
      if (template != null) {
        ref
            .read(activeWorkoutControllerProvider.notifier)
            .startFromTemplate(template);
      }
    });
  }

  void _showProgrammePicker(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    showModalBottomSheet<Programme>(
      context: context,
      builder: (ctx) => FutureBuilder<List<Programme>>(
        future: ref.read(programmeRepositoryProvider).getAllProgrammes(),
        builder: (ctx, snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.chooseProgramme,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(s.noProgrammesAvailable),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (ctx, index) {
                      final programme = snapshot.data![index];
                      return ListTile(
                        leading: const Icon(Icons.calendar_month),
                        title: Text(programme.name),
                        subtitle: Text(
                          s.programmeDaysCount(programme.days.length),
                        ),
                        onTap: () => Navigator.pop(ctx, programme),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ).then((programme) async {
      if (programme != null) {
        final started = await ref
            .read(activeWorkoutControllerProvider.notifier)
            .startFromProgramme(programme);
        if (!started && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.noWorkoutScheduledForToday)),
          );
        }
      }
    });
  }

  void _showPRCelebration(
    BuildContext context,
    WidgetRef ref,
    ActiveWorkoutState state,
  ) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => PRCelebrationOverlay(
        exerciseName: state.latestPRExerciseName ?? 'Exercise',
        value: state.latestPR!.value,
        recordType: state.latestPR!.recordType,
        unit: ref.read(weightUnitProvider),
        onDismiss: () {
          entry.remove();
          ref.read(activeWorkoutControllerProvider.notifier).clearPR();
        },
      ),
    );
    overlay.insert(entry);
  }

  void _showSupersetPicker(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
    ActiveWorkoutState state,
  ) {
    final s = S.of(context)!;
    final otherExercises =
        state.exercises.where((e) => e.id != exercise.id).toList();
    final supersetGroups = getSupersetGroups(state.setsByExercise);
    final supersetExerciseIds =
        supersetGroups.values.expand((ids) => ids).toSet();
    final available = otherExercises
        .where((e) => !supersetExerciseIds.contains(e.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.noOtherExercises)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              s.selectSupersetPartner,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          for (final other in available)
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(other.name),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(activeWorkoutControllerProvider.notifier)
                    .linkSuperset(exercise.id, other.id);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmFinish(
    BuildContext context,
    ActiveWorkoutController controller,
  ) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.finishWorkoutTitle),
        content: Text(s.finishWorkoutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.finish),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.finishWorkout();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIVATE SMALL WIDGETS — Kinetic design atoms for this screen only.
// ═══════════════════════════════════════════════════════════════════════════

/// Idle hero section: large icon tile, eyebrow, title, sub-copy.
/// Mirrors the centred hero block in `screenStart()`.
///
/// The [eyebrowLabel] is displayed as-is (not uppercased) so that widget
/// tests can locate the exact localised string with `find.text(...)`.
class _KineticIdleHero extends StatelessWidget {
  const _KineticIdleHero({required this.eyebrowLabel});

  /// Exact text shown in the eyebrow row — rendered without case conversion
  /// so that widget test finders using [find.text] can match it directly.
  final String eyebrowLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          // 84 px rounded-square tile with accent-soft bg + accent ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 40,
                  color: cs.primary,
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Eyebrow row — styled like rf.css .eyebrow but text is
          // preserved verbatim for widget-test findability.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrowLabel,
                style: KineticText.mono(
                  size: 11,
                  letterSpacing: 2.6,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 1,
                color: cs.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to train?',
            style: KineticText.display(size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            'Start fresh and log as you go, or pull in a saved plan.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Large accent-filled primary start card (mirrors the CSS `.cta`-inside card).
class _KineticStartCard extends StatelessWidget {
  const _KineticStartCard({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMPTY SESSION',
                    style: KineticText.mono(
                      size: 11,
                      letterSpacing: 1.8,
                      color: cs.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: KineticText.display(
                      size: 24,
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Build it live — add exercises & log sets',
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      color: cs.onPrimary.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.play_arrow,
                size: 28,
                color: cs.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single entry-point row: icon tile + title/subtitle + trailing arrow.
/// Mirrors `.srow` in `rf.css`.
class _KineticStartRow extends StatelessWidget {
  const _KineticStartRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // 42 px accent-soft icon tile
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KineticText.display(
                      size: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, size: 20, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

/// Inline workout header (replaces AppBar) for the active-session states.
/// Shows: live accent dot + "Workout · HH:MM AM/PM" + accent-soft Finish pill.
/// The "Finish" text must remain findable by widget tests.
class _KineticWorkoutHeader extends StatelessWidget {
  const _KineticWorkoutHeader({
    required this.startedAt,
    required this.onFinish,
    this.isLoading = false,
  });

  final DateTime startedAt;
  final VoidCallback onFinish;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          // Live pulsing dot
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.4),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // "Workout · time"
          Text(
            '${s.workoutTitle}  ·  ${startedAt.toLocal().timeOfDay}',
            style: KineticText.display(size: 16, color: cs.onSurface),
          ),
          const Spacer(),
          // Finish pill — keeps the "Finish" text widget for tests
          GestureDetector(
            onTap: isLoading ? null : onFinish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    s.finish,
                    style: KineticText.mono(
                      size: 12,
                      letterSpacing: 0.8,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Volume hero: mono 72/800 readout + set/exercise meta row.
/// Mirrors the volume hero block in `screenKinetic()`.
class _KineticVolumeHero extends ConsumerWidget {
  const _KineticVolumeHero({
    required this.volumeKg,
    required this.totalSets,
    required this.exerciseCount,
  });

  final double volumeKg;
  final int totalSets;
  final int exerciseCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context)!;
    final unit = ref.watch(weightUnitProvider);
    final volume = unit.fromKg(volumeKg);
    final volumeStr = volume >= 1000
        ? '${(volume / 1000).toStringAsFixed(1)}k'
        : volume.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Giant mono numeral + "kg" unit
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              volumeStr,
              style: KineticText.mono(
                size: 64,
                weight: FontWeight.w800,
                letterSpacing: -3.0,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                unit.label(s),
                style: KineticText.mono(
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Accent pill + mono meta
        Row(
          children: [
            const KineticPill(
              'Volume',
              icon: Icons.trending_up,
              variant: KineticPillVariant.accent,
            ),
            const SizedBox(width: 10),
            Text(
              '$totalSets SETS · $exerciseCount EXERCISES',
              style: KineticText.mono(
                size: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dashed-ring empty-state prompt for the active session with no exercises.
/// Mirrors `.empty` / `.empty__ring` in `rf.css`.
class _KineticEmptyPrompt extends StatelessWidget {
  const _KineticEmptyPrompt({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 72 px dashed ring with add icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: cs.outline,
              width: 2,
              // Dashed effect approximated via StrokeCap; a real dashed border
              // requires CustomPainter but a simple outline suffices here.
            ),
          ),
          child: Icon(
            Icons.add,
            size: 34,
            color: cs.outline,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hint,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXERCISE CARDS — Kinetic reskin of the per-exercise sections.
// ═══════════════════════════════════════════════════════════════════════════

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({
    required this.exercise,
    required this.sets,
    required this.ghostSets,
    required this.suggestion,
    required this.onLogSet,
    required this.onDeleteSet,
    required this.onEditSet,
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
    this.onLinkSuperset,
    this.autofocusWeight = false,
  });

  final Exercise exercise;
  final List<WorkoutSet> sets;
  final List<GhostSet> ghostSets;
  final GhostSet? suggestion;
  final void Function({
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;
  final void Function(String setId) onDeleteSet;
  final void Function(WorkoutSet updatedSet) onEditSet;
  final VoidCallback? onLinkSuperset;
  final bool autofocusWeight;

  /// Whether this exercise's set-input card is expanded.
  final bool expanded;

  /// Called when the collapsed "Add Set" affordance is tapped.
  final VoidCallback onExpand;

  /// Called when the expanded card's collapse control is tapped.
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: onLinkSuperset != null
          ? () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(s.linkAsSuperset),
                      onTap: () {
                        Navigator.pop(ctx);
                        onLinkSuperset!();
                      },
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(22),
            // 4 px accent left bar (matches the design's focused card style)
            border: Border(
              left: BorderSide(color: cs.primary, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: _ExerciseSectionContent(
            exercise: exercise,
            sets: sets,
            ghostSets: ghostSets,
            suggestion: suggestion,
            onLogSet: onLogSet,
            onDeleteSet: onDeleteSet,
            onEditSet: onEditSet,
            autofocusWeight: autofocusWeight,
            expanded: expanded,
            onExpand: onExpand,
            onCollapse: onCollapse,
          ),
        ),
      ),
    );
  }
}

class _ExerciseSectionContent extends ConsumerWidget {
  const _ExerciseSectionContent({
    required this.exercise,
    required this.sets,
    required this.ghostSets,
    required this.suggestion,
    required this.onLogSet,
    required this.onDeleteSet,
    required this.onEditSet,
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
    this.autofocusWeight = false,
  });

  final Exercise exercise;
  final List<WorkoutSet> sets;
  final List<GhostSet> ghostSets;
  final GhostSet? suggestion;
  final void Function({
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;
  final void Function(String setId) onDeleteSet;
  final void Function(WorkoutSet updatedSet) onEditSet;
  final bool autofocusWeight;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTableContent = sets.isNotEmpty || ghostSets.isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context)!;
    final unit = ref.watch(weightUnitProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise header row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: KineticText.display(size: 17, color: cs.onSurface),
                  ),
                  if (sets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.history,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Last: ${unit.formatFromKg(sets.last.weight)}'
                            '${unit.label(s)} × ${sets.last.reps}',
                            style: KineticText.mono(
                              size: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Muscle-group ghost pill
            KineticPill(
              exercise.muscleGroup.name,
              variant: KineticPillVariant.ghost,
            ),
            // Collapse ("finish logging") control — only while expanded.
            if (expanded) ...[
              const SizedBox(width: 8),
              _CollapseButton(onTap: onCollapse),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Set cards grid
        if (hasTableContent) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < sets.length; i++)
                _SetCard(
                  index: i,
                  set: sets[i],
                  onDelete: () => onDeleteSet(sets[i].id),
                  onEdit: onEditSet,
                ),
              for (int i = 0; i < ghostSets.length; i++)
                _GhostSetCard(
                  index: sets.length + i,
                  ghost: ghostSets[i],
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (expanded)
          SetInputCard(
            onLogSet: onLogSet,
            suggestion: suggestion,
            autofocusWeight: autofocusWeight,
            unit: unit,
          )
        else
          _AddSetButton(onTap: onExpand),
      ],
    );
  }
}

/// Compact accent-soft affordance shown in place of the full [SetInputCard]
/// when an exercise is collapsed. Tapping it expands the exercise for logging.
class _AddSetButton extends StatelessWidget {
  const _AddSetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: cs.primary.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              s.addSet.toUpperCase(),
              style: KineticText.mono(
                size: 12.5,
                letterSpacing: 0.8,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small ghost close control on an expanded exercise card — collapses the
/// set-input ("finish logging" for that exercise).
class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: s.collapse,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.keyboard_arrow_up,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SupersetGroup extends StatelessWidget {
  const _SupersetGroup({
    required this.exercises,
    required this.state,
    required this.controller,
    required this.onUnlink,
    required this.exerciseKeys,
    required this.onLogSet,
    required this.expandedExerciseId,
    required this.onExpand,
    required this.onCollapse,
    this.autofocusExerciseId,
  });

  final List<Exercise> exercises;
  final ActiveWorkoutState state;
  final ActiveWorkoutController controller;
  final void Function(String exerciseId) onUnlink;
  final Map<String, GlobalKey> exerciseKeys;
  final String? autofocusExerciseId;
  final String? expandedExerciseId;
  final void Function(String exerciseId) onExpand;
  final VoidCallback onCollapse;
  final void Function({
    required String exerciseId,
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.tertiary.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: cs.tertiaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14, color: cs.tertiary),
                  const SizedBox(width: 6),
                  Text(
                    s.supersetLabel.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: cs.tertiary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => onUnlink(exercises.first.id),
                    child: Icon(Icons.link_off, size: 16, color: cs.outline),
                  ),
                ],
              ),
            ),
            for (final exercise in exercises)
              KeyedSubtree(
                key: exerciseKeys.putIfAbsent(exercise.id, () => GlobalKey()),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ExerciseSectionContent(
                    exercise: exercise,
                    sets: state.setsByExercise[exercise.id] ?? [],
                    ghostSets: state.remainingGhosts(exercise.id),
                    suggestion: state.nextGhostSet(exercise.id),
                    autofocusWeight: exercise.id == autofocusExerciseId,
                    expanded: exercise.id == expandedExerciseId,
                    onExpand: () => onExpand(exercise.id),
                    onCollapse: onCollapse,
                    onLogSet: ({
                      required double weight,
                      required int reps,
                      double? rpe,
                      bool isWarmUp = false,
                    }) {
                      onLogSet(
                        exerciseId: exercise.id,
                        weight: weight,
                        reps: reps,
                        rpe: rpe,
                        isWarmUp: isWarmUp,
                      );
                    },
                    onDeleteSet: (setId) =>
                        controller.deleteSet(setId, exercise.id),
                    onEditSet: (updatedSet) => controller.updateSet(updatedSet),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Logged set chip — Kinetic style (surfaceContainerLow card, mono text).
class _SetCard extends ConsumerWidget {
  const _SetCard({
    required this.index,
    required this.set,
    required this.onDelete,
    required this.onEdit,
  });

  final int index;
  final WorkoutSet set;
  final VoidCallback onDelete;
  final void Function(WorkoutSet updatedSet) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context)!;
    final unit = ref.watch(weightUnitProvider);

    return GestureDetector(
      onTap: () async {
        final updated = await showEditSetDialog(context, set, unit: unit);
        if (updated != null) onEdit(updated);
      },
      onLongPress: onDelete,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              set.isWarmUp ? 'W' : 'SET ${index + 1}',
              style: KineticText.mono(
                size: 8,
                letterSpacing: 1.2,
                color: set.isWarmUp ? Colors.orange : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${unit.formatFromKg(set.weight)}${unit.label(s)}',
              style: KineticText.mono(
                size: 14,
                weight: FontWeight.w700,
                letterSpacing: -0.5,
                color: cs.onSurface,
              ),
            ),
            Text(
              '× ${set.reps}',
              style: KineticText.mono(
                size: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ghost (previous-session) set chip — dimmed, mono, italic.
class _GhostSetCard extends ConsumerWidget {
  const _GhostSetCard({
    required this.index,
    required this.ghost,
  });

  final int index;
  final GhostSet ghost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context)!;
    final unit = ref.watch(weightUnitProvider);

    return Opacity(
      opacity: 0.4,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              'SET ${index + 1}',
              style: KineticText.mono(
                size: 8,
                letterSpacing: 1.2,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${unit.formatFromKg(ghost.weight)}${unit.label(s)}',
              style: KineticText.mono(
                size: 14,
                weight: FontWeight.w700,
                letterSpacing: -0.5,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '× ${ghost.reps}',
              style: KineticText.mono(
                size: 11,
                color: cs.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
