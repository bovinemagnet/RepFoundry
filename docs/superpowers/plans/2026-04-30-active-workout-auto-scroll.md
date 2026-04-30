# Active Workout Auto-Scroll Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the active workout screen smooth-scroll to follow newly added exercises and newly logged sets, while leaving bulk template/programme loads at the top of the list.

**Architecture:** Convert `ActiveWorkoutScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` with a `ScrollController` and a map of `GlobalKey`s (one per exercise id). Expose two `@visibleForTesting` handler methods (`handleAddExercise`, `handleLogSet`) that internally call the controller and then schedule a post-frame `Scrollable.ensureVisible`. The FAB and `SetInputCard` callbacks call those handlers, giving us testable seams while keeping the production wiring intact.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_test.

**Spec:** `docs/superpowers/specs/2026-04-30-active-workout-auto-scroll-design.md`

---

## File Structure

- **Modify:** `lib/features/workout/presentation/screens/active_workout_screen.dart` (sole production change)
- **Modify:** `test/features/workout/presentation/screens/active_workout_screen_test.dart` (add four new tests)

No other files are touched. No domain, application, data, or controller changes.

---

### Task 1: Convert screen to stateful with ScrollController + key map

**Files:**
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart` (lines 26-87 + 289-385)

This is a structural change with no behavior change. Existing tests must still pass.

- [ ] **Step 1.1: Add the `meta` import for `@visibleForTesting`**

At the top of `active_workout_screen.dart`, after the existing `package:flutter` import, add:

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
```

- [ ] **Step 1.2: Convert `ActiveWorkoutScreen` to `ConsumerStatefulWidget`**

The state class is named publicly (`ActiveWorkoutScreenState`) and annotated `@visibleForTesting` so widget tests can access typed members like `scrollController` via `tester.state<ActiveWorkoutScreenState>(...)`. Replace lines 26-87 with:

```dart
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      ActiveWorkoutScreenState();
}

@visibleForTesting
class ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _exerciseKeys = {};

  @visibleForTesting
  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String exerciseId) =>
      _exerciseKeys.putIfAbsent(exerciseId, () => GlobalKey());

  void _pruneStaleKeys(List<String> currentExerciseIds) {
    final live = currentExerciseIds.toSet();
    _exerciseKeys.removeWhere((id, _) => !live.contains(id));
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

    return Scaffold(
      appBar: AppBar(
        title: state.hasActiveWorkout
            ? Text(
                '${s.workoutTitle}  •  ${state.activeWorkout!.startedAt.timeOfDay}',
              )
            : Text(s.workoutTitle),
        actions: [
          if (state.hasActiveWorkout)
            TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _confirmFinish(context, controller),
              icon: const Icon(Icons.check),
              label: Text(s.finish),
            ),
        ],
      ),
      body: state.isLoading
          ? LoadingWidget(message: s.loadingWorkout)
          : state.hasActiveWorkout
              ? _buildActiveWorkout(context, ref, state, controller)
              : _buildNoWorkout(context, ref, controller),
      floatingActionButton: state.hasActiveWorkout
          ? FloatingActionButton.extended(
              onPressed: () => _pickExercise(context, ref),
              icon: const Icon(Icons.add),
              label: Text(s.addExercise),
            )
          : null,
    );
  }
```

Note: every method in the class previously took `(BuildContext context, WidgetRef ref, ...)`. They still do — `ConsumerState` exposes `ref` as an instance field, but the existing methods all accept `ref` as a parameter from build, so leave their signatures alone. The `mounted` getter is provided by `State`.

- [ ] **Step 1.3: Add `controller: _scrollController` to the body `ListView`**

In `_buildActiveWorkout`, find the `ListView(` (currently line 330) and change it to:

```dart
return ListView(
  controller: _scrollController,
  padding: const EdgeInsets.only(bottom: 88),
  children: [
```

- [ ] **Step 1.4: Wrap `_ExerciseSection` in `KeyedSubtree`**

Inside `_buildActiveWorkout`'s loop, change the non-superset branch from:

```dart
] else ...[
  _ExerciseSection(
    exercise: exercise,
    sets: state.setsByExercise[exercise.id] ?? [],
    /* ... */
  ),
],
```

