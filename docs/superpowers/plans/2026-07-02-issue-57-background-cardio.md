# Background Cardio Tracking (Issue 57) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cardio sessions survive phone lock: elapsed time/pace are wall-clock correct after suspension, and GPS + BLE HR keep recording in the background with the platform-required notification/indicator.

**Architecture:** Replace tick-counted `elapsedSeconds` with wall-clock diffing (`clock.now()` against a `runningSince` anchor plus an accumulated-pause duration) in both the cardio and HR-panel controllers. Add a `ForegroundSessionService` abstraction (cardio data layer) whose Android implementation runs a `flutter_foreground_task` foreground service (types `location`/`connectedDevice`) while a session is running; iOS gets `UIBackgroundModes` (location, bluetooth-central) and a background-capable geolocator subscription instead.

**Tech Stack:** Flutter/Dart, Riverpod `Notifier`, `package:clock` + `package:fake_async` (timer testability), `flutter_foreground_task` ^9.2.2, `geolocator` ^14 (`AppleSettings`/`AndroidSettings`).

## Global Constraints

- British spelling in comments and docs.
- `dart analyze` must report zero issues; `dart format` clean.
- Lints: `always_declare_return_types`, `prefer_const_constructors`, `prefer_final_fields`, `prefer_final_locals`.
- Existing pattern: data-layer service notification strings are hardcoded (see `lib/features/notifications/data/notification_service.dart`); do NOT add ARB entries for the foreground-service notification.
- Sync/background services are best-effort: swallow errors, never block user actions.
- No Claude/Anthropic mentions and no co-author lines in commit messages.
- Do not regress the foreground cardio flow (all existing tests keep passing).

---

### Task 1: Wall-clock elapsed time in CardioTrackingController

**Files:**
- Modify: `lib/features/cardio/presentation/controllers/cardio_tracking_controller.dart`
- Modify: `pubspec.yaml` (add `clock` dependency, `fake_async` dev dependency)
- Test: `test/features/cardio/presentation/controllers/cardio_tracking_controller_test.dart`

**Interfaces:**
- Consumes: existing `CardioTrackingState.elapsedSeconds` (int, unchanged shape).
- Produces: `CardioTrackingController` fields `DateTime? _runningSince`, `Duration _accumulated`; ticks/pause/save all derive elapsed via `clock.now()`. Task 3 modifies the same controller.

- [ ] **Step 1: Add dependencies**

In `pubspec.yaml` under `dependencies:` add `clock: ^1.1.2`; under `dev_dependencies:` add `fake_async: ^1.3.3`. Run `flutter pub get`.

- [ ] **Step 2: Write the failing tests**

Add to the `timer state transitions` group in `cardio_tracking_controller_test.dart` (import `package:clock/clock.dart` not needed in test; import `package:fake_async/fake_async.dart`):

```dart
test('elapsed time follows the wall clock, not tick count', () {
  fakeAsync((async) {
    controller.start();
    async.elapse(const Duration(seconds: 5));
    expect(controller.state.elapsedSeconds, 5);

    // Simulate OS suspension: wall time passes but no timer ticks fire.
    async.elapseBlocking(const Duration(minutes: 10));
    // First tick after resume corrects the display from the wall clock.
    async.elapse(const Duration(seconds: 1));
    expect(controller.state.elapsedSeconds, 5 + 600 + 1);
    controller.reset();
  });
});

test('pause() freezes elapsed and resume accumulates correctly', () {
  fakeAsync((async) {
    controller.start();
    async.elapse(const Duration(seconds: 10));
    controller.pause();
    // Time passing while paused must not count.
    async.elapse(const Duration(minutes: 5));
    expect(controller.state.elapsedSeconds, 10);

    controller.start();
    async.elapse(const Duration(seconds: 20));
    expect(controller.state.elapsedSeconds, 30);
    controller.reset();
  });
});

test('reset() zeroes the wall-clock accumulator', () {
  fakeAsync((async) {
    controller.start();
    async.elapse(const Duration(seconds: 30));
    controller.reset();
    controller.start();
    async.elapse(const Duration(seconds: 3));
    expect(controller.state.elapsedSeconds, 3);
    controller.reset();
  });
});

test('save() persists wall-clock duration even without a recent tick',
    () async {
  await controller.selectExercise('e1', 'Treadmill');
  late Future<void> saveFuture;
  fakeAsync((async) {
    controller.start();
    async.elapse(const Duration(seconds: 5));
    // Suspension right before save: no tick fires for these 10 minutes.
    async.elapseBlocking(const Duration(minutes: 10));
    saveFuture = controller.save(distanceMeters: 1000);
    async.flushMicrotasks();
  });
  await saveFuture;
  final sessions = await cardioRepo.getSessionsForExercise('e1');
  expect(sessions.single.durationSeconds, 605);
});
```

