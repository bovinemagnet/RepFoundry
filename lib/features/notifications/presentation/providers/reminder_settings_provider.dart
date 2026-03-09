import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/reminder_settings.dart';
import '../../data/notification_service.dart';

String daysToString(Set<int> days) {
  final sorted = days.toList()..sort();
  return sorted.join(',');
}

Set<int> stringToDays(String value) {
  if (value.isEmpty) return {};
  return value.split(',').map(int.parse).toSet();
}

class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  ReminderSettingsNotifier() : super(const ReminderSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = ReminderSettings(
      enabledDays: stringToDays(prefs.getString('reminder_days') ?? ''),
      hour: prefs.getInt('reminder_hour') ?? 18,
      minute: prefs.getInt('reminder_minute') ?? 0,
      streakReminderEnabled: prefs.getBool('streak_reminder') ?? false,
    );
  }

  Future<void> toggleDay(int day) async {
    final days = Set<int>.from(state.enabledDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(enabledDays: days);
    await _persist();
    await _reschedule();
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _persist();
    await _reschedule();
  }

  Future<void> toggleStreakReminder() async {
    final newValue = !state.streakReminderEnabled;
    state = state.copyWith(streakReminderEnabled: newValue);
    await _persist();
    if (newValue) {
      await NotificationService().scheduleStreakReminder(state.hour, state.minute);
    } else {
      await NotificationService().cancelStreakReminder();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_days', daysToString(state.enabledDays));
    await prefs.setInt('reminder_hour', state.hour);
    await prefs.setInt('reminder_minute', state.minute);
    await prefs.setBool('streak_reminder', state.streakReminderEnabled);
  }

  Future<void> _reschedule() async {
    final service = NotificationService();
    await service.scheduleWeeklyReminders(state);
    if (state.streakReminderEnabled) {
      await service.scheduleStreakReminder(state.hour, state.minute);
    }
  }
}

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  (ref) => ReminderSettingsNotifier(),
);
