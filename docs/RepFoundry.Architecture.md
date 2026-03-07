# RepFoundry — Architecture Document

**Version 1.0 | March 2026**
**Flutter / Dart • Riverpod • Clean Architecture**

---

## 1. Architecture Overview

RepFoundry follows a clean architecture pattern with clear separation between presentation, domain, and data layers. The app is built with Flutter and Dart, targeting both iOS and Android from a single codebase. The architecture prioritises offline-first operation, fast startup, and testability.

---

## 2. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Framework | Flutter 3.x / Dart 3.x | Cross-platform UI and application framework |
| State Management | Riverpod 2.x | Reactive state management with dependency injection |
| Local Database | Drift 2.x (SQLite) | Offline-first persistence with type-safe queries; in-memory repositories retained for testing |
| Navigation | GoRouter | Declarative routing with deep link support |
| Dependency Injection | Riverpod (built-in) | Provider-based DI with auto-dispose and scoping |
| Charts | fl_chart | High-performance charting for progress visualisation |
| Audio | audioplayers 6.x | Cross-platform audio playback for rest timer alerts |
| BLE | flutter_blue_plus | Bluetooth Low Energy scanning and connection for heart rate monitors |
| Location | geolocator | GPS position stream for outdoor cardio distance tracking |
| Testing | flutter_test, mockito, integration_test | Unit, widget, and integration testing |
| CI/CD | Planned — GitHub Actions + Fastlane | Automated build, test, and store deployment (not yet configured) |
| Analytics / Crash | Planned — Firebase Crashlytics + Analytics | Crash reporting and usage analytics (not yet integrated) |

---

## 3. Project Structure

The project uses a feature-first directory layout. Each feature contains its own presentation, application, and data sub-layers. Shared domain models and core utilities live in common directories.

```
lib/
├── app/                      # App-level config, theme, router
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── features/
│   ├── workout/              # Workout logging feature
│   │   ├── presentation/     # Screens, widgets, controllers
│   │   ├── application/      # Use cases, state notifiers
│   │   ├── domain/           # Models, repository interfaces
│   │   └── data/             # Repository impls (Drift + in-memory)
│   ├── exercises/            # Exercise library feature
│   ├── history/              # Workout history & progress
│   ├── cardio/               # Cardio tracking feature
│   ├── heart_rate/           # Real-time HR monitoring panel
│   ├── templates/            # Workout templates
│   └── settings/             # App preferences
├── core/                     # Shared utilities
│   ├── database/             # Drift database, tables, converters
│   │   ├── app_database.dart # @DriftDatabase class + seed data
│   │   ├── converters.dart   # DateTime↔epoch ms, enum↔string
│   │   ├── database_provider.dart  # Riverpod provider
│   │   └── tables/           # 7 Drift table definitions
│   ├── extensions/           # Dart extension methods
│   └── widgets/              # Reusable UI components
└── main.dart
```

---

## 4. Layer Architecture

### 4.1 Presentation Layer

Flutter widgets and screens consume state from Riverpod providers. Screens are thin and delegate all logic to controllers (StateNotifier classes). No business logic lives in widget build methods.