to:

```dart
] else ...[
  KeyedSubtree(
    key: _keyFor(exercise.id),
    child: _ExerciseSection(
      exercise: exercise,
      sets: state.setsByExercise[exercise.id] ?? [],
      /* ... */
    ),
  ),
],
```

- [ ] **Step 1.5: Wrap each exercise rendered inside `_SupersetGroup`**

Inside the existing `_SupersetGroup` widget's `build`, find the `for (final exercise in exercises)` loop and wrap each padded `_ExerciseSectionContent` in a `KeyedSubtree`. Because `_SupersetGroup` is a stateless widget that doesn't have access to the screen's `_keyFor`, pass a `Map<String, GlobalKey>` down via constructor. Update `_SupersetGroup`'s constructor:

```dart
class _SupersetGroup extends StatelessWidget {
  const _SupersetGroup({
    required this.exercises,
    required this.state,
    required this.controller,
    required this.onUnlink,
    required this.exerciseKeys,
  });

  final List<Exercise> exercises;
  final ActiveWorkoutState state;
  final ActiveWorkoutController controller;
  final void Function(String exerciseId) onUnlink;
  final Map<String, GlobalKey> exerciseKeys;
```

Inside the `for (final exercise in exercises)` loop, replace:

```dart
for (final exercise in exercises)
  Padding(
    padding: const EdgeInsets.all(16),
    child: _ExerciseSectionContent(
      /* ... */
    ),
  ),
```

with:

```dart
for (final exercise in exercises)
  KeyedSubtree(
    key: exerciseKeys.putIfAbsent(exercise.id, () => GlobalKey()),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _ExerciseSectionContent(
        /* ... */
      ),
    ),
  ),
```

Then in `_buildActiveWorkout` where `_SupersetGroup` is constructed, pass the screen's `_exerciseKeys`:

```dart
return _SupersetGroup(
  exercises: groupExercises,
  state: state,
  controller: controller,
  onUnlink: (exerciseId) => controller.unlinkSuperset(exerciseId),
  exerciseKeys: _exerciseKeys,
);
```

- [ ] **Step 1.6: Run existing tests**

```bash
gradle21w antora --quiet 2>/dev/null; flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart
```

(The first command is a noop here; we just want the second to run. Or run directly: `flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart`.)

Expected: all 4 existing tests pass. No regressions.

- [ ] **Step 1.7: Run `dart analyze` to confirm no issues**

```bash
dart analyze lib/features/workout/presentation/screens/active_workout_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 1.8: Commit**

```bash
git add lib/features/workout/presentation/screens/active_workout_screen.dart
git commit -m "refactor: convert ActiveWorkoutScreen to ConsumerStatefulWidget

