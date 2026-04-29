# Stretching Recording — Design Spec (MVP)

**Issue:** #15
**Date:** 2026-04-30
**Author:** Paul Snow
**Status:** Approved (auto mode — proceeding without further dialogue per user direction)

## Scope

Implement the core of the stretching-recording PRD (issue #15) as MVP. The user
also asked for a curated list of 15–20 common stretches that can be picked
quickly from the add-stretching UI, including the splits.

### In scope

- Phase 1 (data + domain), Phase 2 (UI in active workout), Phase 3 (timer),
  Phase 4 (history display).
- 18 seeded stretches (including front splits and side splits), with a free-text
  custom name fallback.

### Out of scope (deferred)

- Phase 5 — JSON/CSV export/import. Note as a TODO; out of MVP.
- Cloud sync (`SyncSnapshot`) wiring — not blocking MVP, opens follow-up.
- App-killed timer draft persistence — accept loss for MVP per PRD §14.
- Health-store flexibility export.
- Localising every stretch name into ja/ko/zh — English only; structure is
  ready for localisation later.

## Architecture

Standard feature-first: `lib/features/stretching/{application,data,domain,presentation}`.

- Domain: `StretchingSession` model, `StretchingEntryMethod` and `StretchingSide`
  enums, repository interface, plus a small `StretchPreset` value type plus a
  `defaultStretches` const list.
- Data: `DriftStretchingSessionRepository` + `InMemoryStretchingSessionRepository`.
- Application: `SaveStretchingSessionUseCase` (creates/auto-creates a workout
  similar to `SaveCardioSessionUseCase` if the caller does not pass a workoutId,
  but for MVP we always require an active workoutId — the active workout
  controller already gives us one).
- Presentation: `StretchingTimerController` (NotifierProvider, non-autoDispose),
  widgets `StretchingSection`, `AddStretchingSheet`, `StretchingEntryTile`,
  `StretchingTimerPanel`.

## Data model

Drift table `stretching_sessions`:

| Column          | Type           | Notes                                      |
|-----------------|----------------|--------------------------------------------|
| id              | TEXT PK        | UUID v4                                    |
| workout_id      | TEXT NOT NULL  | FK → workouts.id                           |
| type            | TEXT NOT NULL  | preset key or "custom"                     |
| custom_name     | TEXT           | populated when type = custom               |
| body_area       | TEXT           | enum name; nullable                        |
| side            | TEXT           | enum name; nullable                        |
| duration_seconds| INTEGER NOT NULL |                                          |
| started_at      | INTEGER        | epoch ms; null for manual entries          |
| ended_at        | INTEGER        | epoch ms; null for manual entries          |
| entry_method    | TEXT NOT NULL  | enum name (timer | manual)                 |
| notes           | TEXT           |                                            |
| updated_at      | INTEGER NOT NULL DEFAULT 0 |                              |
| deleted_at      | INTEGER        | soft delete                                |

Indexes: `idx_stretching_sessions_workout(workout_id)`,
`idx_stretching_sessions_type_updated(type, updated_at)`.

`schemaVersion`: bump 8 → 9. Migration `from < 9` creates the table and
indexes.

## Seeded stretches (18)

Sourced from Self / Mayo Clinic / Pliability references in the issue brief.

| Key                  | Display name                  | Body area    |
|----------------------|-------------------------------|--------------|
| standingHamstring    | Standing Hamstring Stretch    | Hamstrings   |
| seatedForwardFold    | Seated Forward Fold           | Hamstrings   |
| standingQuad         | Standing Quadriceps Stretch   | Quadriceps   |
| lowLungeHipFlexor    | Low Lunge Hip Flexor          | Hip Flexors  |
| pigeon               | Pigeon Pose                   | Hips         |
| butterfly            | Butterfly Stretch             | Hips         |
| childsPose           | Child's Pose                  | Back         |
| cobra                | Cobra Stretch                 | Back         |
| catCow               | Cat–Cow                       | Back         |
| downwardDog          | Downward-Facing Dog           | Full Body    |
| crossBodyShoulder    | Cross-Body Shoulder Stretch   | Shoulders    |
| doorwayChest         | Doorway Chest Stretch         | Chest        |
| standingCalf         | Standing Calf Stretch         | Calves       |
| supineSpinalTwist    | Supine Spinal Twist           | Back         |
| neckSideStretch      | Neck Side Stretch             | Neck         |
| figureFourGlute      | Figure-4 Glute Stretch        | Glutes/Hips  |
| ninetyNinety         | 90/90 Hip Stretch             | Hips         |
| frogPose             | Frog Pose                     | Adductors    |
| frontSplits          | Front Splits                  | Hamstrings/Hip Flexors |
| sideSplits           | Side Splits (Middle Splits)   | Adductors    |

That's 20 total — meets the user's "15–20, include the splits" ask.

## UI

`StretchingSection` slots into the active workout `ListView` between the rest
timer and the strength exercise sections (visible only when there is an active
workout). Empty state shows an "Add Stretching" CTA; populated shows a header
with totals and a list of `StretchingEntryTile`s.

`AddStretchingSheet` (modal bottom sheet):
1. Stretch picker: a wrap of preset chips plus a "Custom…" option.
2. Mode toggle: Timer vs Manual.
3. Timer view: stopwatch + Pause/Stop & Save/Discard.
4. Manual view: minutes + seconds inputs + quick-duration chips
   (1/2/5/10/15 min).
5. Optional notes field.
6. Save button.

History: `WorkoutDetailScreen` gets a new "Stretching" card listing entries
when present, plus a per-workout total. (Cards on the history list intentionally
left as-is for MVP — keeps the diff small and the card readable.)

## Validation

- duration > 0.
- duration <= 12 hours (warning above 3 hours per PRD §14 deferred — hard cap
  only for MVP).
- type non-empty.
- custom_name <= 60 chars, trimmed.

## Testing

- Domain: `StretchingSession.create()` produces UUID + UTC timestamp.
- Repository: in-memory + Drift round-trip + soft delete + watch stream.
- Use case: validation + persistence.
- Controller: timer start/pause/resume/stop/discard/save state transitions.
- Widget: section empty/populated, add-sheet save flow.

## Non-goals (MVP)

- Strength PRs / volume / set count are unaffected — stretching is a separate
  table and is never read by the strength flows.
- No analytics events.
- No timer-completion sounds.