- **Screens:** full-page widgets mapped to GoRouter routes
- **Widgets:** reusable UI components (SetInputCard, RestTimerWidget, ExercisePicker, GhostSetRow). RestTimerWidget fires haptic vibration and an audible beep when the countdown completes, controlled by user preferences in `RestTimerSettings`.
- **Models:** presentation-only data objects (e.g. `GhostSet` — lightweight, non-persistable representation of a previous session's set used for auto-fill suggestions)
- **Controllers:** Riverpod Notifiers that manage screen-level state and coordinate use cases

### 4.2 Application Layer

Use cases encapsulate single business operations. They are pure Dart classes that depend on repository interfaces (not implementations), making them fully testable without Flutter or database dependencies.

- **LogSetUseCase:** validates input, persists set, updates workout summary
- **StartWorkoutUseCase:** creates workout record, loads template if applicable
- **CalculateProgressUseCase:** computes estimated 1RM, volume trends, PRs

### 4.3 Domain Layer

Pure Dart models with no framework dependencies. These are immutable data classes with hand-written copyWith methods and value equality.

| Model | Key Fields | Notes |
|-------|-----------|-------|
| Workout | id, startedAt, completedAt, templateId?, notes | Top-level container for a session |
| WorkoutSet | id, workoutId, exerciseId, setOrder, weight, reps, rpe?, timestamp | Single set within a workout |
| Exercise | id, name, category, muscleGroup, equipmentType, isCustom | Exercise definitions |
| CardioSession | id, workoutId, exerciseId, durationSeconds, distanceMeters?, incline?, avgHeartRate? | Cardio entry within a workout |
| WorkoutTemplate | id, name, exercises (List\<TemplateExercise\>), createdAt, updatedAt | Reusable workout blueprint |
| PersonalRecord | id, exerciseId, recordType, value, achievedAt | Tracked PRs (1RM, max reps, etc.) |

### 4.4 Data Layer

Repository implementations use Drift (SQLite) for production persistence and in-memory storage for testing. Each repository implements a domain-layer interface, keeping the persistence mechanism swappable.

**Production repositories:**

- `DriftExerciseRepository` — implements `ExerciseRepository` against SQLite
- `DriftWorkoutRepository` — implements `WorkoutRepository` against SQLite

**Test repositories (kept alongside):**

- `InMemoryExerciseRepository` — used by use case tests with hand-written fakes
- `InMemoryWorkoutRepository` — used by use case tests with hand-written fakes

Key data design decisions:

- Soft deletes on workouts and exercises (`deletedAt` field) to support undo and data recovery
- Repository interfaces return Streams for reactive data; Drift's query watcher efficiently invalidates only affected streams when data changes
- All timestamps stored as UTC epoch milliseconds (`IntColumn`) for consistency and sort performance
- Enums stored as their `.name` string — human-readable in the database and safe against reordering
- String UUID primary keys, matching the existing domain model pattern
- `PRAGMA foreign_keys = ON` enabled in `beforeOpen` for referential integrity
- 18 default exercises seeded on first run (IDs '1'–'18')
- `driftDatabase()` from `drift_flutter` provides a `LazyDatabase` — the DB opens on first query, avoiding a loading screen
- Import aliasing (`import '...app_database.dart' as db;`) resolves naming conflicts between Drift-generated data classes and domain models

---

## 5. Data Schema

All 7 tables are defined as Drift table classes in `lib/core/database/tables/`. Drift generates type-safe accessors, companion classes, and query watchers from these definitions. The generated code lives in `app_database.g.dart` (regenerate with `dart run build_runner build --delete-conflicting-outputs`).

| Table | Columns | Repository | Status |
|-------|---------|------------|--------|
| exercises | id (PK, text), name, category, muscle_group, equipment_type, is_custom, deleted_at | `DriftExerciseRepository` | Implemented |
| workouts | id (PK, text), started_at, completed_at, template_id (FK?), notes, deleted_at | `DriftWorkoutRepository` | Implemented |
| workout_sets | id (PK, text), workout_id (FK), exercise_id (FK), set_order, weight, reps, rpe, timestamp | `DriftWorkoutRepository` | Implemented |
| cardio_sessions | id (PK, text), workout_id (FK), exercise_id (FK), duration_seconds, distance_meters, incline, avg_heart_rate | — | Table only (repo deferred) |
| personal_records | id (PK, text), exercise_id (FK), record_type, value, achieved_at, workout_set_id (FK?) | — | Table only (repo deferred) |
| workout_templates | id (PK, text), name, created_at, updated_at | — | Table only (repo deferred) |
| template_exercises | id (PK, text), template_id (FK), exercise_id (FK), exercise_name, target_sets, target_reps, order_index | — | Table only (repo deferred) |

All datetime columns use `IntColumn` storing UTC epoch milliseconds. Enum columns use `TextColumn` storing the enum's `.name` string. All primary keys are text (UUID v4).

---

## 6. State Management

Riverpod is used throughout for reactive state management. The provider tree follows a clear hierarchy.

### 6.1 Provider Types

- **Provider:** static dependencies (database instance, repositories, use cases)
- **FutureProvider:** one-shot async data (exercise library load, single workout fetch)
- **StreamProvider:** reactive data (workout history list, active workout sets — powered by Drift query watchers)
- **NotifierProvider:** mutable UI state (active workout controller, rest timer, exercise search filter)

The `databaseProvider` is defined with an `UnimplementedError` default and overridden in `ProviderScope` inside `main()` with the real `AppDatabase` instance. Repository providers read from `databaseProvider` to obtain the database.

### 6.2 Active Workout State Flow

The most complex state in the app is the active workout. When a user starts a workout, an `ActiveWorkoutController` (StateNotifier) is created that holds the in-progress workout, its sets, and the rest timer state. Sets are persisted to the repository immediately on entry (not batched at the end) so that data is never lost if the app is killed.

The flow is:

1. User taps **Start Workout**
2. `ActiveWorkoutController` creates a `Workout` in the repository
3. User adds an exercise — the controller fetches sets from the last completed session for that exercise via `WorkoutRepository.getSetsFromLastSession()` and stores them as `GhostSet` objects in state
4. Ghost rows appear as dimmed placeholders beneath confirmed sets; `SetInputCard` is pre-populated with the next ghost set's weight/reps/RPE
5. User confirms each set (persisted immediately) — the ghost list advances automatically
6. Rest timer runs between sets
7. User taps **Finish**
8. Notifier marks workout as completed; unconsumed ghosts are discarded (never persisted)
9. History providers auto-refresh via broadcast streams

### 6.3 Ghost Set Auto-Fill

When an exercise is added to a workout, the controller queries the most recent completed session containing that exercise. The returned sets are converted to lightweight `GhostSet` objects (weight, reps, RPE, setOrder) — deliberately stripped of IDs and timestamps to prevent accidental persistence.

The `ActiveWorkoutState` exposes two helpers:
- `nextGhostSet(exerciseId)` — returns the ghost at index `loggedSetCount`, or `null` if all ghosts are consumed
- `remainingGhosts(exerciseId)` — returns the ghost list beyond the logged set count, used to render dimmed placeholder rows

Key files: `lib/features/workout/presentation/models/ghost_set.dart`, `lib/features/workout/presentation/controllers/active_workout_controller.dart`

### 6.4 Rest Timer Alerts

The rest timer (`restTimerProvider` in `rest_timer_widget.dart`) counts down from a user-selected duration. When the countdown transitions from a non-null value to `null`, the `RestTimerWidget` (a `ConsumerStatefulWidget`) detects this via `ref.listen()` and fires:

- **Haptic feedback:** `HapticFeedback.heavyImpact()` — uses Flutter's built-in `dart:services`, no external package
- **Sound alert:** `AudioPlayer.play(AssetSource('sounds/timer_complete.wav'))` — a bundled 0.5s 440 Hz sine-wave beep via the `audioplayers` package

Both alerts are gated by `RestTimerSettings` (vibration and sound toggles), persisted via SharedPreferences. The settings provider (`restTimerSettingsProvider`) follows the same `StateNotifier` + `SharedPreferences` pattern as the existing theme and weight-unit providers.

Key files: `lib/features/workout/presentation/widgets/rest_timer_widget.dart`, `lib/features/settings/presentation/providers/rest_timer_settings_provider.dart`, `assets/sounds/timer_complete.wav`

### 6.5 BLE Heart Rate Streaming

The cardio feature supports live heart rate streaming from any device that advertises the standard BLE Heart Rate Service (UUID 0x180D). This includes dedicated chest straps (Polar, Garmin, Wahoo), arm bands, Apple Watch (via its built-in "Broadcast Heart Rate" setting), and Samsung Galaxy Watch (via Samsung Health's BLE broadcast setting).

**Architecture:**

- `HeartRateService` (abstract) — defines the BLE contract: scan, connect, disconnect, heart rate stream, and connection state stream. The `HrConnectionState` enum (`connected`, `reconnecting`, `disconnected`) enables the UI to reflect connection lifecycle.
- `FlutterBlueHeartRateService` — production implementation using `flutter_blue_plus`. Scans for devices advertising 0x180D, connects, discovers the HR Measurement characteristic (0x2A37), and subscribes to notifications. Parses both 8-bit and 16-bit HR value formats per the BLE spec.
- `FakeHeartRateService` — test double with controllable streams for unit testing.

**Auto-reconnect:** When an unexpected BLE disconnection is detected (e.g. watch goes briefly out of range), the service automatically attempts up to 2 reconnections with a 2-second delay between attempts. If reconnection succeeds, services are re-discovered and the HR characteristic is re-subscribed. If all retries fail, a `disconnected` event is emitted. Intentional disconnects (via `disconnect()`) skip reconnection.

**Connection state flow:**

1. `connectToDevice()` → connects and emits `HrConnectionState.connected`
2. Unexpected disconnect detected → emits `HrConnectionState.reconnecting` → retries
3. Reconnect succeeds → emits `HrConnectionState.connected`
4. All retries fail → emits `HrConnectionState.disconnected`
5. `disconnect()` → intentional flag set, no reconnect attempt

**Controller integration:** `CardioTrackingController` subscribes to both `heartRateStream` (for BPM readings) and `connectionStateStream` (for reconnecting/disconnected states). The `hrReconnecting` field in `CardioTrackingState` drives a "Reconnecting..." indicator in the UI.

**UX guidance:** An in-app setup guide (`hr_setup_guide_dialog.dart`) provides device-specific instructions for enabling BLE broadcast on Apple Watch and Samsung Galaxy Watch. The guide is accessible via a help icon on the HR monitor card and a "Setup Help" button in the empty-state device picker.

Key files: `lib/features/cardio/data/heart_rate_service.dart`, `lib/features/cardio/data/flutter_blue_heart_rate_service.dart`, `lib/features/cardio/presentation/controllers/cardio_tracking_controller.dart`, `lib/features/cardio/presentation/widgets/hr_setup_guide_dialog.dart`, `lib/features/cardio/presentation/widgets/hr_device_picker_dialog.dart`

### 6.6 Heart Rate Panel

A dedicated heart rate monitoring screen (`lib/features/heart_rate/`) provides a focused view for tracking heart rate during any activity. It shares the `HeartRateService` singleton with the cardio feature — if cardio already has a BLE connection, the panel auto-syncs on navigation.

**Domain layer** (pure Dart, no Flutter imports):

- `HealthProfile` — user health data model: age, resting HR, measured max HR, clinician cap, beta blocker flag, heart condition flag, custom zones. `isCautionMode` computed property. `estimatedMaxHr` via 220 − age.
- `ZoneCalculator` — multi-method zone engine with priority chain: custom zones → clinician cap → caution mode → HRR/Karvonen → measured max → age-estimated. Returns `ZoneConfiguration` with `List<CalculatedZone>`, `ZoneMethod`, `ZoneReliability` (high/medium/low), and human-readable `reason`. HRR formula: `restingHR + pct × (maxHR − restingHR)`. 5-zone model with dual labels (e.g. "Moderate (Aerobic)").
- `TimeInZoneCalculator` — calculates per-zone time distribution from timestamped readings, total moderate-or-higher duration, and recovery HR drop (peak to 60s post-exercise).
- `WarningMessages` — static string constants for disclaimers, beta blocker/heart condition warnings, symptom prompts, and stop-exercise text. British spelling, localisation-ready.
- `HrAnalyticsEvent` + `HrAnalyticsReporter` — analytics event definitions and abstract reporter interface. `NoopAnalyticsReporter` (debug-log only) used for MVP.

**Providers:**

- `HealthProfileNotifier` (StateNotifier) — SharedPreferences-backed health profile. Migrates legacy `user_age` key to `hr_age` on first load. Methods: `updateAge`, `updateRestingHeartRate`, `updateMeasuredMaxHeartRate`, `setTakingBetaBlocker`, `setHasHeartCondition`, `setClinicianMaxHr`, `setCustomZones`.
- `zoneConfigurationProvider` (derived Provider) — watches `healthProfileProvider`, calls `calculateZones()`. Returns `ZoneConfiguration?`.
- `cautionModeProvider` (derived Provider) — `healthProfileProvider.isCautionMode`.
- `chartWindowProvider` (StateNotifier) — configurable sliding window duration (30s, 60s, 90s, 120s, 300s). Default 60s. Persisted via SharedPreferences.
- `userAgeProvider` — refactored to delegate to `healthProfileProvider.age` for backwards compatibility.

**Presentation components:**

- `HeartRatePanelController` (StateNotifier) — manages monitoring state, timestamped readings (`HrReading` with `bpm` and `elapsed` duration), elapsed timer, and BLE connection lifecycle. Non-autoDispose so monitoring survives tab switches.
- `HeartRateChart` — real-time fl_chart `LineChart` plotting BPM against elapsed time. Accepts `ZoneConfiguration` for zone band annotations and optional `windowSeconds` for a sliding window view. X-axis shows `M:SS` timestamps with adaptive intervals.
- `HeartRateZoneLegend` — displays 5 training zones with dual labels, BPM ranges, and inline `ReliabilityIndicator`. Highlights the current zone. Shows "Clinician-provided limits in use" when applicable.
- `HealthProfileOnboarding` — 4-step bottom sheet: age → resting HR + measured max → medical flags → clinician cap. Skip/Next/Back navigation. Triggered on first HR panel visit (when age is null) or from Settings.
- `DisclaimerDialog` — first-use disclaimer dialog (shown once via SharedPreferences flag).
- `CautionBadge` — amber warning card shown when `isCautionMode` is true. Text varies by flag (beta blocker, heart condition, or both).
- `ReliabilityIndicator` — colour-coded High (green) / Medium (amber) / Low (red) indicator with tooltip explaining the reasoning.
- `SymptomReportButton` — symptom selection dialog → stop-exercise dialog with urgent-help guidance. Calls `controller.stopMonitoring()` on symptom report.

**Screen layout:** The `HeartRatePanelScreen` shows (top to bottom): caution badge (if applicable), live BPM display with zone label, Start/Pause/Reset controls, recent chart (sliding window with configurable dropdown), full session chart, stats card (avg/min/max/readings), time-in-zone summary bars, symptom report button (during monitoring), and zone legend.

**Controls:** Connect (opens BLE device picker), Start/Pause monitoring, Reset readings, Disconnect. Stats card shows avg/min/max/readings count.

**Settings integration:** The Settings screen has an expanded "Health Profile" section with tiles for: age, resting HR, measured max HR, beta blocker toggle, heart condition toggle, clinician max HR, zone method summary with reliability, "Set Up Heart Rate Zones" wizard link, and general disclaimer text.

Key files: `lib/features/heart_rate/domain/models/health_profile.dart`, `lib/features/heart_rate/domain/zone_calculator.dart`, `lib/features/heart_rate/domain/time_in_zone_calculator.dart`, `lib/features/heart_rate/domain/warning_messages.dart`, `lib/features/heart_rate/presentation/providers/health_profile_provider.dart`, `lib/features/heart_rate/presentation/providers/zone_configuration_provider.dart`, `lib/features/heart_rate/presentation/providers/chart_window_provider.dart`, `lib/features/heart_rate/presentation/screens/heart_rate_panel_screen.dart`, `lib/features/heart_rate/presentation/controllers/heart_rate_panel_controller.dart`, `lib/features/heart_rate/presentation/widgets/heart_rate_chart.dart`, `lib/features/heart_rate/presentation/widgets/heart_rate_zones.dart`, `lib/features/heart_rate/presentation/widgets/health_profile_onboarding.dart`, `lib/features/heart_rate/presentation/widgets/disclaimer_dialog.dart`, `lib/features/heart_rate/presentation/widgets/caution_badge.dart`, `lib/features/heart_rate/presentation/widgets/reliability_indicator.dart`, `lib/features/heart_rate/presentation/widgets/symptom_report_button.dart`, `lib/features/settings/presentation/providers/user_age_provider.dart`

---

## 7. Navigation Architecture

GoRouter is configured with a ShellRoute for the bottom navigation bar (three tabs: Workout, History, Settings) and nested routes for detail screens. Deep links are supported for sharing specific workouts.

| Route | Screen | Notes |
|-------|--------|-------|
| `/workout` | ActiveWorkoutScreen | Main logging screen; start or continue a workout |
| `/exercises` | ExerciseLibraryScreen | Browse and search the exercise library |
| `/cardio` | CardioTrackingScreen | Log cardio sessions |
| `/heart-rate` | HeartRatePanelScreen | Real-time HR monitoring with zone chart |
| `/history` | HistoryListScreen | Past workouts in reverse chronological order |
| `/history/:id` | WorkoutDetailScreen | Full breakdown of a past workout |
| `/history/exercise/:id` | ExerciseProgressScreen | Per-exercise history with charts |
| `/settings` | SettingsScreen | App preferences, data export, theme toggle |
| `/templates` | TemplateListScreen | Manage workout templates |

---

## 8. Offline-First Strategy

The app is designed to work entirely offline. All data is persisted locally via Drift (SQLite). No feature requires network connectivity. This is critical for gym environments with poor connectivity.

When cloud sync is introduced in v2, the strategy will be:

- **Local-first writes:** all data written to SQLite immediately
- **Background sync:** a sync engine periodically pushes local changes to the cloud and pulls remote changes
- **Conflict resolution:** last-write-wins at the row level, with a sync timestamp column on all tables
- **Sync status:** UI indicators for sync state (synced, pending, error) without blocking user interaction

---

## 9. Performance Considerations

### 9.1 Startup Time

The target is sub-2-second cold start on mid-range devices. Key strategies: lazy provider initialisation (only the active workout feature loads on start) and minimal widget tree depth on the home screen. The exercise library loads asynchronously and is searchable once loaded.

### 9.2 Database Performance

For users with years of workout data, query performance is maintained through Drift's foreign-key references (which create implicit indexes) on `workout_id`, `exercise_id`, and similar columns. History pagination uses keyset pagination (`WHERE started_at < lastTimestamp`) rather than OFFSET to avoid degrading performance on large datasets. Drift's query watcher efficiently invalidates only affected streams when data changes.

### 9.3 UI Rendering

List-heavy screens (workout history, exercise list) use `ListView.builder` for lazy rendering. Charts are rendered with fl_chart which uses `CustomPainter` for GPU-accelerated drawing. Animations are limited to 60fps targets with simple curves to avoid jank on older devices.

---

## 10. Testing Strategy

| Level | Scope | Tools |
|-------|-------|-------|
| Unit tests | Domain models, use cases, repository logic (in-memory fakes + Drift in-memory DB), state notifiers | flutter_test, mockito, drift/native (NativeDatabase.memory()), riverpod testing utilities |
| Widget tests | Individual screens and components with mocked providers | flutter_test, WidgetTester |
| Integration tests | Full user flows (start workout → log sets → finish → view history) | flutter_test |

Coverage targets: 80% for domain and application layers, 60% for presentation layer.

---

## 11. CI/CD Pipeline (Planned)

> **Note:** No CI/CD workflows are configured yet. The table below describes the planned pipeline.

GitHub Actions will handle continuous integration. Fastlane will automate store submissions.

| Stage | Actions | Trigger |
|-------|---------|---------|
| Lint + Format | `dart analyze`, `dart format --set-exit-if-changed` | Every PR |
| Unit + Widget Tests | `flutter test` with coverage reporting | Every PR |
| Integration Tests | Run on emulator (Android) and simulator (iOS) | Merge to main |
| Build | `flutter build apk / ipa` with flavour-based config (dev, staging, prod) | Merge to main |
| Deploy (Beta) | Fastlane upload to TestFlight + Play Console internal track | Tag: `beta/*` |
| Deploy (Release) | Fastlane upload to App Store + Play Store production | Tag: `v*` |

---

## 12. Security Considerations

- All user data stored in the app's local storage, protected by OS-level encryption at rest
- No personally identifiable information collected beyond optional email for cloud sync (v2)
- Data export (CSV/JSON) requires user-initiated action; no automatic external transmission
- When cloud sync ships, all API traffic will use TLS 1.3 and authentication via Firebase Auth tokens

---

## 13. Future Architecture Considerations

The following architectural investments are deferred to keep v1 lean but are accounted for in the current structure:

- **Remaining Drift repositories:** CardioSession, PersonalRecord, and WorkoutTemplate repositories need implementing against the existing table definitions.
- **Cloud sync layer:** Repository interfaces are designed so a remote data source can be added behind the same contract without changing the application or presentation layers.
- **Wearable companion:** Live BLE heart rate streaming from Apple Watch and Samsung Galaxy Watch is implemented (via standard BLE HR broadcast). A full native companion app for Wear OS or watchOS (providing workout control, rep logging on wrist, etc.) would require shared domain models extracted into a Dart package with platform channel integration — this remains deferred.
- **Feature flags:** A FeatureFlag provider is planned to support A/B testing and gradual rollout of Pro features.
- **Modularisation:** Features are self-contained directories today. When the codebase grows, each feature can be extracted into a separate Dart package for independent compilation and testing.