Adds ScrollController and per-exercise GlobalKey map as scaffolding
for upcoming auto-scroll behavior (issue #30). No behavior change."
```

---

### Task 2: Add the `_scrollToExercise` helper

**Files:**
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart`
- Test: `test/features/workout/presentation/screens/active_workout_screen_test.dart`

The helper exists but is not yet called from any user-visible flow. Tests verify it works in isolation. After this task, scroll-on-demand works programmatically; wiring to FAB and `onLogSet` comes in Tasks 3-5.

- [ ] **Step 2.1: Write a failing test that calls `scrollToExercise` and asserts the scroll moved**

Add this test to the `group('ActiveWorkoutScreen', ...)` block in `active_workout_screen_test.dart`. Imports needed at the top of the file:

```dart
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
```

Add a helper above the `group(...)`:

```dart
Exercise _testExercise(String id, String name) => Exercise(
      id: id,
      name: name,
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.chest,
      equipmentType: EquipmentType.barbell,
      updatedAt: DateTime(2025, 1, 1),
    );
```

Then add the test inside the group:

```dart
testWidgets(
  'scrollToExercise_movesScrollOffset_whenExerciseIsBelowFold',
  (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(ActiveWorkoutScreen));
    final container = ProviderScope.containerOf(element);
    final notifier =
        container.read(activeWorkoutControllerProvider.notifier);

    // Add enough exercises that the last one is below the fold.
    for (var i = 0; i < 10; i++) {
      await notifier.addExercise(_testExercise('ex-$i', 'Exercise $i'));
    }
    await tester.pumpAndSettle();

    final state = tester.state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));
    expect(state.scrollController.offset, 0.0);

    state.scrollToExercise('ex-9', alignment: 0.0);
    await tester.pumpAndSettle();

    expect(state.scrollController.offset, greaterThan(0.0));
  },
);
```

- [ ] **Step 2.2: Run test to verify it fails**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart --plain-name "scrollToExercise_movesScrollOffset"
```

Expected: FAIL — `scrollToExercise` is undefined on the State.

- [ ] **Step 2.3: Implement `_scrollToExercise` and expose for testing**

In `_ActiveWorkoutScreenState`, add:

```dart
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
```

- [ ] **Step 2.4: Run the test**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart --plain-name "scrollToExercise_movesScrollOffset"
```

Expected: PASS.

- [ ] **Step 2.5: Commit**

```bash
git add lib/features/workout/presentation/screens/active_workout_screen.dart test/features/workout/presentation/screens/active_workout_screen_test.dart
git commit -m "feat: add scrollToExercise helper to active workout screen

Uses Scrollable.ensureVisible against per-exercise GlobalKeys.
Helper is currently unwired; subsequent commits hook it into the
add-exercise and log-set handlers (issue #30)."
```

---

### Task 3: Wire scroll on add exercise

**Files:**
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart`
- Test: `test/features/workout/presentation/screens/active_workout_screen_test.dart`

Extract the post-add scroll into a testable `handleAddExercise` method. The existing `_pickExercise` calls it after the exercise picker returns.

- [ ] **Step 3.1: Write a failing test that drives `handleAddExercise` and asserts scroll moved**

Add to `active_workout_screen_test.dart`:

```dart
testWidgets(
  'handleAddExercise_scrollsNewExerciseToTop_afterAdd',
  (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(ActiveWorkoutScreen));
    final container = ProviderScope.containerOf(element);
    final notifier =
        container.read(activeWorkoutControllerProvider.notifier);

    // Pre-fill with enough exercises to overflow the viewport.
    for (var i = 0; i < 8; i++) {
      await notifier.addExercise(_testExercise('ex-$i', 'Exercise $i'));
    }
    await tester.pumpAndSettle();

    final state = tester.state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));
    final offsetBefore = state.scrollController.offset as double;

    await state.handleAddExercise(_testExercise('new-ex', 'New Exercise'));
    await tester.pumpAndSettle();

    expect(state.scrollController.offset, isNot(equals(offsetBefore)));
    expect(state.scrollController.offset, greaterThan(0.0));
  },
);
```

- [ ] **Step 3.2: Run test to verify it fails**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart --plain-name "handleAddExercise_scrollsNewExerciseToTop"
```

Expected: FAIL — `handleAddExercise` is undefined.

- [ ] **Step 3.3: Add `handleAddExercise` and call it from `_pickExercise`**

In `_ActiveWorkoutScreenState`, add:

```dart
@visibleForTesting
Future<void> handleAddExercise(Exercise exercise) async {
  await ref
      .read(activeWorkoutControllerProvider.notifier)
      .addExercise(exercise);
  if (!mounted) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _scrollToExercise(exercise.id, alignment: 0.0);
  });
}
```

Then change the existing `_pickExercise` from:

```dart
Future<void> _pickExercise(BuildContext context, WidgetRef ref) async {
  final exercise = await context.push<Exercise>('/exercises');
  if (exercise != null) {
    ref.read(activeWorkoutControllerProvider.notifier).addExercise(exercise);
  }
}
```

to:

```dart
Future<void> _pickExercise(BuildContext context, WidgetRef ref) async {
  final exercise = await context.push<Exercise>('/exercises');
  if (exercise != null && mounted) {
    await handleAddExercise(exercise);
  }
}
```

- [ ] **Step 3.4: Run the test**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart --plain-name "handleAddExercise_scrollsNewExerciseToTop"
```

Expected: PASS.

- [ ] **Step 3.5: Run the full screen test file to confirm no regressions**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 3.6: Commit**

```bash
git add lib/features/workout/presentation/screens/active_workout_screen.dart test/features/workout/presentation/screens/active_workout_screen_test.dart
git commit -m "feat: scroll new exercise to top of viewport after add (issue #30)

