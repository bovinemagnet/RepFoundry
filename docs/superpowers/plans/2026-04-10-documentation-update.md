# Documentation Update — High-Impact Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the highest-impact Antora documentation pages and CLAUDE.md so that new contributors and AI tooling have accurate context for the current codebase.

**Architecture:** Pure documentation changes across 6 files — 4 Antora AsciiDoc pages (3 existing, 1 new), 1 Antora nav file, and 1 project root CLAUDE.md. No code changes. Validated by `gradle21w antora` building without errors.

**Tech Stack:** AsciiDoc (Antora), Markdown (CLAUDE.md), Gradle (Antora build validation)

---

## File Map

| # | File | Action | Responsibility |
|---|------|--------|----------------|
| 1 | `src/docs/modules/ROOT/pages/architecture.adoc` | Modify | Update CI/CD, feature listing, offline-first/sync section |
| 2 | `src/docs/modules/ROOT/pages/testing.adoc` | Modify | Add missing test patterns (buildScreen, createTestApp, ProviderContainer) |
| 3 | `src/docs/modules/ROOT/pages/features/sync.adoc` | Create | New sync feature page |
| 4 | `src/docs/modules/ROOT/nav.adoc` | Modify | Add sync.adoc to navigation |
| 5 | `CLAUDE.md` | Modify | Update feature list, add sync/analytics/body_metrics/programmes/notifications summaries, note CI/CD |
| 6 | — | — | Validation: `gradle21w antora` builds with zero errors |

---

### Task 1: Update architecture.adoc — CI/CD section

**Files:**
- Modify: `src/docs/modules/ROOT/pages/architecture.adoc:68-75` (tech stack CI/CD row)
- Modify: `src/docs/modules/ROOT/pages/architecture.adoc:276-309` (CI/CD pipeline section)

- [x] **Step 1: Update CI/CD row in tech stack table**

Replace the two planned/not-yet-configured rows in the tech stack table (lines 68–75) with:

```asciidoc
| CI/CD
| GitHub Actions
| Automated APK build and GitHub Release on version tags
```

Remove the "Analytics / Crash" planned row entirely (it is out of scope for this update and not yet implemented).

- [x] **Step 2: Replace the CI/CD Pipeline section**

Replace the entire `== CI/CD Pipeline (Planned)` section (lines 276–309) with:

```asciidoc
== CI/CD Pipeline

GitHub Actions automates the release process.
The workflow is defined in `.github/workflows/release.yml`.

=== Android APK Release

Triggered by pushing a tag matching `v*`.

Steps:

. Checkout repository
. Set up Java 17 (Temurin) and Flutter (stable channel)
. Run `flutter pub get`
. Detect pre-release: tags ending in `-SNAPSHOT` (case-insensitive) are marked as pre-release
. Decode and write the Android keystore from repository secrets (`KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`) if `KEYSTORE_BASE64` is set
. Build release APK: `flutter build apk --release`
. Rename APK to `RepFoundry-{tag}.apk`
. Create a GitHub Release via `softprops/action-gh-release@v2` with auto-generated release notes and the APK attached as an artifact

NOTE: iOS build and deployment are not yet automated.
```

- [x] **Step 3: Verify the file is valid AsciiDoc**

Run: `gradle21w antora 2>&1 | head -40`
Expected: No errors referencing `architecture.adoc`

