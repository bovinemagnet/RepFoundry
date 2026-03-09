class ReminderSettings {
  final Set<int> enabledDays; // DateTime.monday (1) through DateTime.sunday (7)
  final int hour;
  final int minute;
  final bool streakReminderEnabled;

  const ReminderSettings({
    this.enabledDays = const {},
    this.hour = 18,
    this.minute = 0,
    this.streakReminderEnabled = false,
  });

  bool get hasReminders => enabledDays.isNotEmpty;

  ReminderSettings copyWith({
    Set<int>? enabledDays,
    int? hour,
    int? minute,
    bool? streakReminderEnabled,
  }) {
    return ReminderSettings(
      enabledDays: enabledDays ?? this.enabledDays,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      streakReminderEnabled:
          streakReminderEnabled ?? this.streakReminderEnabled,
    );
  }
}
