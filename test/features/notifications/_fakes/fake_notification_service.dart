import 'package:rep_foundry/features/notifications/data/notification_service.dart';
import 'package:rep_foundry/features/notifications/domain/models/reminder_settings.dart';

class FakeNotificationService implements NotificationService {
  NotificationPermission status = NotificationPermission.granted;
  bool requestResult = true;

  int requestCallCount = 0;
  int openSettingsCallCount = 0;
  int testNotificationCallCount = 0;
  int weeklyScheduleCallCount = 0;
  int streakScheduleCallCount = 0;
  int streakCancelCallCount = 0;
  int cancelAllCallCount = 0;
  ReminderSettings? lastWeeklySettings;

  @override
  Future<NotificationPermission> permissionStatus() async => status;

  @override
  Future<bool> requestPermission() async {
    requestCallCount += 1;
    status = requestResult
        ? NotificationPermission.granted
        : NotificationPermission.denied;
    return requestResult;
  }

  @override
  Future<void> openNotificationSettings() async {
    openSettingsCallCount += 1;
  }

  @override
  Future<void> showTestNotification() async {
    testNotificationCallCount += 1;
  }

  @override
  Future<void> scheduleWeeklyReminders(ReminderSettings settings) async {
    weeklyScheduleCallCount += 1;
    lastWeeklySettings = settings;
  }

  @override
  Future<void> scheduleStreakReminder(int hour, int minute) async {
    streakScheduleCallCount += 1;
  }

  @override
  Future<void> cancelStreakReminder() async {
    streakCancelCallCount += 1;
  }

  @override
  Future<void> cancelAllReminders() async {
    cancelAllCallCount += 1;
  }

  @override
  Future<void> init() async {}
}
