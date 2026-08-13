import 'package:rep_foundry/features/notifications/data/notification_service.dart';
import 'package:rep_foundry/features/notifications/domain/models/reminder_settings.dart';

/// A notification service that reports permission as granted and swallows
/// every scheduling call.
///
/// Integration tests run on simulators where notification permission has
/// never been requested, so the real service reports it denied and the
/// screen shows its "notifications are blocked" banner — an artefact of the
/// test device, not a state the documentation should show. Faking it also
/// stops a test run scheduling real notifications on the machine.
class FakeNotificationService implements NotificationService {
  NotificationPermission status = NotificationPermission.granted;

  @override
  Future<NotificationPermission> permissionStatus() async => status;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> showTestNotification() async {}

  @override
  Future<void> scheduleWeeklyReminders(ReminderSettings settings) async {}

  @override
  Future<void> scheduleStreakReminder(int hour, int minute) async {}

  @override
  Future<void> cancelStreakReminder() async {}

  @override
  Future<void> cancelAllReminders() async {}
}
