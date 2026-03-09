import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../domain/models/reminder_settings.dart';

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

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
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

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
