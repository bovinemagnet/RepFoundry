# Design: Per-set heart-rate summaries and workout↔HR swipe navigation

**Date:** 2026-07-18
**Issues:** [#70 — link cardio to active workout](https://github.com/bovinemagnet/RepFoundry/issues/70), [#71 — swipe between workout and hr measurement](https://github.com/bovinemagnet/RepFoundry/issues/71)
**Author:** Paul Snow

## Goal

1. **Issue 70:** While a BLE heart-rate monitor is connected during a strength workout, automatically stamp each logged set with a heart-rate summary (average and peak BPM) so effort can be reviewed alongside sets and reps.
2. **Issue 71:** A horizontal swipe shortcut between the Active Workout screen and the Heart Rate panel, which are not adjacent bottom-nav tabs.

## Current state

- The workout feature and the heart-rate feature share nothing except the singleton `heartRateServiceProvider` (`lib/core/providers.dart`). The active workout never sees HR data.
- `HeartRatePanelController` and `CardioTrackingController` each keep their own private sample buffer; the panel's `HrReading` stores *elapsed* durations, not wall-clock timestamps.
- `WorkoutSet` has a single absolute `timestamp` (log time) and no HR fields. Drift schema is at version 11.
- No swipe/PageView navigation exists anywhere; tabs navigate via `context.go`.

## Design — Issue 70 (automatic per-set HR summary)

### Shared HR session recorder

New `HrSessionRecorder` (Riverpod `Notifier`, non-autoDispose) in `lib/core/`, alongside `heartRateServiceProvider`. Responsibilities:

- Subscribe to `heartRateService.heartRateStream` while connected; buffer `HrSample(bpm, DateTime timestampUtc)` — absolute UTC timestamps.
- Expose the sample list, current BPM, connection state, session start, and `HrWindowSummary? summarise(DateTime from, DateTime to)` returning average and peak BPM for the window (null when no samples fall inside it).

`HeartRatePanelController` and `CardioTrackingController` are refactored to consume the recorder instead of their private buffers (the panel converts absolute timestamps to the `elapsed` durations the `hr_zones` package expects). This removes buffer duplication and keeps all screens consistent.

### Schema and sync

`WorkoutSet` gains two nullable ints: `avgHeartRate` and `peakHeartRate`.

- Domain model `workout_set.dart`, Drift table `workout_sets_table.dart`.
- `schemaVersionConst` 11 → 12 with an `if (from < 12)` `ALTER TABLE workout_sets ADD COLUMN ...` migration block (nullable, no backfill).
- Sync serialiser touch-points: `_setToDomain`, upsert companion, `_setToMap`, `_setFromMap`. Merge engine unchanged (last-write-wins on `updatedAt` already covers new columns).

### Capture wiring

- `LogSetInput` and `WorkoutSet.create` accept the optional HR fields.
- `ActiveWorkoutController.logSet` computes the window: **previous logged set's timestamp (any exercise; workout start if first set) → now, capped at 5 minutes**, asks the recorder for a summary, and passes avg/peak through. No monitor connected or no samples in window → fields stay null; behaviour is otherwise unchanged.

### UI

Compact heart chip on logged set rows (e.g. `♥ 142 / 168`) in the Active Workout screen and the history workout detail, rendered only when data exists. New strings in `app_en.arb` + `flutter gen-l10n`.

## Design — Issue 71 (swipe shortcut)

Small reusable gesture wrapper in `lib/core/widgets/` using `onHorizontalDragEnd` with a fling velocity/distance threshold:

- Active Workout screen: swipe left → `context.go('/heart-rate')`.
- Heart Rate panel: swipe right → `context.go('/workout')`.

The two screens act as if side by side. Tab order, router structure, and other screens are untouched. No PageView.

## Error handling

- HR capture is best-effort: any recorder/summary failure results in null HR fields, never a blocked or failed set log.
- Older app versions reject snapshots written at schema 12 (existing forward-incompatibility guard); nullable columns keep the merge backward-safe otherwise.

## Testing

- Pure window-summary function: unit tests first (empty window, cap behaviour, single sample, avg vs peak).
- `HrSessionRecorder` unit tests with the existing fake HR service.
- Existing panel/cardio controller tests act as regression net for the recorder refactor.
- `LogSetUseCase` test with HR fields; Drift migration v11→v12 test; sync serialiser round-trip test including new fields.
- Widget tests: HR chip renders only when data present; horizontal fling on each screen navigates to its partner.

## Delivery

Two PRs: issue 71 first (small, independent), then issue 70. The in-flight BLE hardening work (reconnect backoff schedule, GATT 133 retry, scan-error classification) lands before both.
