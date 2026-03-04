# RepFoundry — Architecture Document

**Version 1.0 | March 2026**
**Flutter / Dart • Riverpod • Drift • Clean Architecture**

---

## 1. Architecture Overview

RepFoundry follows a clean architecture pattern with clear separation between presentation, domain, and data layers. The app is built with Flutter and Dart, targeting both iOS and Android from a single codebase. The architecture prioritises offline-first operation, fast startup, and testability.

---

## 2. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Framework | Flutter 3.x / Dart 3.x | Cross-platform UI and application framework |
| State Management | Riverpod 2.x | Reactive state management with dependency injection and code generation |
| Local Database | Drift (SQLite) | Type-safe, reactive local persistence with migration support |
| Navigation | GoRouter | Declarative routing with deep link support |
| Dependency Injection | Riverpod (built-in) | Provider-based DI with auto-dispose and scoping |
| Charts | fl_chart | High-performance charting for progress visualisation |
| Testing | flutter_test, mockito, integration_test | Unit, widget, and integration testing |
| CI/CD | GitHub Actions + Fastlane | Automated build, test, and store deployment |
| Analytics / Crash | Firebase Crashlytics + Analytics | Crash reporting and usage analytics |

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
│   │   └── data/             # Repository impls, data sources
│   ├── exercises/            # Exercise library feature
│   ├── history/              # Workout history & progress
│   ├── cardio/               # Cardio tracking feature
│   ├── templates/            # Workout templates
│   └── settings/             # App preferences
├── core/                     # Shared utilities
│   ├── database/             # Drift DB definition, migrations
│   ├── extensions/           # Dart extension methods
│   └── widgets/              # Reusable UI components
└── main.dart
```

---

## 4. Layer Architecture

### 4.1 Presentation Layer

Flutter widgets and screens consume state from Riverpod providers. Screens are thin and delegate all logic to controllers (AsyncNotifier or Notifier classes). No business logic lives in widget build methods.

- **Screens:** full-page widgets mapped to GoRouter routes
- **Widgets:** reusable UI components (SetInputCard, RestTimerWidget, ExercisePicker)
- **Controllers:** Riverpod Notifiers that manage screen-level state and coordinate use cases

### 4.2 Application Layer

Use cases encapsulate single business operations. They are pure Dart classes that depend on repository interfaces (not implementations), making them fully testable without Flutter or database dependencies.

- **LogSetUseCase:** validates input, persists set, updates workout summary
- **StartWorkoutUseCase:** creates workout record, loads template if applicable
- **CalculateProgressUseCase:** computes estimated 1RM, volume trends, PRs

### 4.3 Domain Layer

Pure Dart models with no framework dependencies. These are immutable data classes generated with freezed for value equality, copyWith, and JSON serialisation.

| Model | Key Fields | Notes |
|-------|-----------|-------|
| Workout | id, startedAt, completedAt, templateId?, notes | Top-level container for a session |
| WorkoutSet | id, workoutId, exerciseId, setOrder, weight, reps, rpe?, timestamp | Single set within a workout |
| Exercise | id, name, category, muscleGroup, equipmentType, isCustom | Exercise definitions |
| CardioSession | id, workoutId, exerciseId, duration, distance?, incline?, heartRate? | Cardio entry within a workout |
| WorkoutTemplate | id, name, exerciseIds, setSchemas | Reusable workout blueprint |
| PersonalRecord | id, exerciseId, recordType, value, achievedAt | Tracked PRs (1RM, max reps, etc.) |

### 4.4 Data Layer

Repository implementations backed by Drift (SQLite). Each repository implements a domain-layer interface and converts between Drift data classes and domain models. Drift provides type-safe SQL queries, reactive streams via watchable queries, and schema migrations.

Key data design decisions:

- All timestamps stored as UTC epoch milliseconds for consistency and sort performance
- Soft deletes on workouts and exercises (`deletedAt` column) to support undo and data recovery
- Indexes on `workoutId`, `exerciseId`, and `timestamp` columns for fast history queries
- Schema versioning with Drift migrations; each version bump has an explicit migration step

---

## 5. Database Schema

The SQLite database uses the following core tables. Drift generates type-safe accessors from these definitions.

| Table | Columns | Relationships |
|-------|---------|---------------|
| workouts | id (PK), started_at, completed_at, template_id (FK?), notes, deleted_at | Has many workout_sets, cardio_sessions |
| workout_sets | id (PK), workout_id (FK), exercise_id (FK), set_order, weight, reps, rpe, timestamp | Belongs to workout and exercise |
| exercises | id (PK), name, category, muscle_group, equipment_type, is_custom, deleted_at | Has many workout_sets |
| cardio_sessions | id (PK), workout_id (FK), exercise_id (FK), duration_sec, distance_m, incline, avg_hr | Belongs to workout |
| workout_templates | id (PK), name, created_at, updated_at | Has many template_exercises |
| template_exercises | id (PK), template_id (FK), exercise_id (FK), target_sets, target_reps, order_index | Belongs to template and exercise |
| personal_records | id (PK), exercise_id (FK), record_type, value, achieved_at, workout_set_id (FK) | Belongs to exercise |

---

## 6. State Management

Riverpod is used throughout for reactive state management. The provider tree follows a clear hierarchy.

### 6.1 Provider Types

- **Provider:** static dependencies (database instance, repositories)
- **FutureProvider:** one-shot async data (exercise library load, single workout fetch)
- **StreamProvider:** reactive data (workout history list, active workout sets — powered by Drift watch queries)
- **NotifierProvider:** mutable UI state (active workout controller, rest timer, exercise search filter)

### 6.2 Active Workout State Flow

The most complex state in the app is the active workout. When a user starts a workout, an `ActiveWorkoutNotifier` is created that holds the in-progress workout, its sets, and the rest timer state. Sets are persisted to the database immediately on entry (not batched at the end) so that data is never lost if the app is killed.

The flow is:

1. User taps **Start Workout**
2. `ActiveWorkoutNotifier` creates a `Workout` row in the DB
3. User adds sets (each persisted immediately)
4. Rest timer runs between sets
5. User taps **Finish**
6. Notifier marks workout as completed
7. PR detection runs asynchronously
8. History providers auto-refresh via Drift streams

---

## 7. Navigation Architecture

GoRouter is configured with a ShellRoute for the bottom navigation bar (three tabs: Workout, History, Settings) and nested routes for detail screens. Deep links are supported for sharing specific workouts.

| Route | Screen | Notes |
|-------|--------|-------|
| `/workout` | ActiveWorkoutScreen | Main logging screen; start or continue a workout |
| `/workout/exercise/:id` | ExerciseDetailScreen | Log sets for a specific exercise |
| `/history` | HistoryListScreen | Past workouts in reverse chronological order |
| `/history/:id` | WorkoutDetailScreen | Full breakdown of a past workout |
| `/history/exercise/:id` | ExerciseProgressScreen | Per-exercise history with charts |
| `/settings` | SettingsScreen | App preferences, data export, theme toggle |
| `/templates` | TemplateListScreen | Manage workout templates |

---

## 8. Offline-First Strategy

The app is designed to work entirely offline. SQLite is the single source of truth, and no feature requires network connectivity. This is critical for gym environments with poor connectivity.

When cloud sync is introduced in v2, the strategy will be:

- **Local-first writes:** all data written to SQLite immediately
- **Background sync:** a sync engine periodically pushes local changes to the cloud and pulls remote changes
- **Conflict resolution:** last-write-wins at the row level, with a sync timestamp column on all tables
- **Sync status:** UI indicators for sync state (synced, pending, error) without blocking user interaction

---

## 9. Performance Considerations

### 9.1 Startup Time

The target is sub-2-second cold start on mid-range devices. Key strategies: lazy provider initialisation (only the active workout feature loads on start), pre-compiled Drift query cache, and minimal widget tree depth on the home screen. The exercise library loads asynchronously and is searchable once loaded.

### 9.2 Database Performance

For users with years of workout data, query performance is maintained through composite indexes on `(exercise_id, timestamp)` and `(workout_id, set_order)`. History pagination uses keyset pagination (`WHERE timestamp < lastTimestamp`) rather than OFFSET to avoid degrading performance on large datasets. Drift's query watcher efficiently invalidates only affected streams when data changes.

### 9.3 UI Rendering

List-heavy screens (workout history, exercise list) use `ListView.builder` for lazy rendering. Charts are rendered with fl_chart which uses `CustomPainter` for GPU-accelerated drawing. Animations are limited to 60fps targets with simple curves to avoid jank on older devices.

---

## 10. Testing Strategy

| Level | Scope | Tools |
|-------|-------|-------|
| Unit tests | Domain models, use cases, repository logic, state notifiers | flutter_test, mockito, riverpod testing utilities |
| Widget tests | Individual screens and components with mocked providers | flutter_test, WidgetTester |
| Integration tests | Full user flows (start workout → log sets → finish → view history) | integration_test, patrol |
| Database tests | Schema migrations, query correctness, edge cases | Drift testing with in-memory SQLite |

Coverage targets: 80% for domain and application layers, 60% for presentation layer, 100% for database migrations.

---

## 11. CI/CD Pipeline

GitHub Actions handles continuous integration. Fastlane automates store submissions.

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

- All user data stored in the app's sandboxed SQLite database, protected by OS-level encryption at rest
- No personally identifiable information collected beyond optional email for cloud sync (v2)
- Data export (CSV/JSON) requires user-initiated action; no automatic external transmission
- Firebase Analytics collects only anonymised usage events; no workout content is sent
- When cloud sync ships, all API traffic will use TLS 1.3 and authentication via Firebase Auth tokens

---

## 13. Future Architecture Considerations

The following architectural investments are deferred to keep v1 lean but are accounted for in the current structure:

- **Cloud sync layer:** Repository interfaces are designed so a remote data source can be added behind the same contract without changing the application or presentation layers.
- **Wearable companion:** Shared domain models will be extracted into a Dart package consumable by a Wear OS (Kotlin) or watchOS (Swift) companion app, with data sync via platform channels.
- **Feature flags:** A simple FeatureFlag provider is included from day one to support A/B testing and gradual rollout of Pro features.
- **Modularisation:** Features are self-contained directories today. When the codebase grows, each feature can be extracted into a separate Dart package for independent compilation and testing.