Check `InMemoryCardioSessionRepository` for the fetch method name (`getSessionsForExercise` or similar — mirror what the existing `save()` tests in this file use to read back the saved session, and reuse their approach).

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/cardio/presentation/controllers/cardio_tracking_controller_test.dart`
Expected: the four new tests FAIL (elapsed stays at tick count, e.g. 6 instead of 606); all pre-existing tests still pass.

- [ ] **Step 4: Implement wall-clock elapsed in the controller**

In `cardio_tracking_controller.dart` add `import 'package:clock/clock.dart';` and fields + helper:

```dart
  DateTime? _runningSince;
  Duration _accumulated = Duration.zero;

  int get _wallClockElapsedSeconds {
    final running = _runningSince;
    final live = running == null
        ? Duration.zero
        : clock.now().difference(running);
    return (_accumulated + live).inSeconds;
  }
```

Replace the timer in `start()` (elapsed is derived from the wall clock so a
missed tick during OS suspension self-corrects on the next one):

```dart
    _runningSince = clock.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: _wallClockElapsedSeconds);
    });
```

In `pause()` accumulate and clear the anchor (before `state = ...`):

```dart
    if (_runningSince != null) {
      _accumulated += clock.now().difference(_runningSince!);
      _runningSince = null;
    }
    state = state.copyWith(isRunning: false, elapsedSeconds: _wallClockElapsedSeconds);
```

In `reset()` zero both: `_runningSince = null; _accumulated = Duration.zero;`

In `save()`, before the `if (... elapsedSeconds <= 0) return;` guard, refresh elapsed so suspension immediately before save cannot truncate the session:

```dart
    if (state.isRunning || _accumulated > Duration.zero) {
      state = state.copyWith(elapsedSeconds: _wallClockElapsedSeconds);
    }
```

and in the success branch (after `_stopGpsTracking()`), also zero `_runningSince`/`_accumulated`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/cardio/presentation/controllers/cardio_tracking_controller_test.dart`
Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/cardio/presentation/controllers/cardio_tracking_controller.dart test/features/cardio/presentation/controllers/cardio_tracking_controller_test.dart
git commit -m "fix: derive cardio elapsed time from the wall clock"
```

---

### Task 2: Wall-clock elapsed time in HeartRatePanelController

**Files:**
- Modify: `lib/features/heart_rate/presentation/controllers/heart_rate_panel_controller.dart`
- Test: `test/features/heart_rate/presentation/controllers/heart_rate_panel_controller_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1 (same pattern, independent file).
- Produces: no API change; `HeartRatePanelState.elapsedSeconds` now wall-clock derived.

- [ ] **Step 1: Write the failing tests**

Mirror the existing test file's container setup; add:

