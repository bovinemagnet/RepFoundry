import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthSyncSettings {
  final bool enabled;
  final bool writeWorkouts;
  final bool writeWeight;
  final bool writeHeartRate;
  final bool readWeight;

  const HealthSyncSettings({
    this.enabled = false,
    this.writeWorkouts = true,
    this.writeWeight = true,
    this.writeHeartRate = false,
    this.readWeight = false,
  });

  HealthSyncSettings copyWith({
    bool? enabled,
    bool? writeWorkouts,
    bool? writeWeight,
    bool? writeHeartRate,
    bool? readWeight,
  }) {
    return HealthSyncSettings(
      enabled: enabled ?? this.enabled,
      writeWorkouts: writeWorkouts ?? this.writeWorkouts,
      writeWeight: writeWeight ?? this.writeWeight,
      writeHeartRate: writeHeartRate ?? this.writeHeartRate,
      readWeight: readWeight ?? this.readWeight,
    );
  }
}

class HealthSyncSettingsNotifier extends Notifier<HealthSyncSettings> {
  static const _keyEnabled = 'health_sync_enabled';
  static const _keyWriteWorkouts = 'health_sync_write_workouts';
  static const _keyWriteWeight = 'health_sync_write_weight';
  static const _keyWriteHeartRate = 'health_sync_write_heart_rate';
  static const _keyReadWeight = 'health_sync_read_weight';

  @override
  HealthSyncSettings build() {
    _load();
    return const HealthSyncSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = HealthSyncSettings(
      enabled: prefs.getBool(_keyEnabled) ?? false,
      writeWorkouts: prefs.getBool(_keyWriteWorkouts) ?? true,
      writeWeight: prefs.getBool(_keyWriteWeight) ?? true,
      writeHeartRate: prefs.getBool(_keyWriteHeartRate) ?? false,
      readWeight: prefs.getBool(_keyReadWeight) ?? false,
    );
  }

  Future<void> toggleEnabled() async {
    final newValue = !state.enabled;
    state = state.copyWith(enabled: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, newValue);
  }

  Future<void> toggleWriteWorkouts() async {
    final newValue = !state.writeWorkouts;
    state = state.copyWith(writeWorkouts: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWriteWorkouts, newValue);
  }

  Future<void> toggleWriteWeight() async {
    final newValue = !state.writeWeight;
    state = state.copyWith(writeWeight: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWriteWeight, newValue);
  }

  Future<void> toggleWriteHeartRate() async {
    final newValue = !state.writeHeartRate;
    state = state.copyWith(writeHeartRate: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWriteHeartRate, newValue);
  }

  Future<void> toggleReadWeight() async {
    final newValue = !state.readWeight;
    state = state.copyWith(readWeight: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReadWeight, newValue);
  }
}

final healthSyncSettingsProvider =
    NotifierProvider<HealthSyncSettingsNotifier, HealthSyncSettings>(
  HealthSyncSettingsNotifier.new,
);
