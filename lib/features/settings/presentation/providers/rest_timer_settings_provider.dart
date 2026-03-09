import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestTimerSettings {
  final bool vibrationEnabled;
  final bool soundEnabled;

  const RestTimerSettings({
    this.vibrationEnabled = true,
    this.soundEnabled = true,
  });

  RestTimerSettings copyWith({
    bool? vibrationEnabled,
    bool? soundEnabled,
  }) {
    return RestTimerSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class RestTimerSettingsNotifier extends Notifier<RestTimerSettings> {
  @override
  RestTimerSettings build() {
    _load();
    return const RestTimerSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = RestTimerSettings(
      vibrationEnabled: prefs.getBool('rest_timer_vibration') ?? true,
      soundEnabled: prefs.getBool('rest_timer_sound') ?? true,
    );
  }

  Future<void> toggleVibration() async {
    final newValue = !state.vibrationEnabled;
    state = state.copyWith(vibrationEnabled: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rest_timer_vibration', newValue);
  }

  Future<void> toggleSound() async {
    final newValue = !state.soundEnabled;
    state = state.copyWith(soundEnabled: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rest_timer_sound', newValue);
  }
}

final restTimerSettingsProvider =
    NotifierProvider<RestTimerSettingsNotifier, RestTimerSettings>(
  RestTimerSettingsNotifier.new,
);
