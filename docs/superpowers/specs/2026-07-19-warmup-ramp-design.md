# Design: Warm-up set generator (ramp from working weight)

**Date:** 2026-07-19
**Issue:** [#67 — Warm-up set generator: auto-suggest a ramp from working weight](https://github.com/bovinemagnet/RepFoundry/issues/67)
**Author:** Paul Snow

## Goal

Given a working weight, generate a warm-up ramp (bar × 10, 40% × 5, 60% × 3, 80% × 1) and let the user add those sets to the current exercise as `isWarmUp` rows with one tap, after previewing them. Loadable equipment only. No schema change — builds on the existing `WorkoutSet.isWarmUp`.

## Decisions made during design

- **Working weight source:** the currently-typed weight in the set input card, falling back to the ghost (last-session) weight, then the last logged set. Button hidden when none resolves.
- **Default scheme:** bar × 10, 40% × 5, 60% × 3, 80% × 1. Fixed and hard-coded — no settings toggle in this version (per-exercise and configurable schemes remain out of scope).
- **Rounding:** bar-only step = 20 kg / 45 lb for barbell; percentage steps round to the nearest loadable increment (2.5 kg / 5 lb) in the active display unit, never below the bar.
- **Insertion UX:** a preview bottom sheet lists the computed steps, then an Add button inserts them. Rows are `isWarmUp` and remain editable/removable.
- **Non-barbell equipment:** dumbbell, kettlebell, cable, machine drop the empty-bar step and start at 40%. Non-loadable equipment (bodyweight, cardioMachine, resistanceBand, other) get no action.

## Architecture

### Pure ramp generator — `lib/core/units/warmup_ramp.dart`

```dart
List<WarmupStep> warmupRamp({
  required double workingKg,
  required EquipmentType equipment,
  required WeightUnit unit,
});
```

- `WarmupStep`: `{ double weightKg, int reps, bool isBarOnly }`.
- New constants (in `lib/core/units/`): `barWeightKg = 20.0`, `barWeightLbs = 45.0`; plate increments `2.5 kg` / `5 lb`.
- Default scheme: bar × 10 (barbell only), 40% × 5, 60% × 3, 80% × 1.
- Rounding happens in the display unit — convert kg → unit, round to the increment, convert back — so the loaded number is clean in whatever the user reads.
- Steps at or below the bar (or below one increment for non-barbell) collapse out; consecutive duplicate weights de-duplicate.
- `workingKg <= 0` or non-loadable equipment → empty list.

Loadable equipment: `barbell`, `dumbbell`, `kettlebell`, `cable`, `machine`. Excluded: `bodyweight`, `cardioMachine`, `resistanceBand`, `other`.

### Working-weight source + section wiring

`SetInputCard` currently keeps its weight text in private state. Lift the current weight up (a small `onWeightChanged` callback / exposed value) so `_ExerciseSection` can read it. Resolution priority: typed weight → ghost/suggestion weight → last logged set → none (action hidden). This is the one contained refactor.

### UI — "Add warm-up" action + preview sheet

A compact "Add warm-up" action in `_ExerciseSection`, shown only for loadable equipment with a resolvable working weight. Tapping opens a bottom sheet listing steps in the active unit (e.g. `20 kg × 10 · 40 × 5 · 60 × 3 · 80 × 1`) with an Add button. Confirming inserts each step sequentially via `controller.logSet(..., isWarmUp: true)` — sequential awaits keep `setOrder` correct (state updates after each await), and warm-ups are already excluded from PR detection. Rows render with the existing orange `W` chip and are editable/removable.

Both `_ExerciseSection` and `_SupersetGroup` render exercise content, so the new prop threads through both call sites.

## Error handling

- No working weight, non-loadable equipment, or an empty ramp → action absent or a no-op; never inserts a malformed set.
- Ramp weights obey existing set validation (weight ≥ 0, reps > 0); the bar step is always ≥ the bar, percentage steps ≥ one increment.

## Testing (TDD)

- Pure `warmupRamp`: default 4-step barbell ramp at a round weight; kg vs lbs rounding; dumbbell (no bar step, starts at 40%); bar-collapse when working weight is near the bar; `<= 0` and non-loadable → empty; consecutive-duplicate de-dup.
- Controller: inserting a ramp yields N `isWarmUp` sets with ascending `setOrder` and fires no PRs.
- Widget: action hidden for bodyweight/cardio equipment and shown for barbell; preview sheet lists the steps; Add inserts warm-up rows.

## Delivery

Single branch (`feat/warmup-ramp`) and PR, `Closes #67`, TDD throughout. No schema change, no new settings. Full `flutter test` + `dart analyze` + `dart format` before push.