Extracts handleAddExercise into a testable method that awaits the
controller, then schedules a post-frame Scrollable.ensureVisible
with alignment 0.0 so the new section's header lands at the top.
Bulk template/programme loads bypass this path, leaving scroll at 0."
```

---

### Task 4: Wire scroll on log set (standalone exercise)

**Files:**
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart`
- Test: `test/features/workout/presentation/screens/active_workout_screen_test.dart`

`controller.logSet` returns `Future<void>` and awaits a DB write before mutating state. Chain the post-frame scroll off the future via `.then(...)` so the new set chip is in the tree before we measure the section's bottom.

- [ ] **Step 4.1: Write a failing test that drives `handleLogSet` and asserts scroll moved**

Add to `active_workout_screen_test.dart`:

```dart
testWidgets(
  'handleLogSet_scrollsExerciseInputCardIntoView_afterLog',
  (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(ActiveWorkoutScreen));
    final container = ProviderScope.containerOf(element);
    final notifier =
        container.read(activeWorkoutControllerProvider.notifier);

    // First exercise will be off-screen once we add many more.
    final target = _testExercise('target-ex', 'Target Exercise');
    await notifier.addExercise(target);
    for (var i = 0; i < 8; i++) {
      await notifier.addExercise(_testExercise('ex-$i', 'Exercise $i'));
    }
    await tester.pumpAndSettle();

    final state = tester.state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));

    // Manually scroll past the target so the next log will need to come back up.
    state.scrollController.jumpTo(
      state.scrollController.position.maxScrollExtent,
    );
    await tester.pumpAndSettle();

    final offsetBefore = state.scrollController.offset as double;
    expect(offsetBefore, greaterThan(0.0));

    state.handleLogSet(
      exerciseId: 'target-ex',
      weight: 50.0,
      reps: 10,
      rpe: null,
      isWarmUp: false,
    );
    await tester.pumpAndSettle();

    // Scrolling target into view from below means offset should decrease.
    expect(state.scrollController.offset, lessThan(offsetBefore));
  },
);
```

- [ ] **Step 4.2: Run test to verify it fails**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart --plain-name "handleLogSet_scrollsExerciseInputCardIntoView"
```

Expected: FAIL — `handleLogSet` is undefined.

- [ ] **Step 4.3: Add `handleLogSet` and rewire the `_ExerciseSection`'s `onLogSet`**

In `_ActiveWorkoutScreenState`, add:

```dart
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
```

In `_buildActiveWorkout`, change the standalone `_ExerciseSection`'s `onLogSet` callback from:

```dart
onLogSet: ({
  required double weight,
  required int reps,
  double? rpe,
  bool isWarmUp = false,
}) {
  controller.logSet(
    exerciseId: exercise.id,
    weight: weight,
    reps: reps,
    rpe: rpe,
    isWarmUp: isWarmUp,
  );
},
```

to:

```dart
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
```

- [ ] **Step 4.4: Run the test**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart --plain-name "handleLogSet_scrollsExerciseInputCardIntoView"
```

Expected: PASS.

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/workout/presentation/screens/active_workout_screen.dart test/features/workout/presentation/screens/active_workout_screen_test.dart
git commit -m "feat: scroll exercise input card into view after logging set (issue #30)

Extracts handleLogSet that chains Scrollable.ensureVisible (alignment
1.0) off controller.logSet's Future via .then(), so the new set chip
is in the tree before we measure the section's bottom edge."
```

---

### Task 5: Mirror the log-set scroll wiring inside `_SupersetGroup`

**Files:**
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart`

`_SupersetGroup` has its own `_ExerciseSectionContent` instances with their own `onLogSet` callbacks that call `controller.logSet` directly (bypassing `handleLogSet`). Pass the handler down so superset exercises behave the same.

- [ ] **Step 5.1: Add a callback parameter to `_SupersetGroup`**

Update `_SupersetGroup`'s constructor to accept a log-set callback:

