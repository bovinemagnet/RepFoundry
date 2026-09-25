import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process alive on Android while a cardio session is
/// running, the heart-rate panel is monitoring, or the coach is talking
/// through a workout, so GPS, BLE heart-rate streams and spoken cues survive
/// the phone being locked, showing the platform-required ongoing
/// notification. iOS background execution is handled by UIBackgroundModes
/// and the background-capable location subscription instead.
abstract class ForegroundSessionService {
  /// Reconcile the platform foreground service with the session state.
  Future<void> update({
    required bool sessionRunning,
    required bool gpsEnabled,
    required bool hrConnected,
    required bool coachActive,
  });

  /// Fires when the user taps the notification's "Turn coach off" button,
  /// shown only while the coach is keeping the service alive.
  Stream<void> get coachStopRequests;
}

/// Id of the notification button that switches the coach off.
const String stopCoachButtonId = 'stop_coach';

/// Runs in the service's own isolate; the plugin calls it when the service
/// starts. Its only job is to relay notification button presses back to the
/// app's isolate.
@pragma('vm:entry-point')
void foregroundTaskStart() {
  FlutterForegroundTask.setTaskHandler(_ButtonRelay());
}

class _ButtonRelay extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain(id);
  }
}

class FlutterForegroundSessionService implements ForegroundSessionService {
  bool _initialised = false;
  bool _running = false;
  bool _gps = false;
  bool _hr = false;
  bool _coach = false;
  final _stopCoach = StreamController<void>.broadcast();

  @override
  Stream<void> get coachStopRequests => _stopCoach.stream;

  void _onTaskData(Object data) {
    if (data == stopCoachButtonId) _stopCoach.add(null);
  }

  void _init() {
    if (_initialised) return;
    _initialised = true;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
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
    required bool coachActive,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    // Android 14+ requires a permitted service type; without GPS, an HR
    // monitor or the coach's voice there is nothing to keep alive (the
    // elapsed timer is wall-clock based and self-corrects on resume).
    final wantsService =
        sessionRunning && (gpsEnabled || hrConnected || coachActive);
    try {
      if (!wantsService) {
        if (_running) {
          _running = false;
          await FlutterForegroundTask.stopService();
        }
        return;
      }
      final typesChanged =
          gpsEnabled != _gps || hrConnected != _hr || coachActive != _coach;
      if (_running && !typesChanged) return;
      _init();
      if (_running && typesChanged) {
        // Service types can only be set at start, so restart with the
        // new capability set.
        await FlutterForegroundTask.stopService();
        _running = false;
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
          // The coach's spoken cues are audio the user chose to hear.
          if (coachActive) ForegroundServiceTypes.mediaPlayback,
        ],
        notificationTitle: gpsEnabled || coachActive
            ? 'RepFoundry is tracking your workout'
            : 'RepFoundry is monitoring your heart rate',
        notificationText: gpsEnabled
            ? 'Cardio session in progress'
            : coachActive
                ? 'Your coach is with you'
                : 'Heart rate monitor connected',
        notificationButtons: coachActive
            ? const [
                NotificationButton(
                  id: stopCoachButtonId,
                  text: 'Turn coach off',
                ),
              ]
            : null,
        callback: foregroundTaskStart,
      );
      _running = true;
      _gps = gpsEnabled;
      _hr = hrConnected;
      _coach = coachActive;
    } on Exception {
      // Best-effort: background tracking must never break the session.
    }
  }
}
