# Documentation Update — High-Impact Pages

**Date:** 2026-04-10
**Author:** Paul Snow

## Context

The RepFoundry codebase has evolved significantly since the documentation was last updated in early March 2026. Several features (sync, analytics, body metrics, programmes, notifications) have been implemented, CI/CD is live, navigation expanded from 3 to 5 tabs, and ~150 tests were added. The Antora documentation site and CLAUDE.md are stale in key areas.

## Goal

Update the highest-impact Antora pages and CLAUDE.md so that:
- A new contributor can understand the current architecture accurately
- AI tooling (CLAUDE.md) has correct context for future work

## Scope — 6 Files

### 1. `src/docs/modules/ROOT/pages/architecture.adoc`

**Changes:**
- Update navigation section from 3-tab to 5-tab shell (Workout, History, Cardio, Heart Rate, Settings)
- Move cloud sync from "future/deferred" to "implemented features" with brief summary
- Add analytics, body_metrics, programmes, notifications to the feature directory listing
- Update CI/CD section from "not yet configured" to document the GitHub Actions APK release pipeline
- Update tech stack table to reflect current Gradle, Kotlin, and dependency versions

### 2. `src/docs/modules/ROOT/pages/testing.adoc`

**Changes:**
- Document the three-layer test structure: unit tests, widget tests, integration tests
- Document testing patterns used in the codebase:
  - File-local fake repositories for use case tests
  - `InMemory*Repository` classes from `lib/` for controller and widget tests
  - `AppDatabase.forTesting(NativeDatabase.memory())` for Drift repository tests
  - `ProviderContainer(overrides: [...])` for presentation controller tests
  - `buildScreen()` helpers with `ProviderScope` + `MaterialApp` + localisation delegates for widget tests
  - `createTestApp()` + `pumpUntilFound()` for integration tests
- Document how to run tests: `flutter test`, single file, integration tests
- Document conventions: coverage targets (80% domain/application, 60% presentation), test naming, localisation setup in widget tests
- No hard-coded test counts — structure and patterns only

### 3. `src/docs/modules/ROOT/pages/features/sync.adoc` (new file)

**Content:**
- Overview: offline-first cloud sync via iCloud (iOS) / Google Drive (Android)
- SyncOrchestrator 6-step flow: check connectivity, create local snapshot, download remote, merge, apply merged to local DB, upload merged to cloud
- SyncMergeEngine: updatedAt-wins conflict resolution strategy
- SyncSnapshot model: 11 entity lists (exercises, workouts, workoutSets, cardioSessions, personalRecords, workoutTemplates, templateExercises, bodyMetrics, programmes, programmeDays, progressionRules) plus metadata (snapshotAt, deviceId, schemaVersion)
- CloudSyncService interface + CloudKit platform channel implementation
- SyncSettings (enabled, lastSyncAt, deviceId, consentGiven) and SyncState (idle/syncing/success/error) providers
- Design principle: sync is best-effort, errors are swallowed, never blocks user actions (fire-and-forget after workout completion)

### 4. `src/docs/modules/ROOT/nav.adoc`

**Change:** Add `sync.adoc` entry under the features section of the navigation tree.

### 5. `CLAUDE.md` (project root)

**Changes:**
- Update feature directory listing from 7 to all 13 features under `lib/features/`
- Add brief sync architecture summary (SyncOrchestrator, merge engine, CloudSyncService)
- Add brief descriptions for analytics, body_metrics, programmes, notifications features
- Update navigation section to describe 5-tab shell
- Note GitHub Actions CI/CD pipeline exists

### 6. Validation

- Run `gradle21w antora` to verify all Antora pages build without errors

## Out of Scope

- Updating individual feature pages for analytics, body_metrics, programmes, notifications (they already exist in Antora; separate update pass)
- Migrating PRDs from `docs/` into Antora product pages
- Updating the markdown docs in `docs/` (superseded by Antora as source of truth)

## Success Criteria

- `gradle21w antora` builds with zero errors
- Architecture page accurately reflects the 5-tab navigation, 13 features, shipped sync, and live CI/CD
- Testing page documents patterns without hard-coded counts
- New sync feature page provides enough context for a contributor to understand the sync architecture
- CLAUDE.md provides accurate context for AI tooling
