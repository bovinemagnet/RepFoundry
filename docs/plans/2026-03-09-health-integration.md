# Health Integration (3.4) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate with Apple HealthKit and Android Health Connect to write workouts, heart rate, and body weight, and read body weight from platform health stores.

**Architecture:** New `health_sync` feature directory with a `HealthSyncService` wrapping the `health` Flutter package. Settings toggles (SharedPreferences-backed StateNotifier) control which data types sync. Hook into existing workout completion and body metric save flows.

**Tech Stack:** Flutter/Dart, `health` package, Riverpod, SharedPreferences, l10n via ARB

---

## Task 1: Add dependency and platform configuration

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/build.gradle`

**Step 1: Add health dependency**

In `pubspec.yaml`, add under dependencies:
```yaml
  health: ^11.1.0
```

Run: `flutter pub get`

**Step 2: Android Health Connect configuration**

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>` (before `<application>`):
```xml
<!-- Health Connect -->
<uses-permission android:name="android.permission.health.READ_WEIGHT" />
<uses-permission android:name="android.permission.health.WRITE_WEIGHT" />
<uses-permission android:name="android.permission.health.READ_BODY_FAT" />
<uses-permission android:name="android.permission.health.WRITE_BODY_FAT" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.WRITE_HEART_RATE" />
<uses-permission android:name="android.permission.health.WRITE_EXERCISE" />
<uses-permission android:name="android.permission.health.READ_EXERCISE" />
```

Inside `<application>`, add the Health Connect intent filter:
```xml
<activity
    android:name="androidx.health.connect.client.permission.HealthPermissionRequestActivity"
    android:exported="true">
  <intent-filter>
    <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
  </intent-filter>
</activity>
```

**Step 3: iOS HealthKit configuration**

In `ios/Runner/Info.plist`, add:
```xml
<key>NSHealthShareUsageDescription</key>
<string>RepFoundry reads body weight from Apple Health to keep your metrics in sync.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>RepFoundry writes workouts and body metrics to Apple Health for a complete fitness picture.</string>
```

Note: HealthKit capability must be enabled in Xcode (Runner → Signing & Capabilities → + HealthKit). This is a manual step.

**Step 4: Verify**

Run: `flutter pub get && dart analyze`

**Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock android/ ios/
git commit -m "feat: add health package dependency and platform permissions for HealthKit/Health Connect"
```

---

## Task 2: HealthSyncService

**Files:**
- Create: `lib/features/health_sync/data/health_sync_service.dart`
- Create: `test/features/health_sync/data/health_sync_service_test.dart`

**Step 1: Create the service**

```dart
// lib/features/health_sync/data/health_sync_service.dart
import 'package:health/health.dart';

class HealthSyncService {
  final Health _health = Health();
  bool _isAuthorised = false;

  /// Request permissions for the given health data types.
  Future<bool> requestAuthorisation({
    bool writeWorkouts = true,
    bool writeWeight = true,
    bool writeHeartRate = true,
    bool readWeight = true,
  }) async {
    final types = <HealthDataType>[];
    final permissions = <HealthDataAccess>[];

    if (writeWorkouts) {
      types.add(HealthDataType.WORKOUT);
      permissions.add(HealthDataAccess.WRITE);
    }
    if (writeWeight) {
      types.add(HealthDataType.WEIGHT);
      permissions.add(HealthDataAccess.READ_WRITE);
    }
    if (writeHeartRate) {
      types.add(HealthDataType.HEART_RATE);
      permissions.add(HealthDataAccess.WRITE);
    }
    if (readWeight) {
      if (!types.contains(HealthDataType.WEIGHT)) {
        types.add(HealthDataType.WEIGHT);
        permissions.add(HealthDataAccess.READ);
      }
    }

    if (types.isEmpty) return true;

    _isAuthorised = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    return _isAuthorised;
  }

