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
  // `_initialSettings` gives build() a stable device ID immediately,
  // `_loadFuture` ensures every caller awaits the same preferences read,
  // and `_loadedSettings` lets rebuilds keep returning the last loaded
  // state instead of temporarily falling back to `_initialSettings`.
  Future<void>? _loadFuture;
  final SyncSettings _initialSettings =
      SyncSettings(deviceId: const Uuid().v4());
  SyncSettings? _loadedSettings;

  @override
  SyncSettings build() {
    _ensureLoadStarted();
    return _loadedSettings ?? _initialSettings;
  }

  Future<void> ensureLoaded() async {
    await _ensureLoadStarted();
  }

  Future<void> _ensureLoadStarted() {
    final loadFuture = _loadFuture;
    if (loadFuture != null) return loadFuture;
    final startedLoad = _load();
    _loadFuture = startedLoad;
    return startedLoad;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final deviceId = prefs.getString(_keyDeviceId) ?? _initialSettings.deviceId;
    // Persist device ID on first load
    if (!prefs.containsKey(_keyDeviceId)) {
      await prefs.setString(_keyDeviceId, deviceId);
    }

    final lastSyncMs = prefs.getInt(_keyLastSyncAt);
    final loadedSettings = SyncSettings(
      enabled: prefs.getBool(_keyEnabled) ?? false,
      lastSyncAt: lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs, isUtc: true)
          : null,
      deviceId: deviceId,
      consentGiven: prefs.getBool(_keyConsentGiven) ?? false,
    );
    _loadedSettings = loadedSettings;
    state = loadedSettings;
  }

  Future<void> setEnabled(bool enabled) async {
    final nextState = state.copyWith(enabled: enabled);
    _loadedSettings = nextState;
    state = nextState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }

  Future<void> setConsentGiven(bool given) async {
    final nextState = state.copyWith(consentGiven: given);
    _loadedSettings = nextState;
    state = nextState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsentGiven, given);
  }

  Future<void> updateLastSyncAt(DateTime time) async {
    final nextState = state.copyWith(lastSyncAt: time);
    _loadedSettings = nextState;
    state = nextState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSyncAt, time.millisecondsSinceEpoch);
  }

  Future<void> disableAndClear() async {
    final nextState = SyncSettings(deviceId: state.deviceId);
    _loadedSettings = nextState;
    state = nextState;
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
