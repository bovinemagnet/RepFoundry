# Active Workout Auto-Scroll — Design

**Issue:** [#30 — Scroll not following new exercises](https://github.com/bovinemagnet/RepFoundry/issues/30)
**Author:** Paul Snow
**Date:** 2026-04-30
**Version:** 0.0.0
**Status:** Approved

## Problem

On the active workout screen, the scroll position never follows new content:

- Logging successive sets within an exercise leaves the `SetInputCard` increasingly buried as further exercises and sets accumulate.
- Tapping the *Add Exercise* FAB appends the new exercise to the bottom of the list while the scroll position remains at the top, so the new section is invisible until the user scrolls manually.

The user must manually scroll after every action to see what they just did.

## Goals

1. After logging a set, the exercise's `SetInputCard` is visible — ready to log the next set without manual scrolling.
2. After adding a new exercise via the FAB, the new exercise's header is at the top of the viewport.
3. Scroll motion is animated (~300 ms ease) to preserve a sense of where new content came from.

## Non-goals

- **No auto-scroll on bulk loads.** Starting a workout from a template or programme loads multiple exercises at once and must leave the scroll at the top so the user can survey the full list. Logging a set within a template-loaded workout still triggers the goal-1 behavior.
- **No auto-scroll on edits, deletes, or undo.** Only forward-additive actions (`addExercise`, `logSet`) trigger scrolling.
- No changes to the domain, application, data, or controller layers.

## Approach

All changes are confined to `lib/features/workout/presentation/screens/active_workout_screen.dart`. The screen converts from `ConsumerWidget` to `ConsumerStatefulWidget` and gains:

- `final ScrollController _scrollController = ScrollController();` — attached to the body `ListView` and disposed in `dispose()`.
- `final Map<String, GlobalKey> _exerciseKeys = {};` — one key per exercise id, used by `Scrollable.ensureVisible` to locate sections.
- A helper `_scrollToExercise(String exerciseId, {required double alignment})` that calls `Scrollable.ensureVisible` on the keyed context with `Duration(milliseconds: 300)` and `Curves.easeInOut`.

Each `_ExerciseSection` (and each exercise rendered inside `_SupersetGroup`) is wrapped in a `KeyedSubtree(key: _keyFor(exercise.id), child: ...)`. `_keyFor` lazily inserts a new `GlobalKey` if one does not exist; stale keys for removed exercises are pruned at the start of each `build` against the current `state.exercises` list.

### Trigger 1 — new exercise

In `_pickExercise`, after the exercise is added to state, schedule a post-frame callback to scroll the new section's header to the top:

```dart
final exercise = await context.push<Exercise>('/exercises');
if (exercise != null) {
  await ref.read(activeWorkoutControllerProvider.notifier).addExercise(exercise);
  if (!mounted) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _scrollToExercise(exercise.id, alignment: 0.0);
  });
}
```

`addPostFrameCallback` waits one frame so the new section's `GlobalKey` has a `BuildContext` before measurement. `alignment: 0.0` aligns the section's top with the viewport's top.

### Trigger 2 — set logged

`controller.logSet` is `Future<void>` and awaits a DB write before mutating state. To ensure the new set chip is in the tree before we measure the section's bottom, the screen chains the post-frame scroll off the future via `.then(...)`. No typedef changes are needed — the `onLogSet` callbacks on `_ExerciseSection`, `_ExerciseSectionContent`, and `SetInputCard` remain `void Function({...})`:

```dart
onLogSet: ({required weight, required reps, rpe, isWarmUp = false}) {
  final exerciseId = exercise.id;
  controller.logSet(
    exerciseId: exerciseId,
    weight: weight,
    reps: reps,
    rpe: rpe,
    isWarmUp: isWarmUp,
  ).then((_) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToExercise(exerciseId, alignment: 1.0);
    });
  });
},
```

`alignment: 1.0` aligns the exercise section's bottom with the viewport's bottom, bringing the `SetInputCard` into view. The same wiring applies inside `_SupersetGroup`.

### Why `Scrollable.ensureVisible` over `ScrollController.animateTo`

`ensureVisible` computes the offset from the widget's actual rendered position. This handles variable-height exercise sections, superset wrappers, the rest-timer header, and the stretching section header without manual offset arithmetic. `animateTo` would require us to track each section's height as it rebuilds — fragile.

### Bulk-load isolation

`startFromTemplate` and `startFromProgramme` invoke the controller directly and do not pass through `_pickExercise` or `onLogSet`. No scroll fires. This satisfies the non-goal automatically without explicit suppression logic.

### Rebuild safety

Because keys are pruned and lazily created in `build`, deleting an exercise mid-flight (between scheduling the post-frame callback and its execution) means `_exerciseKeys[id]` returns null or its `currentContext` is null. The helper guards both and no-ops:

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
```

## Alternatives considered

**B — State-driven scroll signal in `ActiveWorkoutState`.** Add a one-shot `ScrollIntent? scrollIntent` field set by the controller after `addExercise`/`logSet`, consumed by the screen via `ref.listen`. *Rejected*: mixes UI concerns into the state model; one-shot fields are an awkward pattern; only two trigger sites and they both already live in the screen.

**C — Diff state changes via `ref.listen`.** Detect `exercises.length` or per-exercise `setsByExercise[id].length` increases and scroll. *Rejected*: cannot distinguish "user added one exercise" from "template loaded six exercises" without an additional signal — fails the bulk-load non-goal. Also fires on edge cases like undo or programme re-application.

## Testing

**Widget test** (new or extending an existing file under `test/features/workout/presentation/screens/`):

1. **Adding an exercise scrolls its header to the top.** Seed a workout with enough exercises to overflow the viewport. Drive the controller's `addExercise`, pump frames, and assert the new exercise's rendered global rect top is within ~8 px of the `ListView` viewport top.
2. **Logging a set scrolls the exercise's input card into view.** Seed an off-screen exercise, drive `controller.logSet`, pump, and assert the exercise section's bottom edge is within the viewport.
3. **Bulk template load does not auto-scroll.** Pump a fresh screen, call `startFromTemplate` with 6 exercises, pump, assert `_scrollController.offset == 0`.

If `Scrollable.ensureVisible` proves brittle to assert against directly, fall back to a behavior probe: a `@visibleForTesting` callback `onScrollRequested(String exerciseId, double alignment)` invoked alongside the real scroll, with assertions on its arguments.

**Manual verification before claiming done:**

- `flutter run` on Android emulator.
- Start a workout, add Bench Press, log 3 sets — `SetInputCard` stays in view, smooth scroll.
- Add Squat, Deadlift, Overhead Press, Row, Pull-up — each new exercise smooth-scrolls its header to the top.
- Start from a template with 6 exercises — screen lands at the top, no auto-scroll.
- Delete an exercise immediately after adding (race) — no crash, no flash scroll.

**Lint / format:**

- `dart analyze` zero issues.
- `dart format --set-exit-if-changed .` passes.

## Risks

- **Race between post-frame scroll and unmount.** Mitigated by the `mounted` guard after both `await` points and the `currentContext == null` guard in `_scrollToExercise`.
- **Keyboard interaction with `alignment: 1.0`.** When the soft keyboard is open while logging, the input card's "bottom of viewport" target may be the keyboard top rather than the screen bottom — Flutter's `Scrollable.ensureVisible` respects the visible viewport, so this should behave correctly. Verified during manual testing.
- **GlobalKey churn on reorder.** Exercises are not currently reorderable in the active workout, so keys remain stable for an exercise's lifetime.
