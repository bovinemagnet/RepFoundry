import 'package:flutter_riverpod/legacy.dart';
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

class MaxHrAlertNotifier extends StateNotifier<MaxHrAlertSettings> {
  MaxHrAlertNotifier() : super(const MaxHrAlertSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
    StateNotifierProvider<MaxHrAlertNotifier, MaxHrAlertSettings>(
  (ref) => MaxHrAlertNotifier(),
);