```dart
test('elapsed time follows the wall clock across suspension', () {
  fakeAsync((async) {
    controller.startMonitoring();
    async.elapse(const Duration(seconds: 5));
    expect(controller.state.elapsedSeconds, 5);
    async.elapseBlocking(const Duration(minutes: 10));
    async.elapse(const Duration(seconds: 1));
    expect(controller.state.elapsedSeconds, 606);
    controller.stopMonitoring();
  });
});

test('stopMonitoring() freezes elapsed; restart accumulates', () {
  fakeAsync((async) {
    controller.startMonitoring();
    async.elapse(const Duration(seconds: 10));
    controller.stopMonitoring();
    async.elapse(const Duration(minutes: 2));
    expect(controller.state.elapsedSeconds, 10);
    controller.startMonitoring();
    async.elapse(const Duration(seconds: 5));
    expect(controller.state.elapsedSeconds, 15);
    controller.stopMonitoring();
  });
});

test('resetReadings() zeroes the wall-clock accumulator', () {
  fakeAsync((async) {
    controller.startMonitoring();
    async.elapse(const Duration(seconds: 30));
    controller.stopMonitoring();
    controller.resetReadings();
    controller.startMonitoring();
    async.elapse(const Duration(seconds: 3));
    expect(controller.state.elapsedSeconds, 3);
    controller.stopMonitoring();
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/heart_rate/presentation/controllers/heart_rate_panel_controller_test.dart`
Expected: new tests FAIL (606 vs 6); existing tests pass.

- [ ] **Step 3: Implement**

Same pattern as Task 1 in `heart_rate_panel_controller.dart`: add `import 'package:clock/clock.dart';`, fields `_monitoringSince`/`_accumulated`, getter `_wallClockElapsedSeconds`, set anchor in `startMonitoring()` with the tick assigning `elapsedSeconds: _wallClockElapsedSeconds`, accumulate + refresh state in `stopMonitoring()`, zero both in `resetReadings()` and `disconnectHeartRate()`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/heart_rate/presentation/controllers/heart_rate_panel_controller_test.dart`
Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/heart_rate/presentation/controllers/heart_rate_panel_controller.dart test/features/heart_rate/presentation/controllers/heart_rate_panel_controller_test.dart
git commit -m "fix: derive heart-rate panel elapsed time from the wall clock"
```

---

### Task 3: ForegroundSessionService abstraction + controller integration

**Files:**
- Create: `lib/features/cardio/data/foreground_session_service.dart`
- Modify: `lib/core/providers.dart` (new provider)
- Modify: `lib/features/cardio/presentation/controllers/cardio_tracking_controller.dart`
- Modify: `pubspec.yaml` (add `flutter_foreground_task: ^9.2.2`)
- Create: `test/features/cardio/data/fake_foreground_session_service.dart`
- Test: `test/features/cardio/presentation/controllers/cardio_tracking_controller_test.dart`

**Interfaces:**
- Produces:
  ```dart
  abstract class ForegroundSessionService {
    /// Reconcile the platform foreground service with the session state.
    Future<void> update({
      required bool sessionRunning,
      required bool gpsEnabled,
      required bool hrConnected,
    });
  }
  ```
  and `final foregroundSessionServiceProvider = Provider<ForegroundSessionService>(...)` in `core/providers.dart`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/cardio/data/fake_foreground_session_service.dart`:

```dart
import 'package:rep_foundry/features/cardio/data/foreground_session_service.dart';

class FakeForegroundSessionService implements ForegroundSessionService {
  final List<({bool sessionRunning, bool gpsEnabled, bool hrConnected})>
      updates = [];

  ({bool sessionRunning, bool gpsEnabled, bool hrConnected})? get last =>
      updates.isEmpty ? null : updates.last;

  @override
  Future<void> update({
    required bool sessionRunning,
    required bool gpsEnabled,
    required bool hrConnected,
  }) async {
    updates.add((
      sessionRunning: sessionRunning,
      gpsEnabled: gpsEnabled,
      hrConnected: hrConnected,
    ));
  }
}
```

In `cardio_tracking_controller_test.dart`: instantiate a `FakeForegroundSessionService`, add `foregroundSessionServiceProvider.overrideWithValue(foregroundService)` to the container overrides, and add a new group:

```dart
group('foreground session service', () {
  test('start() activates the service with current capabilities', () {
    fakeAsync((async) {
      controller.start();
      async.flushMicrotasks();
      expect(foregroundService.last,
          (sessionRunning: true, gpsEnabled: false, hrConnected: false));
      controller.reset();
    });
  });

  test('pause() and reset() deactivate the service', () {
    fakeAsync((async) {
      controller.start();
      controller.pause();
      async.flushMicrotasks();
      expect(foregroundService.last?.sessionRunning, isFalse);
      controller.start();
      controller.reset();
      async.flushMicrotasks();
      expect(foregroundService.last?.sessionRunning, isFalse);
    });
  });

  test('toggleGps() while running updates the service capabilities',
      () async {
    controller.start();
    await controller.toggleGps();
    expect(foregroundService.last,
        (sessionRunning: true, gpsEnabled: true, hrConnected: false));
    controller.reset();
  });

  test('save() deactivates the service', () async {
    await controller.selectExercise('e1', 'Treadmill');
    controller.start();
    await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
    await controller.save(distanceMeters: 500);
    expect(foregroundService.last?.sessionRunning, isFalse);
  });
});
```

(For the `save()` test, follow whatever the existing save tests do to get a non-zero elapsed time — reuse their mechanism rather than a real delay if they have one.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/cardio/presentation/controllers/cardio_tracking_controller_test.dart`
Expected: new group FAILS (`foregroundSessionServiceProvider` undefined → compile error first; after creating the interface/provider skeleton, `last` is null).