- [x] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/architecture.adoc
git commit -m "Update architecture.adoc CI/CD section to reflect live pipeline"
```

---

### Task 2: Update architecture.adoc — feature listing and project structure

**Files:**
- Modify: `src/docs/modules/ROOT/pages/architecture.adoc:83-111` (project structure tree)

- [x] **Step 1: Update the feature directory listing in the project structure tree**

Replace the feature listing block inside the `[source]` tree (lines 90–101) so it lists all 13 features:

```asciidoc
[source]
----
lib/
├── app/                      # App-level config, theme, router
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── features/
│   ├── analytics/            # Training analytics and charts
│   ├── body_metrics/         # Weight and body fat tracking
│   ├── cardio/               # Cardio tracking feature
│   ├── exercises/            # Exercise library feature
│   ├── health_sync/          # Platform health data sync
│   ├── heart_rate/           # Real-time HR monitoring panel
│   ├── history/              # Workout history and progress
│   ├── notifications/        # Scheduled workout reminders
│   ├── programmes/           # Multi-week training programmes
│   ├── settings/             # App preferences
│   ├── sync/                 # Cloud sync (iCloud / Google Drive)
│   ├── templates/            # Workout templates
│   └── workout/              # Workout logging feature
├── core/                     # Shared utilities
│   ├── database/             # Drift database, tables, converters
│   │   ├── app_database.dart # @DriftDatabase class + seed data
│   │   ├── converters.dart   # DateTime↔epoch ms, enum↔string
│   │   ├── database_provider.dart  # Riverpod provider
│   │   └── tables/           # Drift table definitions
│   ├── extensions/           # Dart extension methods
│   └── widgets/              # Reusable UI components
└── main.dart
----
```

- [x] **Step 2: Commit**

```bash
git add src/docs/modules/ROOT/pages/architecture.adoc
git commit -m "Update architecture.adoc feature directory listing to 13 features"
```

---

### Task 3: Update architecture.adoc — offline-first / sync section

**Files:**
- Modify: `src/docs/modules/ROOT/pages/architecture.adoc:242-255` (offline-first strategy section)

- [x] **Step 1: Replace the offline-first strategy section**

Replace the entire `== Offline-First Strategy` section (lines 242–255) with:

```asciidoc
== Offline-First Strategy

The app is designed to work entirely offline.
All data is persisted locally via Drift (SQLite).
No feature requires network connectivity — this is critical for gym environments with poor connectivity.

=== Cloud Sync

Cloud sync is implemented as a best-effort, fire-and-forget layer on top of the offline-first core.
Sync never blocks user actions; errors are swallowed and surfaced only as UI status indicators.

The sync feature uses iCloud (via CloudKit platform channel) on iOS and Google Drive (hidden app data folder) on Android.
See xref:features/sync.adoc[Cloud Sync] for the full architecture.

Key design principles:

* *Local-first writes* — all data is written to SQLite immediately; sync runs after the fact
* *Best-effort sync* — connectivity failures are silently tolerated; the user is never blocked
* *updatedAt-wins conflict resolution* — when the same entity exists on both devices, the newer `updatedAt` timestamp wins; ties favour the local copy
* *Fire-and-forget* — sync triggers automatically after workout completion but can also be triggered manually from Settings
```

- [x] **Step 2: Update the Future Architecture Plans section**

In the `== Future Architecture Plans` section (lines 319–327), remove the bullet about "Cloud sync layer" since sync is now implemented. The bullet reads:

```
* *Cloud sync layer* — repository interfaces are designed so a remote data source can be added behind the same contract without changing the application or presentation layers
```

Remove that single bullet point.

- [x] **Step 3: Commit**

```bash
git add src/docs/modules/ROOT/pages/architecture.adoc
git commit -m "Update architecture.adoc offline-first section to document shipped sync"
```

---

### Task 4: Update testing.adoc — add missing test patterns

**Files:**
- Modify: `src/docs/modules/ROOT/pages/testing.adoc`

- [x] **Step 1: Update the test structure tree**

Replace the test directory tree (lines 9–30) to include all 13 feature directories:

```asciidoc
[source]
----
test/
├── features/
│   ├── analytics/
│   ├── body_metrics/
│   ├── cardio/
│   ├── exercises/
│   ├── health_sync/
│   ├── heart_rate/
│   ├── history/
│   ├── notifications/
│   ├── programmes/
│   ├── settings/
│   ├── sync/
│   ├── templates/
│   └── workout/
│       ├── domain/
│       │   └── workout_test.dart
│       ├── application/
│       │   └── log_set_use_case_test.dart
│       ├── data/
│       │   └── drift_workout_repository_test.dart
│       └── presentation/
│           └── active_workout_controller_test.dart
├── core/
│   └── database/
│       └── app_database_test.dart
└── integration_test/            # Full user-flow tests (separate directory at project root)
----
```

- [x] **Step 2: Add ProviderContainer pattern to presentation controller tests section**

After the existing Widget Tests section (after line 136), add a new section for presentation controller tests:

```asciidoc
=== Presentation Controller Tests