```dart
class _SupersetGroup extends StatelessWidget {
  const _SupersetGroup({
    required this.exercises,
    required this.state,
    required this.controller,
    required this.onUnlink,
    required this.exerciseKeys,
    required this.onLogSet,
  });

  final List<Exercise> exercises;
  final ActiveWorkoutState state;
  final ActiveWorkoutController controller;
  final void Function(String exerciseId) onUnlink;
  final Map<String, GlobalKey> exerciseKeys;
  final void Function({
    required String exerciseId,
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;
```

- [ ] **Step 5.2: Use the callback inside `_SupersetGroup`'s inner `onLogSet`**

Inside the `for (final exercise in exercises)` loop, change the inner `_ExerciseSectionContent`'s `onLogSet` from:

```dart
onLogSet: ({
  required double weight,
  required int reps,
  double? rpe,
  bool isWarmUp = false,
}) {
  controller.logSet(
    exerciseId: exercise.id,
    weight: weight,
    reps: reps,
    rpe: rpe,
    isWarmUp: isWarmUp,
  );
},
```

to:

```dart
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
```

- [ ] **Step 5.3: Pass `handleLogSet` through `_buildActiveWorkout`**

Where `_SupersetGroup` is constructed in `_buildActiveWorkout`, add the new parameter:

```dart
return _SupersetGroup(
  exercises: groupExercises,
  state: state,
  controller: controller,
  onUnlink: (exerciseId) => controller.unlinkSuperset(exerciseId),
  exerciseKeys: _exerciseKeys,
  onLogSet: handleLogSet,
);
```

- [ ] **Step 5.4: Run the full workout screen test file**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart
```

Expected: all tests pass (no new test in this task — the wiring is symmetric with Task 4 and is covered by manual verification).

- [ ] **Step 5.5: Run `dart analyze`**

```bash
dart analyze lib/features/workout/presentation/screens/active_workout_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 5.6: Commit**

```bash
git add lib/features/workout/presentation/screens/active_workout_screen.dart
git commit -m "feat: extend log-set auto-scroll wiring to superset exercises

Threads handleLogSet through _SupersetGroup so exercises rendered
inside a superset trigger the same input-card-into-view scroll as
standalone exercises (issue #30)."
```

---

### Task 6: Regression test — bulk template load does not auto-scroll

**Files:**
- Test: `test/features/workout/presentation/screens/active_workout_screen_test.dart`

The bulk-load no-scroll behavior is a non-goal that we satisfied automatically (template path bypasses our handlers). Add a test that locks this in.

- [ ] **Step 6.1: Add the test**

Add this test to the existing group in `active_workout_screen_test.dart`. Imports needed:

```dart
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
```

```dart
testWidgets(
  'startFromTemplate_doesNotAutoScroll_evenWithManyExercises',
  (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(ActiveWorkoutScreen));
    final container = ProviderScope.containerOf(element);
    final notifier =
        container.read(activeWorkoutControllerProvider.notifier);

    // Pre-create exercises in the in-memory exercise repository so the
    // template can resolve them, plus matching TemplateExercise rows.
    final exerciseRepo = container.read(exerciseRepositoryProvider);
    final templateExercises = <TemplateExercise>[];
    for (var i = 0; i < 8; i++) {
      final ex = _testExercise('tmpl-ex-$i', 'Template Exercise $i');
      await exerciseRepo.createExercise(ex);
      templateExercises.add(
        TemplateExercise(
          id: 'te-$i',
          templateId: 'tmpl-1',
          exerciseId: ex.id,
          exerciseName: ex.name,
          targetSets: 3,
          targetReps: 10,
          orderIndex: i,
          updatedAt: DateTime(2025, 1, 1),
        ),
      );
    }

    final template = WorkoutTemplate(
      id: 'tmpl-1',
      name: 'Big Day',
      exercises: templateExercises,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    await notifier.startFromTemplate(template);
    await tester.pumpAndSettle();

    final state = tester.state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));
    expect(state.scrollController.offset, 0.0);
  },
);
```

- [ ] **Step 6.2: Run the test**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart --plain-name "startFromTemplate_doesNotAutoScroll"
```

Expected: PASS (the production code already satisfies this — template loading goes through `controller.startFromTemplate` → `addExercise` directly, never through our `_pickExercise`/`handleAddExercise` handlers, so no scroll fires).

If the test fails, the production wiring is wrong somewhere. Investigate before continuing — do not delete or weaken the test.

- [ ] **Step 6.3: Run the full screen test file**

```bash
flutter test test/features/workout/presentation/screens/active_workout_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 6.4: Commit**