  /// Write a strength or cardio workout session.
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required int totalCalories,
    bool isCardio = false,
  }) async {
    return _health.writeWorkoutData(
      activityType: isCardio
          ? HealthWorkoutActivityType.RUNNING
          : HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING,
      start: startTime,
      end: endTime,
      totalEnergyBurned: totalCalories,
      totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
    );
  }

  /// Write body weight in kg.
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime dateTime,
  }) async {
    return _health.writeHealthData(
      value: weightKg,
      type: HealthDataType.WEIGHT,
      startTime: dateTime,
      endTime: dateTime,
      unit: HealthDataUnit.KILOGRAM,
    );
  }

  /// Write body fat percentage.
  Future<bool> writeBodyFat({
    required double percent,
    required DateTime dateTime,
  }) async {
    return _health.writeHealthData(
      value: percent,
      type: HealthDataType.BODY_FAT_PERCENTAGE,
      startTime: dateTime,
      endTime: dateTime,
      unit: HealthDataUnit.PERCENT,
    );
  }

  /// Write heart rate samples.
  Future<bool> writeHeartRate({
    required int bpm,
    required DateTime dateTime,
  }) async {
    return _health.writeHealthData(
      value: bpm.toDouble(),
      type: HealthDataType.HEART_RATE,
      startTime: dateTime,
      endTime: dateTime,
      unit: HealthDataUnit.BEATS_PER_MINUTE,
    );
  }

  /// Read latest body weight from health store.
  Future<double?> readLatestWeight() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.WEIGHT],
      startTime: thirtyDaysAgo,
      endTime: now,
    );

    if (data.isEmpty) return null;

    // Sort by date descending, return most recent
    data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
    final latest = data.first;
    if (latest.value is NumericHealthValue) {
      return (latest.value as NumericHealthValue).numericValue.toDouble();
    }
    return null;
  }

  bool get isAuthorised => _isAuthorised;
}
```

**Step 2: Write a basic test for the calorie estimation helper**

Since the Health API requires a real device, tests will focus on any pure logic. For now, create a placeholder test file with a simple calculation test.

**Step 3: Commit**

```bash
git add lib/features/health_sync/ test/features/health_sync/
git commit -m "feat: add HealthSyncService wrapping health package"
```

---

## Task 3: Health sync settings provider

**Files:**
- Create: `lib/features/health_sync/presentation/providers/health_sync_settings_provider.dart`
- Create: `test/features/health_sync/presentation/providers/health_sync_settings_test.dart`

**Step 1: Create settings model and provider**

Follow the pattern from `rest_timer_settings_provider.dart`:
- `HealthSyncSettings` class with fields: `enabled`, `writeWorkouts`, `writeWeight`, `writeHeartRate`, `readWeight`
- `HealthSyncSettingsNotifier` extends `StateNotifier<HealthSyncSettings>`
- Backed by SharedPreferences with keys `health_sync_*`
- Methods: `toggleEnabled()`, `toggleWriteWorkouts()`, `toggleWriteWeight()`, `toggleWriteHeartRate()`, `toggleReadWeight()`

**Step 2: Write tests for default values and toggle logic**

**Step 3: Commit**

```bash
git add lib/features/health_sync/ test/features/health_sync/
git commit -m "feat: add health sync settings provider with SharedPreferences persistence"
```

---

## Task 4: Write workout data on completion

**Files:**
- Modify: `lib/features/workout/presentation/controllers/active_workout_controller.dart`
- Modify: `lib/features/cardio/application/save_cardio_session_use_case.dart`
- Create: `lib/features/health_sync/application/sync_workout_use_case.dart`

**Step 1: Create sync use case**

Pure Dart use case that takes workout data and writes to HealthSyncService:
- Accepts: startTime, endTime, totalVolume, isCardio, exerciseCount
- Estimates calories: strength = 0.05 * totalVolume (rough MET-based estimate), cardio = durationMinutes * 8 (moderate cardio MET)
- Calls `healthSyncService.writeWorkout(...)`

**Step 2: Hook into finishWorkout()**

In `ActiveWorkoutController.finishWorkout()`, after persisting the workout:
- Check if health sync is enabled via provider
- If enabled, calculate total volume from sets, call sync use case

**Step 3: Hook into cardio save**

In `SaveCardioSessionUseCase.execute()` or at the controller level:
- After saving cardio session, sync if enabled

**Step 4: Verify**

Run: `dart analyze && flutter test`

**Step 5: Commit**

```bash
git add lib/features/health_sync/ lib/features/workout/ lib/features/cardio/
git commit -m "feat: write workout data to Apple Health / Health Connect on completion"
```

---

## Task 5: Write body weight on save

**Files:**
- Modify: `lib/features/body_metrics/presentation/screens/body_metrics_screen.dart` (or equivalent save flow)

**Step 1: Find the body metric save point**

Read the body metrics screen/controller to find where `BodyMetric` is persisted.

**Step 2: Hook health sync**

After saving a body metric:
- Check if health sync enabled + writeWeight enabled
- Write weight via `healthSyncService.writeWeight()`
- If bodyFatPercent is set, also write body fat

**Step 3: Verify**

Run: `dart analyze && flutter test`

**Step 4: Commit**

```bash
git add lib/features/body_metrics/ lib/features/health_sync/
git commit -m "feat: write body weight and body fat to health store on save"
```

---

## Task 6: Read body weight from health store

**Files:**
- Create: `lib/features/health_sync/application/read_health_weight_use_case.dart`
- Modify: `lib/main.dart` (or appropriate startup hook)

**Step 1: Create read use case**

- Calls `healthSyncService.readLatestWeight()`
- Returns the weight if found and different from the latest body metric entry
- Returns null if no new data or sync disabled

**Step 2: Add import flow on app open**

In main.dart or via a provider that runs on startup:
- If health sync + readWeight enabled
- Read latest weight
- If newer than latest body metric, show snackbar or dialog offering to import

Keep it simple: just a snackbar with "Import X kg from Health?" and an action button.

**Step 3: Verify**

Run: `dart analyze && flutter test`

**Step 4: Commit**

```bash
git add lib/features/health_sync/ lib/main.dart
git commit -m "feat: read body weight from health store on app open"
```

---

## Task 7: Settings UI

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

**Step 1: Add Health Sync section**

Between existing sections, add a "Health Sync" section with:
- Master toggle: `SwitchListTile` for enabled/disabled (icon: `Icons.favorite`)
- When enabled, show sub-toggles:
  - Write workouts (`Icons.fitness_center`)
  - Write body weight (`Icons.monitor_weight`)
  - Write heart rate (`Icons.monitor_heart`)
  - Read body weight (`Icons.download`)
- When master toggle turned on for the first time, trigger `healthSyncService.requestAuthorisation()`

**Step 2: Register providers**

In `lib/core/providers.dart`, add:
- `healthSyncServiceProvider` — singleton `HealthSyncService`
- `healthSyncSettingsProvider` — the StateNotifierProvider

**Step 3: Verify**

Run: `dart analyze && flutter test`

**Step 4: Commit**

```bash
git add lib/features/settings/ lib/core/providers.dart
git commit -m "feat: add Health Sync settings UI with per-data-type toggles"
```

---

## Task 8: l10n strings

**Files:**
- Modify: `lib/l10n/app_en.arb`

**Step 1: Add strings**

```json
  "healthSyncTitle": "Health Sync",
  "healthSyncSubtitle": "Sync data with Apple Health or Health Connect",
  "healthSyncEnabled": "Enable Health Sync",
  "writeWorkoutsLabel": "Write workouts",
  "writeWorkoutsSubtitle": "Log completed workouts to the health store",
  "writeWeightLabel": "Write body weight",
  "writeWeightSubtitle": "Send body metrics to the health store",
  "writeHeartRateLabel": "Write heart rate",
  "writeHeartRateSubtitle": "Send heart rate data during cardio",
  "readWeightLabel": "Read body weight",
  "readWeightSubtitle": "Import weight measurements from the health store",
  "healthSyncPermissionDenied": "Health permissions were not granted",
  "healthSyncSuccess": "Synced to Health",
  "importWeightPrompt": "Import {weight} kg from Health?",
  "importWeightAction": "Import",
  "healthSyncNoNewData": "No new data from Health"
```

**Step 2: Regenerate l10n**

Run: `flutter gen-l10n`

**Step 3: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add health sync l10n strings"
```

---

## Task 9: Final verification

**Step 1:** Run `flutter test` — all tests pass
**Step 2:** Run `dart analyze` — 0 errors
**Step 3:** Run `flutter gen-l10n` — success

---

## Notes

- The `health` package requires real device testing — HealthKit/Health Connect APIs are not available in simulators/emulators
- iOS requires the HealthKit capability to be manually enabled in Xcode
- Android requires Health Connect app to be installed on the device
- Calorie estimation is intentionally rough — users who want precise calorie data should use a dedicated tracker
