import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/notification_service.dart';
import '../providers/reminder_settings_provider.dart';
import '../widgets/reminder_days_picker.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final settings = ref.watch(reminderSettingsProvider);
    final permission = ref.watch(notificationPermissionProvider);
    final isDenied =
        permission.value == NotificationPermission.denied;

    return Scaffold(
      appBar: AppBar(title: Text(s.notificationsScreenTitle)),
      body: ListView(
        children: [
          if (isDenied) _PermissionDeniedBanner(),
          _SectionHeader(title: s.workoutReminders),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(s.reminderDays),
            subtitle: Text(s.workoutRemindersSubtitle),
          ),
          ReminderDaysPicker(onBeforeToggle: () => _ensurePermission(ref)),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(s.reminderTime),
            subtitle: Text(s.reminderTimeSubtitle),
            trailing: Text(
              s.reminderTimeOfDay(
                settings.hour.toString().padLeft(2, '0'),
                settings.minute.toString().padLeft(2, '0'),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.hour,
                  minute: settings.minute,
                ),
              );
              if (time == null) return;
              await ref
                  .read(reminderSettingsProvider.notifier)
                  .setTime(time.hour, time.minute);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: Text(s.streakReminder),
            subtitle: Text(s.streakReminderSubtitle),
            value: settings.streakReminderEnabled,
            onChanged: (_) async {
              if (!await _ensurePermission(ref)) return;
              await ref
                  .read(reminderSettingsProvider.notifier)
                  .toggleStreakReminder();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(s.sendTestNotification),
            subtitle: Text(s.sendTestNotificationSubtitle),
            enabled: !isDenied,
            onTap: () => _sendTest(context, ref),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensurePermission(WidgetRef ref) async {
    final notifier = ref.read(notificationPermissionProvider.notifier);
    final current = ref.read(notificationPermissionProvider).value ??
        NotificationPermission.unknown;
    if (current == NotificationPermission.granted) return true;
    final result = await notifier.request();
    return result == NotificationPermission.granted;
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final s = S.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final granted = await _ensurePermission(ref);
    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(s.testNotificationBlockedSnack)),
      );
      return;
    }
    await ref.read(notificationServiceProvider).showTestNotification();
    messenger.showSnackBar(
      SnackBar(content: Text(s.testNotificationSentSnack)),
    );
  }
}

class _PermissionDeniedBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    return MaterialBanner(
      backgroundColor: theme.colorScheme.errorContainer,
      content: Text(
        s.permissionDeniedBanner,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
      leading: Icon(
        Icons.notifications_off_outlined,
        color: theme.colorScheme.onErrorContainer,
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(notificationServiceProvider)
                .openNotificationSettings();
            // Re-check after returning from system settings.
            await ref
                .read(notificationPermissionProvider.notifier)
                .refresh();
          },
          child: Text(s.openSystemSettings),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}
