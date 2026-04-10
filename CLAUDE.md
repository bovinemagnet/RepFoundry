# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RepFoundry is a cross-platform Flutter/Dart workout tracking app targeting iOS 15+ and Android 10+. It follows clean architecture with feature-first modularisation, Riverpod for state management, and an offline-first design with SQLite persistence via Drift.

## Build & Development Commands

```bash
flutter pub get              # Install dependencies
flutter test                 # Run all tests
flutter test test/features/workout/domain/workout_test.dart  # Run a single test file
flutter run -d <device>      # Run on device/emulator
flutter build apk            # Build Android APK
flutter build ios            # Build iOS
dart analyze                 # Lint (CI enforces zero issues)
dart format --set-exit-if-changed .  # Format check
dart run build_runner build --delete-conflicting-outputs  # Regenerate Drift code
flutter gen-l10n             # Regenerate localisation files from ARB
```

Android has three build flavours: `dev`, `staging`, `prod`. The Android namespace is `com.repfoundry.app`.

## Architecture

**Layer structure** (dependencies flow inward only):

```
Presentation → Application → Domain ← Data
```

- **Domain**: Pure Dart models (`Workout`, `WorkoutSet`, `Exercise`, `CardioSession`, `WorkoutTemplate`, `PersonalRecord`) and repository interfaces. No Flutter imports. Presentation-only models (e.g. `GhostSet`) live under their feature's `presentation/models/` directory.
- **Application**: Use cases (`LogSetUseCase`, `StartWorkoutUseCase`, `CalculateProgressUseCase`). Pure Dart, depend on repository interfaces.
- **Data**: Repository implementations (`DriftExerciseRepository`, `DriftWorkoutRepository` for production; `InMemory*Repository` kept for testing). Soft deletes via `deletedAt` field.
- **Presentation**: Screens, widgets, and Riverpod controllers (`Notifier`, `AsyncNotifier`). Screens are thin — logic lives in controllers.

**Feature directories** under `lib/features/`: `analytics`, `body_metrics`, `cardio`, `exercises`, `health_sync`, `heart_rate`, `history`, `notifications`, `programmes`, `settings`, `sync`, `templates`, `workout`. Each feature contains its own `presentation/`, `application/`, `domain/`, and `data/` sub-layers.

Shared code lives in `lib/core/` (extensions, widgets, providers, database).

## Database (Drift / SQLite)

The app uses Drift for SQLite persistence. Key files:

- `lib/core/database/app_database.dart` — `@DriftDatabase` class with 7 tables, `forTesting(QueryExecutor)` constructor, and seed data (18 default exercises)
- `lib/core/database/tables/` — Drift table definitions (exercises, workouts, workout_sets, cardio_sessions, personal_records, workout_templates, template_exercises)
- `lib/core/database/converters.dart` — DateTime↔epoch ms and enum↔string helpers
- `lib/core/database/database_provider.dart` — Riverpod `Provider<AppDatabase>` overridden in `main()`
- `build.yaml` — Drift build_runner configuration

Design decisions:
- **Epoch ms storage**: `IntColumn` with manual conversion for millisecond precision
- **Enum as string**: Stores `.name` — human-readable, safe against enum reordering
- **String UUID PKs**: Match existing domain model pattern
- **`PRAGMA foreign_keys = ON`**: Enabled in `beforeOpen` for referential integrity
- **`driftDatabase()`**: LazyDatabase — DB opens on first query, no loading screen needed
- **Import aliasing**: Drift-generated data classes (`Exercise`, `Workout`, `WorkoutSet`) conflict with domain models; repository files use `import '...app_database.dart' as db;`

## State Management (Riverpod)

Provider hierarchy:
- `Provider` — static dependencies (repositories)
- `FutureProvider` — one-shot async data
- `StreamProvider` — reactive data (history lists, active sets)
- `NotifierProvider` — mutable UI state (active workout controller, rest timer, rest timer settings)