Riverpod controllers (`Notifier`, `AsyncNotifier`) are tested without a widget tree using `ProviderContainer` with overrides.
This isolates controller logic from rendering.

[source,dart]
----
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository()),
        workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('loads initial state from repository', () async {
    final notifier = container.read(analyticsProvider.notifier);
    // assert on notifier state …
  });
}
----
```

- [x] **Step 3: Add buildScreen() pattern to widget tests section**

In the existing Widget Tests section, after the localisation delegates code block (line 134), add:

```asciidoc
Many widget tests use a local `buildScreen()` helper to reduce boilerplate:

[source,dart]
----
Widget buildScreen() {
  return ProviderScope(
    overrides: [/* provider overrides */],
    child: MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: const ScreenUnderTest(),
    ),
  );
}
----

Call `tester.pumpWidget(buildScreen())` in each test to get a fully wired widget with localisation and mocked providers.
```

- [x] **Step 4: Add createTestApp / pumpUntilFound pattern to integration tests section**

Replace the existing Integration Tests section (lines 138–144) with:

```asciidoc
=== Integration Tests

Integration tests cover full user flows — for example, starting a workout, logging sets, finishing, and verifying the session appears in history.
They run on a real emulator (Android) or simulator (iOS).

Integration tests live under `integration_test/` at the project root (separate from `test/`).

The shared `createTestApp()` helper in `integration_test/test_app.dart` bootstraps the full app with a test database.
Tests use `pumpUntilFound()` to wait for asynchronous widgets to appear before interacting:

[source,dart]
----
void main() {
  testWidgets('complete workout flow', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpUntilFound(find.text('Start Workout'));
    // interact with the app …
  });
}
----
```

- [x] **Step 5: Commit**

```bash
git add src/docs/modules/ROOT/pages/testing.adoc
git commit -m "Update testing.adoc with missing test patterns and full feature directory list"
```

---

### Task 5: Create sync feature page

**Files:**
- Create: `src/docs/modules/ROOT/pages/features/sync.adoc`

- [x] **Step 1: Create the sync.adoc file**

Write the following content to `src/docs/modules/ROOT/pages/features/sync.adoc`:

```asciidoc
= Cloud Sync
Paul Snow
:description: Offline-first cloud sync architecture — iCloud (iOS) and Google Drive (Android)
:keywords: sync, cloud, iCloud, CloudKit, Google Drive, offline-first, conflict resolution

RepFoundry syncs workout data across devices using iCloud on iOS and Google Drive on Android.
Sync is best-effort and fire-and-forget — it never blocks user actions or shows loading spinners.
Errors are swallowed and surfaced only as status indicators in the Settings screen.

== Overview

The sync feature sits on top of the offline-first SQLite core.
All data is written locally first; sync runs after the fact (e.g. after completing a workout).
If the device is offline or sync fails, the user is unaffected.

Platform backends:

* *iOS* — CloudKit via a platform channel (`com.repfoundry.app/cloudkit_sync`)
* *Android* — Google Drive hidden app data folder (`driveAppdataScope`) via `googleapis` + `google_sign_in`

Platform selection is handled by `SyncServiceFactory`: `Platform.isIOS` returns `CloudKitSyncService`, all other platforms return `GoogleDriveSyncService`.

== SyncOrchestrator — 6-Step Flow

`SyncOrchestrator.sync()` coordinates the full sync cycle.
A `_isSyncing` guard prevents concurrent runs.

