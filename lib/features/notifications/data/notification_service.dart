import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../domain/models/reminder_settings.dart';

enum NotificationPermission { unknown, granted, denied }

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;

    tzdata.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialised = true;
  }

  /// Detect the device's IANA timezone and bind it to `tz.local`. Without
  /// this, scheduled notifications use UTC and fire at the wrong wall-clock
  /// time outside the UTC zone.
  Future<void> _configureLocalTimeZone() async {
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      debugPrint('Failed to detect local timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<NotificationPermission> permissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == null) return NotificationPermission.unknown;
      return enabled
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      if (options == null) return NotificationPermission.unknown;
      return options.isEnabled
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    return NotificationPermission.granted;
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return (await android?.requestNotificationsPermission()) ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return (await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }
    return true;
  }

  Future<void> openNotificationSettings() {
    return AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      id: 999,
      title: 'RepFoundry test notification',
      body: 'If you can see this, reminders will work.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminders',
          'Workout Reminders',
          channelDescription: 'Scheduled workout reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'test_notification',
    );
  }

  Future<void> scheduleWeeklyReminders(
      ReminderSettings reminderSettings) async {
    await cancelAllReminders();

    for (final day in reminderSettings.enabledDays) {
      await _plugin.zonedSchedule(
        id: day,
        title: 'Time to work out!',
        body: 'Your scheduled workout reminder',
        scheduledDate: _nextInstanceOfDayAndTime(
            day, reminderSettings.hour, reminderSettings.minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminders',
            'Workout Reminders',
            channelDescription: 'Scheduled workout reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'workout_reminder',
      );
    }
  }

  Future<void> scheduleStreakReminder(int hour, int minute) async {
    const streakId = 100;
    await _plugin.zonedSchedule(
      id: streakId,
      title: 'Don\'t break your streak!',
      body: 'You haven\'t logged a workout today',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminders',
          'Streak Reminders',
          channelDescription: 'Reminder when workout streak is at risk',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'streak_reminder',
    );
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(id: 100);
  }

  Future<void> cancelAllReminders() async {
    for (var i = 1; i <= 7; i++) {
      await _plugin.cancel(id: i);
    }
    await _plugin.cancel(id: 100);
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) =>
      nextInstanceOfDayAndTime(day, hour, minute);

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) =>
      nextInstanceOfTime(hour, minute);
}

@visibleForTesting
tz.TZDateTime nextInstanceOfDayAndTime(int day, int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  while (scheduledDate.weekday != day) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 7));
  }

  return scheduledDate;
}

@visibleForTesting
tz.TZDateTime nextInstanceOfTime(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  return scheduledDate;
}