Key patterns:
- Sets are persisted immediately on entry (not batched) to prevent data loss.
- **Rest timer alerts**: `RestTimerWidget` uses `ref.listen()` on `restTimerProvider` to detect timer completion (non-null → null transition) and fires `HapticFeedback.heavyImpact()` and/or `AudioPlayer.play()` based on `restTimerSettingsProvider` toggles. Settings persisted via SharedPreferences.
- **Ghost set auto-fill**: When an exercise is added to a workout, `ActiveWorkoutController` fetches the last completed session's sets via `WorkoutRepository.getSetsFromLastSession()` and stores them as `GhostSet` objects in `ActiveWorkoutState.ghostSetsByExercise`. `SetInputCard` accepts an optional `GhostSet? suggestion` parameter to pre-populate weight/reps/RPE fields. Remaining ghosts render as dimmed placeholder rows in the exercise section.
- **BLE heart rate streaming**: `HeartRateService` interface (`heart_rate_service.dart`) abstracts BLE HR monitor access. `FlutterBlueHeartRateService` scans for BLE HR Service (0x180D), connects, and streams heart rate via characteristic 0x2A37. Supports Apple Watch (broadcast mode), Samsung Galaxy Watch, and standard chest straps. Auto-reconnects up to 2 times on unexpected disconnection with 2-second delays. `HrConnectionState` enum (`connected`, `reconnecting`, `disconnected`) drives UI state via `CardioTrackingController`. Setup guide dialog provides device-specific pairing instructions.
- **Heart rate panel**: Dedicated `heart_rate` feature (`lib/features/heart_rate/`) with its own domain layer, providers, and screen. Shows live BPM, dual fl_chart line graphs (recent sliding window + full session), session stats (avg/min/max), time-in-zone summary bars, and 5-zone heart rate training zones with dual labels (e.g. "Moderate (Aerobic)"). Supports multiple zone calculation methods (custom zones, clinician cap, HRR/Karvonen, measured max, age-estimated) via a priority chain in `zone_calculator.dart`. `HealthProfile` model holds age, resting HR, measured max HR, clinician cap, beta blocker flag, and heart condition flag — persisted via SharedPreferences in `HealthProfileNotifier`. Caution mode activates when medical flags are set, reducing zone reliability to Low and showing an amber caution badge. Reliability indicator (High/Medium/Low) shown alongside zones. First-use disclaimer dialog and 4-step onboarding bottom sheet guide profile setup. Symptom report button during active monitoring triggers a stop-exercise dialog. The panel shares the `HeartRateService` singleton with cardio — if cardio already has HR connected, the panel auto-syncs. `userAgeProvider` delegates to `healthProfileProvider` for backwards compatibility.

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

## Navigation (GoRouter)

ShellRoute with bottom nav (Workout, History, Cardio, Heart Rate, Settings). Routes defined in `lib/app/router.dart`.

## Key Business Logic

- **WorkoutSet.estimatedOneRepMax**: Epley formula — `weight * (1 + reps / 30.0)`
- **PR detection**: runs on each logged set in `LogSetUseCase`
- **Input validation**: weight >= 0, reps > 0, RPE 1–10 (optional)

## Testing

Tests live in `test/` mirroring `lib/` structure. Uses `flutter_test` + `mockito`. Use case tests use fake (in-memory) repository implementations for isolation. Drift repository tests use `NativeDatabase.memory()` via `AppDatabase.forTesting()`. Coverage targets: 80% domain/application, 60% presentation.

**No known test failures** — all tests should pass cleanly.

## CI/CD

GitHub Actions workflow (`.github/workflows/release.yml`) builds a signed Android APK on `v*` tag pushes and creates a GitHub Release with the APK attached. Tags ending in `-SNAPSHOT` are marked as pre-release. iOS build is not yet automated.

## Localisation (l10n)

All user-facing strings are externalised to `lib/l10n/app_en.arb` using Flutter's `gen-l10n` code generation. The generated class `S` lives in `lib/l10n/generated/` and is configured via `l10n.yaml` (output class `S`, output dir `lib/l10n/generated/`). Access strings via `S.of(context)!` in widget build methods. Widget tests must include `localizationsDelegates: S.localizationsDelegates` and `supportedLocales: S.supportedLocales` on their `MaterialApp`. Run `flutter gen-l10n` after modifying `.arb` files. The domain `warning_messages.dart` is retained as a non-Flutter fallback but presentation widgets use `S` instead.

## Linting

Uses `flutter_lints` with additional strict rules: `always_declare_return_types`, `prefer_const_constructors`, `prefer_final_fields`, `prefer_final_locals`. Missing required params and missing returns are treated as errors.

## Documentation

Antora documentation site: `src/docs/` (build with `gradle21w antora`)
Architecture document (legacy): `docs/RepFoundry.Architecture.md`
Product requirements (legacy): `docs/RepFoundry.prd.md`
Heart rate monitoring PRD (legacy): `docs/heartRateMonitoringPRD.md`