. *Check connectivity* — query `connectivity_plus`; bail with error status if offline
. *Create local snapshot* — read all local DB rows (including soft-deleted) into a `SyncSnapshot` via `SyncSnapshotSerialiser.createFromDatabase()`
. *Download remote snapshot* — call `CloudSyncService.downloadSnapshot()`; returns `null` on first sync
. *Merge* — pass local and remote snapshots to `SyncMergeEngine.merge()`; if no remote exists, use local as-is
. *Apply merged snapshot to local DB* — `SyncSnapshotSerialiser.applyToDatabase()` writes all entities in a single Drift transaction using `insertOnConflictUpdate`
. *Upload merged snapshot to cloud* — `CloudSyncService.uploadSnapshot()` serialises the merged snapshot as JSON

== SyncMergeEngine — Conflict Resolution

The merge engine uses an *updatedAt-wins* strategy, resolved per entity by UUID:

* Entities unique to either side are included unconditionally
* When the same UUID exists in both snapshots, the entity with the newer `updatedAt` wins
* Ties (equal timestamps) favour the local copy
* Output snapshot carries `snapshotAt: DateTime.now().toUtc()` and inherits `deviceId` and `schemaVersion` from the local snapshot

The merge is a pure function with no side effects — it takes two `SyncSnapshot` objects and returns a third.

== SyncSnapshot Model

`SyncSnapshot` is an immutable value object holding all syncable data.

=== Metadata

[cols="1,1,2",options="header"]
|===
| Field | Type | Description

| `snapshotAt`
| `DateTime` (UTC)
| When the snapshot was created

| `deviceId`
| `String`
| UUID of the originating device

| `schemaVersion`
| `int`
| Database schema version (currently 6)
|===

=== Entity Lists (11)

[cols="1,2",options="header"]
|===
| List | Domain Model

| `exercises` | `Exercise`
| `workouts` | `Workout`
| `workoutSets` | `WorkoutSet`
| `cardioSessions` | `CardioSession`
| `personalRecords` | `PersonalRecord`
| `workoutTemplates` | `WorkoutTemplate`
| `templateExercises` | `TemplateExercise`
| `bodyMetrics` | `BodyMetric`
| `programmes` | `Programme`
| `programmeDays` | `ProgrammeDay`
| `progressionRules` | `ProgressionRule`
|===

All lists default to `const []`.

== CloudSyncService Interface

`CloudSyncService` (`lib/features/sync/domain/sync_service.dart`) defines four methods:

[cols="2,3",options="header"]
|===
| Method | Description

| `Future<bool> isAvailable()`
| Check authentication and service availability

| `Future<void> uploadSnapshot(String jsonData)`
| Upload serialised snapshot JSON to cloud

| `Future<String?> downloadSnapshot()`
| Download latest snapshot; returns `null` if none exists

| `Future<void> deleteCloudData()`
| Delete cloud data and sign out
|===

=== CloudKit Implementation (iOS)

`CloudKitSyncService` communicates via a platform channel named `com.repfoundry.app/cloudkit_sync`.
Method calls map directly to the interface: `isAvailable`, `uploadSnapshot`, `downloadSnapshot`, `deleteCloudData`.
`PlatformException` on `isAvailable` gracefully returns `false`.

=== Google Drive Implementation (Android)