```bash
git add test/features/workout/presentation/screens/active_workout_screen_test.dart
git commit -m "test: lock in bulk template load does not trigger auto-scroll (issue #30)"
```

---

### Task 7: Final verification — full test suite, lint, format, manual check

**Files:** none (verification only).

- [ ] **Step 7.1: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass. If any unrelated test fails, investigate — the change is confined to a single screen, so cross-feature breakage is unlikely but possible (e.g. a test that imports `ActiveWorkoutScreen` and relies on it being a `ConsumerWidget`).

- [ ] **Step 7.2: Run `dart analyze` over the whole project**

```bash
dart analyze
```

Expected: `No issues found!` CI requires zero issues.

- [ ] **Step 7.3: Run `dart format --set-exit-if-changed .`**

```bash
dart format --set-exit-if-changed lib/features/workout/presentation/screens/active_workout_screen.dart test/features/workout/presentation/screens/active_workout_screen_test.dart
```

Expected: exit 0. If files need reformatting, run `dart format <file>` and amend the most recent commit.

- [ ] **Step 7.4: Manual verification on Android emulator**

Start an emulator (or connected device), then:

```bash
flutter run -d <device>
```

Walk through these scenarios and confirm each works:

1. **Log multiple sets in one exercise.** Start a workout. Add Bench Press. Log a set (50 kg × 10) — confirm the input card stays in view, smooth animation. Log a second and third set — input card stays in view each time.
2. **Add multiple exercises.** With sets already logged in Bench Press, tap *Add Exercise* and pick Squat. Confirm the screen smooth-scrolls so Squat's header lands at the top of the viewport. Repeat for Deadlift, Overhead Press, Row, Pull-up — each new exercise should smooth-scroll into view at the top.
3. **Bulk template load stays at top.** Finish (or cancel) the active workout. From the no-workout screen, tap *Start from Template* and pick a template with 6+ exercises. Confirm the screen lands at the top and does *not* auto-scroll.
4. **Log a set in a template-loaded workout.** With the template-loaded workout open, scroll down to one of the lower exercises and log a set. Confirm the input card scrolls into view.
5. **Race: delete an exercise immediately after adding.** Add an exercise, then long-press a set/exercise to delete it during the scroll animation. Confirm no crash, no flash scroll.
6. **Soft keyboard interaction.** Tap a weight or reps field to bring up the soft keyboard. Log a set. Confirm the input card scrolls back into view above the keyboard, not behind it.

If any scenario fails, file a follow-up task or fix in a new commit before claiming done.

- [ ] **Step 7.5: Verify the issue is resolved on GitHub**

Re-read `gh issue view 30` and confirm each described problem is now fixed:

- "When I add sets and reps, it does not auto scroll down" — fixed by Task 4/5.
- "I add a new exercise, and it is still at the top, not following the exercise" — fixed by Task 3.

If everything checks out, the implementation is complete.

---

## Notes

- **Why no test for the FAB → exercise picker → push flow:** the FAB calls `context.push<Exercise>('/exercises')` which requires a configured GoRouter with the exercises route registered. Setting that up in a widget test for one assertion is more scaffolding than the test is worth. Task 3 tests the `handleAddExercise` method directly, which is what the FAB callback invokes after the picker returns. The wiring between the FAB tap and `handleAddExercise` is one line of code, verified manually in Step 7.4.
- **Why no test for `_SupersetGroup` log-set wiring:** symmetric to Task 4. Setting up a superset state in a widget test (linking two exercises via `controller.linkSuperset`, then driving `handleLogSet` through the rendered group) adds substantial setup for a single line of wiring. Verified manually in Step 7.4 if a superset exists in the tested workout — extend the manual check by linking two exercises before logging.
- **Animation duration:** 300 ms with `Curves.easeInOut` is the spec value. If it feels too slow or too fast in manual testing, adjust the constant in `_scrollToExercise` and document in a follow-up commit.