- [ ] **Step 3: Add dependency and implement**

`pubspec.yaml` dependencies: `flutter_foreground_task: ^9.2.2`, then `flutter pub get`.

Create `lib/features/cardio/data/foreground_session_service.dart`:

```dart
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process alive on Android while a cardio session is
/// running so GPS and BLE heart-rate streams survive the phone being
/// locked. iOS background execution is handled by UIBackgroundModes and
/// the background-capable location subscription instead.
abstract class ForegroundSessionService {
  /// Reconcile the platform foreground service with the session state.
  Future<void> update({
    required bool sessionRunning,
    required bool gpsEnabled,
    required bool hrConnected,
  });
}

class FlutterForegroundSessionService implements ForegroundSessionService {
  bool _initialised = false;
  bool _running = false;
  bool _gps = false;
  bool _hr = false;

  void _init() {
    if (_initialised) return;
    _initialised = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'cardio_tracking',
        channelName: 'Cardio tracking',
        channelDescription:
            'Shown while RepFoundry is tracking a cardio session.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
  }

  @override
  Future<void> update({
    required bool sessionRunning,
    required bool gpsEnabled,
    required bool hrConnected,
  }) async {
    if (!Platform.isAndroid) return;
    // Android 14+ requires a permitted service type; without GPS or HR
    // there is nothing to keep alive (the timer is wall-clock based).
    final wantsService = sessionRunning && (gpsEnabled || hrConnected);
    try {
      if (!wantsService) {
        if (_running) {
          _running = false;
          await FlutterForegroundTask.stopService();
        }
        return;
      }
      final typesChanged = gpsEnabled != _gps || hrConnected != _hr;
      if (_running && !typesChanged) return;
      _init();
      if (_running && typesChanged) {
        await FlutterForegroundTask.stopService();
      }
      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      await FlutterForegroundTask.startService(
        serviceId: 257,
        serviceTypes: [
          if (gpsEnabled) ForegroundServiceTypes.location,
          if (hrConnected) ForegroundServiceTypes.connectedDevice,
        ],
        notificationTitle: 'RepFoundry is tracking your workout',
        notificationText: 'Cardio session in progress',
      );
      _running = true;
      _gps = gpsEnabled;
      _hr = hrConnected;
    } on Exception {
      // Best-effort: background tracking must never break the session.
    }
  }
}
```

(Verify the exact names `ForegroundTaskEventAction.nothing()`, `ForegroundServiceTypes.location`, `ForegroundServiceTypes.connectedDevice`, and `checkNotificationPermission` against the installed package source with `dart analyze` / package docs; adjust if the 9.2.2 API differs.)

In `core/providers.dart` (next to `locationServiceProvider`):

```dart
final foregroundSessionServiceProvider = Provider<ForegroundSessionService>(
  (ref) => FlutterForegroundSessionService(),
);
```

In `CardioTrackingController` add getter + sync helper and call sites:

```dart
  ForegroundSessionService get _foregroundService =>
      ref.read(foregroundSessionServiceProvider);

  void _syncForegroundService() {
    unawaited(_foregroundService.update(
      sessionRunning: state.isRunning,
      gpsEnabled: state.gpsEnabled,
      hrConnected: state.hrConnected,
    ));
  }
```