`GoogleDriveSyncService` uses `googleapis/drive/v3` with `google_sign_in`.
Data is stored as `repfoundry_sync.json` in the hidden `appDataFolder` space (not visible in the user's Drive).
Upload updates the existing file by ID if found, otherwise creates a new file.
`deleteCloudData()` deletes the file and calls `_googleSignIn.disconnect()`.

== State Management

Two Riverpod providers manage sync state, both defined in `lib/features/sync/presentation/providers/sync_settings_provider.dart`.

=== SyncSettings (persisted)

`syncSettingsProvider` — `NotifierProvider<SyncSettingsNotifier, SyncSettings>`

Persisted via `SharedPreferences` under keys: `cloud_sync_enabled`, `cloud_sync_last_sync_at`, `cloud_sync_device_id`, `cloud_sync_consent_given`.

[cols="1,1,2",options="header"]
|===
| Field | Type | Description

| `enabled` | `bool` | Whether sync is turned on
| `lastSyncAt` | `DateTime?` | Timestamp of last successful sync
| `deviceId` | `String` | UUID v4, generated on first build and persisted
| `consentGiven` | `bool` | Whether user has accepted the sync consent dialog
|===

=== SyncState (in-memory)

`syncStateProvider` — `NotifierProvider<SyncStateNotifier, SyncState>`

Not persisted; resets to `idle` on app restart.

`SyncStatus` enum: `idle`, `syncing`, `success`, `error`.

=== Consent Flow

A `SyncConsentDialog` is shown the first time sync is enabled.
The dialog returns a `bool`; sync only proceeds if consent is granted.

== File Inventory

[cols="2,3",options="header"]
|===
| File | Purpose

| `application/sync_orchestrator.dart` | 6-step sync coordinator
| `domain/sync_merge_engine.dart` | updatedAt-wins merge logic
| `domain/sync_service.dart` | `CloudSyncService` abstract interface
| `domain/models/sync_snapshot.dart` | Snapshot value object (11 entity lists + metadata)
| `domain/models/sync_settings.dart` | User-facing settings model
| `domain/models/sync_state.dart` | Runtime UI state + `SyncStatus` enum
| `domain/models/sync_result.dart` | Return value from sync (success, count, timestamp)
| `data/sync_snapshot_serialiser.dart` | DB ↔ JSON serialisation; hard-codes `schemaVersion: 6`
| `data/cloudkit_sync_service.dart` | CloudKit platform channel implementation
| `data/google_drive_sync_service.dart` | Google Drive implementation via `googleapis`
| `data/sync_service_factory.dart` | Platform factory: iOS → CloudKit, else → Google Drive
| `presentation/providers/sync_settings_provider.dart` | Riverpod providers for settings + state
| `presentation/widgets/sync_consent_dialog.dart` | One-time consent dialog
|===
```

- [x] **Step 2: Verify the file builds**

Run: `gradle21w antora 2>&1 | head -40`
Expected: No errors referencing `sync.adoc`

- [x] **Step 3: Commit**

```bash
git add src/docs/modules/ROOT/pages/features/sync.adoc
git commit -m "Add sync feature documentation page"
```

---

### Task 6: Update nav.adoc — add sync entry

**Files:**
- Modify: `src/docs/modules/ROOT/nav.adoc`

- [x] **Step 1: Add sync.adoc to the features section**

The current nav.adoc features section (lines 6–14) lists features alphabetically after Workout Logging and Cardio Tracking. Add the sync entry. The full features block should become:

```asciidoc
* Features
** xref:features/workout.adoc[Workout Logging]
** xref:features/cardio.adoc[Cardio Tracking]
** xref:features/heart-rate.adoc[Heart Rate Monitoring]
** xref:features/programmes.adoc[Programme Builder]
** xref:features/analytics.adoc[Advanced Analytics]
** xref:features/sync.adoc[Cloud Sync]
** xref:features/health-sync.adoc[Health Sync]
** xref:features/body-metrics.adoc[Body Metrics]
** xref:features/notifications.adoc[Notifications]
```

- [x] **Step 2: Commit**

```bash
git add src/docs/modules/ROOT/nav.adoc
git commit -m "Add cloud sync to Antora navigation"
```

---

### Task 7: Update CLAUDE.md — feature list, sync, new features, CI/CD

**Files:**
- Modify: `CLAUDE.md` (project root)

- [x] **Step 1: Update the feature directory listing**

Replace the single line (line 39):

```
**Feature directories** under `lib/features/`: `workout`, `exercises`, `history`, `cardio`, `heart_rate`, `templates`, `settings`. Each feature contains its own `presentation/`, `application/`, `domain/`, and `data/` sub-layers.
```

With:

```
**Feature directories** under `lib/features/`: `analytics`, `body_metrics`, `cardio`, `exercises`, `health_sync`, `heart_rate`, `history`, `notifications`, `programmes`, `settings`, `sync`, `templates`, `workout`. Each feature contains its own `presentation/`, `application/`, `domain/`, and `data/` sub-layers.
```

- [x] **Step 2: Add sync architecture summary after the State Management section**

After the State Management section (after line 74), add a new section:

```markdown
## Cloud Sync

Offline-first cloud sync via iCloud (iOS) / Google Drive (Android). Key components:

- **SyncOrchestrator**: 6-step flow — check connectivity, create local snapshot, download remote, merge, apply to local DB, upload to cloud. Guard prevents concurrent runs.
- **SyncMergeEngine**: updatedAt-wins conflict resolution per entity UUID. Ties favour local. Pure function, no side effects.
- **CloudSyncService**: Abstract interface with `isAvailable()`, `uploadSnapshot()`, `downloadSnapshot()`, `deleteCloudData()`. `CloudKitSyncService` (iOS, platform channel) and `GoogleDriveSyncService` (Android, googleapis).
- **SyncSnapshot**: 11 entity lists (exercises, workouts, workoutSets, cardioSessions, personalRecords, workoutTemplates, templateExercises, bodyMetrics, programmes, programmeDays, progressionRules) + metadata (snapshotAt, deviceId, schemaVersion).
- **SyncSettings/SyncState**: Riverpod providers. Settings persisted via SharedPreferences; state is in-memory only (idle/syncing/success/error).
- Design principle: sync is best-effort, errors are swallowed, never blocks user actions.

## Additional Features

- **Analytics** (`lib/features/analytics/`): Four Riverpod providers (weekly volume, muscle balance, PR timeline, training load) consumed by `AnalyticsScreen` with fl_chart charts. Presentation-only layer over workout data.
- **Body Metrics** (`lib/features/body_metrics/`): Tracks weight and optional body fat percentage entries (`BodyMetric` model). Backed by `DriftBodyMetricRepository`.
- **Programmes** (`lib/features/programmes/`): Multi-week training programmes (`Programme`, `ProgrammeDay`, `ProgressionRule` models) with three progression strategies (fixedIncrement, percentage, deload). Drift repository + list/edit screens.
- **Notifications** (`lib/features/notifications/`): `NotificationService` wrapping `flutter_local_notifications` with timezone support. `ReminderSettings` model + Riverpod provider for scheduled workout reminders.
- **Health Sync** (`lib/features/health_sync/`): Platform health data synchronisation.
```

- [x] **Step 3: Update navigation description**

The Navigation section (line 78) already says:

```
ShellRoute with bottom nav (Workout, History, Cardio, Heart Rate, Settings). Routes defined in `lib/app/router.dart`.
```

This is already correct (5 tabs). No change needed.

- [x] **Step 4: Add CI/CD note**

After the Testing section (after line 88), add:

```markdown
## CI/CD

GitHub Actions workflow (`.github/workflows/release.yml`) builds a signed Android APK on `v*` tag pushes and creates a GitHub Release with the APK attached. Tags ending in `-SNAPSHOT` are marked as pre-release. iOS build is not yet automated.
```

- [x] **Step 5: Update the Documentation section**

Replace the Documentation section (lines 100–104) with:

```markdown
## Documentation

Antora documentation site: `src/docs/` (build with `gradle21w antora`)
Architecture document (legacy): `docs/RepFoundry.Architecture.md`
Product requirements (legacy): `docs/RepFoundry.prd.md`
Heart rate monitoring PRD (legacy): `docs/heartRateMonitoringPRD.md`
```

- [x] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "Update CLAUDE.md with current features, sync architecture, and CI/CD"
```

---

### Task 8: Validate Antora build

**Files:** None (validation only)

- [x] **Step 1: Run the Antora build**

Run: `gradle21w antora`
Expected: Build completes with zero errors. Warnings about missing pages or broken xrefs would indicate a problem.

- [x] **Step 2: If errors exist, fix them**

Read the error output, identify the offending file and line, and correct the AsciiDoc syntax or cross-reference.

- [x] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "Fix Antora build errors from documentation update"
```

Only run this step if fixes were needed.
