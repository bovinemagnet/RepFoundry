import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/sync_settings.dart';
import '../../domain/models/sync_state.dart';

class SyncSettingsNotifier extends Notifier<SyncSettings> {
  static const _keyEnabled = 'cloud_sync_enabled';
  static const _keyLastSyncAt = 'cloud_sync_last_sync_at';
  static const _keyDeviceId = 'cloud_sync_device_id';
  static const _keyConsentGiven = 'cloud_sync_consent_given';

  @override
  SyncSettings build() {
    _load();
    return SyncSettings(deviceId: const Uuid().v4());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final deviceId = prefs.getString(_keyDeviceId) ?? state.deviceId;
    // Persist device ID on first load
    if (!prefs.containsKey(_keyDeviceId)) {
      await prefs.setString(_keyDeviceId, deviceId);
    }

    final lastSyncMs = prefs.getInt(_keyLastSyncAt);
    state = SyncSettings(
      enabled: prefs.getBool(_keyEnabled) ?? false,
      lastSyncAt: lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs, isUtc: true)
          : null,
      deviceId: deviceId,
      consentGiven: prefs.getBool(_keyConsentGiven) ?? false,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }

  Future<void> setConsentGiven(bool given) async {
    state = state.copyWith(consentGiven: given);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsentGiven, given);
  }

  Future<void> updateLastSyncAt(DateTime time) async {
    state = state.copyWith(lastSyncAt: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSyncAt, time.millisecondsSinceEpoch);
  }

  Future<void> disableAndClear() async {
    state = SyncSettings(deviceId: state.deviceId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyLastSyncAt);
    await prefs.remove(_keyConsentGiven);
  }
}

final syncSettingsProvider =
    NotifierProvider<SyncSettingsNotifier, SyncSettings>(
  SyncSettingsNotifier.new,
);

class SyncStateNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  void setStatus(SyncStatus status, {String? error, DateTime? lastSyncAt}) {
    state = SyncState(
      status: status,
      lastSyncAt: lastSyncAt ?? state.lastSyncAt,
      errorMessage: error,
    );
  }
}

final syncStateProvider = NotifierProvider<SyncStateNotifier, SyncState>(
  SyncStateNotifier.new,
);