Call `_syncForegroundService()` at the end of `start()`, `pause()`, `reset()`, `toggleGps()` (both branches), `connectHeartRate()` (success path), `disconnectHeartRate()`, and in `save()`'s success branch (after state is cleared). Also call it from `build()`'s `ref.onDispose` — no: dispose only cancels; instead leave dispose as-is (provider is non-autoDispose and lives for the app).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/cardio/presentation/controllers/cardio_tracking_controller_test.dart && flutter test test/features/cardio/`
Expected: ALL PASS (screen tests unaffected: real impl is a no-op off-Android).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/cardio/data/foreground_session_service.dart lib/core/providers.dart lib/features/cardio/presentation/controllers/cardio_tracking_controller.dart test/features/cardio/
git commit -m "feat: keep cardio GPS/HR tracking alive with an Android foreground service"
```

---

### Task 4: Android manifest — permissions and service declaration

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `com.pravera.flutter_foreground_task.service.ForegroundService` from the Task 3 dependency.

- [ ] **Step 1: Add permissions and service**

After the existing location permissions (line ~4) add:

```xml
    <!-- Foreground service for background cardio tracking (GPS + BLE HR) -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
```

Inside `<application>` (after the flutterEmbedding meta-data):

```xml
        <!-- Cardio session tracking service (flutter_foreground_task).
             Warning: do not change the service name. -->
        <service
            android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
            android:foregroundServiceType="location|connectedDevice"
            android:exported="false"
            android:stopWithTask="true" />
```

- [ ] **Step 2: Verify the Android build**

Run: `flutter build apk --debug --flavor dev`
Expected: BUILD SUCCESSFUL (manifest merge + plugin Kotlin compile OK). If the flavour flag is rejected, check `android/app/build.gradle` for the exact flavour names.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat: declare foreground service and permissions for cardio tracking"
```

---

### Task 5: iOS background modes + background-capable location stream

**Files:**
- Modify: `ios/Runner/Info.plist`
- Modify: `lib/features/cardio/data/location_service.dart`

**Interfaces:**
- Consumes: `LocationService.getPositionStream()` (unchanged signature).

- [ ] **Step 1: Add UIBackgroundModes to Info.plist**

Add before the closing `</dict>`:

```xml
	<key>UIBackgroundModes</key>
	<array>
		<string>location</string>
		<string>bluetooth-central</string>
	</array>
```

- [ ] **Step 2: Platform-specific location settings**

Replace `GeolocatorLocationService.getPositionStream()`:

```dart
  @override
  Stream<Position> getPositionStream() {
    // Background-capable settings: iOS keeps delivering updates when the
    // phone is locked (requires the UIBackgroundModes location entry and
    // shows the system location indicator); Android relies on the cardio
    // foreground service to stay alive.
    late final LocationSettings settings;
    if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }
```

Add `import 'dart:io';` to the file.

- [ ] **Step 3: Verify**

Run: `flutter test test/features/cardio/ && dart analyze`
Expected: all pass, zero analyzer issues. (iOS cannot be built on this Linux host; plist change is verified by inspection.)

- [ ] **Step 4: Commit**

```bash
git add ios/Runner/Info.plist lib/features/cardio/data/location_service.dart
git commit -m "feat: enable iOS background location and BLE for cardio sessions"
```

---

### Task 6: Full verification and PR

**Files:** none new.

- [ ] **Step 1: Full suite**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 2: Analyzer and format**

Run: `dart analyze && dart format --set-exit-if-changed .`
Expected: zero issues, no reformats.

- [ ] **Step 3: Push branch and open PR**

```bash
git push -u origin fix/issue-57-background-cardio
gh pr create --title "fix: keep cardio tracking accurate and alive when the phone is locked" --body "Fixes #57 ..."
```

PR body must cover: wall-clock timer fix (both controllers), Android foreground service (types, notification, best-effort), iOS background modes + geolocator settings, and note that GPS-point incremental persistence (issue item 4) is deferred.
