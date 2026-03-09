import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaxHrAlertSettings {
  final bool vibrationEnabled;
  final bool soundEnabled;

  /// Cooldown in seconds between alerts to avoid constant buzzing.
  final int cooldownSeconds;

  const MaxHrAlertSettings({
    this.vibrationEnabled = true,
    this.soundEnabled = true,
    this.cooldownSeconds = 15,
  });

  MaxHrAlertSettings copyWith({
    bool? vibrationEnabled,
    bool? soundEnabled,
    int? cooldownSeconds,
  }) {
    return MaxHrAlertSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    );
  }

  bool get isEnabled => vibrationEnabled || soundEnabled;
}

class MaxHrAlertNotifier extends Notifier<MaxHrAlertSettings> {
  @override
  MaxHrAlertSettings build() {
    _load();
    return const MaxHrAlertSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = MaxHrAlertSettings(
      vibrationEnabled: prefs.getBool('hr_max_alert_vibration') ?? true,
      soundEnabled: prefs.getBool('hr_max_alert_sound') ?? true,
      cooldownSeconds: prefs.getInt('hr_max_alert_cooldown') ?? 15,
    );
  }

  Future<void> toggleVibration() async {
    final newValue = !state.vibrationEnabled;
    state = state.copyWith(vibrationEnabled: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hr_max_alert_vibration', newValue);
  }

  Future<void> toggleSound() async {
    final newValue = !state.soundEnabled;
    state = state.copyWith(soundEnabled: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hr_max_alert_sound', newValue);
  }

  Future<void> setCooldown(int seconds) async {
    state = state.copyWith(cooldownSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hr_max_alert_cooldown', seconds);
  }
}

final maxHrAlertProvider =
    NotifierProvider<MaxHrAlertNotifier, MaxHrAlertSettings>(
  MaxHrAlertNotifier.new,
);
