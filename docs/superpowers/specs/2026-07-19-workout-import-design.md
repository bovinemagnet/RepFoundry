# Design: CSV workout-history import (RepFoundry, Strong, Hevy)

**Date:** 2026-07-19
**Issue:** [#68 — Workout import: CSV and third-party (Strong/Hevy) history import](https://github.com/bovinemagnet/RepFoundry/issues/68)
**Author:** Paul Snow

## Goal

Let users import strength-training history from CSV files — RepFoundry's own `sets.csv` export, Strong exports, and Hevy exports — so people switching apps can bring their history. File import only; cardio/heart-rate rows and live API sync are out of scope.

## Decisions made during design

- **File input:** add the `file_picker` package and a new "Import from File" settings row. The existing JSON paste dialog stays unchanged.
- **Ambiguous weight units:** Strong files that do not declare a unit trigger a one-tap kg/lbs question before import. Hevy (`weight_kg`) and RepFoundry (kg by definition) never prompt. Strong variants with a `Weight Unit` column use it per-row.
- **Idempotent re-import:** deterministic UUIDv5 IDs derived from row content, so the existing insert-throws-on-duplicate guard makes a second import of the same file a no-op. The sync merge engine is *not* used — it matches by UUID only and adds no safety here.
- **PR backfill:** after import, create personal-record rows where the imported history beats stored all-time bests, dated to the historical set that achieved them. Prevents false "new PR" celebrations against imported history.

## Architecture

### Parsing layer — `lib/features/settings/application/import/`

- New dependency: `csv` (RFC-4180 parsing).
- `CsvFormatAdapter` interface: `bool matches(List<String> header)` + `ParsedHistory parse(...)`.
- Three adapters, each owning its dialect's quirks:
  - `StrongCsvAdapter` — header has `Exercise Name` + `Set Order`. Groups rows by (Date, Workout Name). Non-numeric `Set Order` beginning with `W` marks a warm-up. Cardio-shaped rows (distance/seconds without weight×reps) are counted as skipped. Handles both known header variants (with and without `Weight Unit`).
  - `HevyCsvAdapter` — header has `exercise_title` + `weight_kg`. Groups by (title, start_time); `set_type: warmup` maps to the warm-up flag. Flexible date parsing (ISO and `d MMM yyyy, HH:mm` variants).
  - `RepFoundryCsvAdapter` — header exactly `date,exercise,weight,reps,rpe,volume,e1rm`. Our export has no workout boundaries, so sets group into one workout per calendar day, started at the first set's timestamp.
- `ParsedHistory` neutral model: parsed workouts (source key, name, start/end) holding parsed sets (exercise name, weight in kg, reps, optional RPE, warm-up flag, timestamp). Adapters convert lbs→kg via `WeightUnit`.
- Row skipping: blank/zero reps, cardio-shaped rows, unparseable rows — each counted, never fatal. A file whose structure cannot be parsed aborts with an error **before any database write**.
- Format detection: header sniffing as above; content starting with `{` routes to the existing JSON import; anything else is a clean "unsupported format" error.

### Import engine — `CsvImportEngine`

Consumes `ParsedHistory`, mirrors the write style of `importFromJson` (per-entity repository calls, per-row try/catch):

- **Exercise resolution:** trimmed case-insensitive name match against `getAllExercises()`; unmatched names become custom exercises (`category: strength`, `muscleGroup: fullBody`, `equipmentType: other`, `isCustom: true`).
- **Deterministic IDs:** UUIDv5 under a fixed app namespace — workout from `source|startISO|name`; set from workout key + exercise + set index + weight + reps; created exercise from lowercased name. Duplicate inserts throw and are counted as skipped.
- **Timestamps:** `updatedAt` = the historical time, so later local edits win last-write-wins sync merges.
- **PR backfill:** per imported exercise, best e1RM / max weight / max reps / max volume compared against stored bests with strict `>`; winners create PR rows dated to the achieving set. Strict comparison keeps backfill idempotent.
- **Result:** `ImportResult` gains `exercisesCreated`, `rowsSkipped`, `duplicatesSkipped` (defaulting to 0; existing callers unaffected).

Safety property: parsing is all-or-nothing before any write, and writes are additive-only inserts — a mid-import failure cannot corrupt existing data, and re-running completes the remainder idempotently.

### Settings UI

- New "Import from File" row in the Data section beside the existing import row; `file_picker` filtered to `.csv`/`.json`.
- Flow: pick file → detect format → confirmation dialog naming the detected format (plus kg/lbs choice when ambiguous) → busy state → SnackBar summary (imported counts, exercises created, rows and duplicates skipped).
- New strings in all five ARB files + `flutter gen-l10n`.

## Testing

Fixture CSVs per format under `test/features/settings/fixtures/` (quoted commas, blank RPEs, warm-up markers, a Strong lbs file, cardio rows, malformed file). Parser tests per adapter; engine tests for name matching, custom-exercise creation, unit conversion, import-twice idempotency, and PR backfill both directions; use-case-level test on in-memory repositories; settings widget test for the new row. TDD throughout.

## Delivery

Single branch and PR (`Closes #68`), no stacking. Full `flutter test` + `dart analyze` + `dart format` before push.
