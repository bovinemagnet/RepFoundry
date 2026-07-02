import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process alive on Android while a cardio session is
/// running so GPS and BLE heart-rate streams survive the phone being
/// locked, showing the platform-required ongoing notification. iOS
/// background execution is handled by UIBackgroundModes and the
/// background-capable location subscription instead.
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
    // Android 14+ requires a permitted service type; without GPS or an HR
    // monitor there is nothing to keep alive (the elapsed timer is
    // wall-clock based and self-corrects on resume).
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
