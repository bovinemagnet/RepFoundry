import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rep_foundry/features/sync/domain/models/sync_settings.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_state.dart';
import 'package:rep_foundry/features/sync/presentation/providers/sync_settings_provider.dart';

void main() {
  group('SyncSettingsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has enabled false, consentGiven false, non-empty UUID deviceId', () async {
      final settings = container.read(syncSettingsProvider);

      expect(settings.enabled, isFalse);
      expect(settings.consentGiven, isFalse);
      expect(settings.deviceId, isNotEmpty);
      // UUID v4 format: 8-4-4-4-12
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            .hasMatch(settings.deviceId),
        isTrue,
      );

      // Allow async _load() to complete before tearDown disposes container
      await Future<void>.delayed(Duration.zero);
    });

    test('setEnabled persists to SharedPreferences', () async {
      final notifier = container.read(syncSettingsProvider.notifier);
      await notifier.setEnabled(true);

      expect(container.read(syncSettingsProvider).enabled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('cloud_sync_enabled'), isTrue);
    });

    test('setConsentGiven persists', () async {
      final notifier = container.read(syncSettingsProvider.notifier);
      await notifier.setConsentGiven(true);

      expect(container.read(syncSettingsProvider).consentGiven, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('cloud_sync_consent_given'), isTrue);
    });

    test('updateLastSyncAt persists epoch ms in prefs', () async {
      final notifier = container.read(syncSettingsProvider.notifier);
      final now = DateTime.utc(2026, 3, 9, 12, 0, 0);
      await notifier.updateLastSyncAt(now);

      expect(container.read(syncSettingsProvider).lastSyncAt, equals(now));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('cloud_sync_last_sync_at'), equals(now.millisecondsSinceEpoch));
    });

    test('disableAndClear resets all fields but preserves deviceId', () async {
      final notifier = container.read(syncSettingsProvider.notifier);

      // Enable and set values first
      await notifier.setEnabled(true);
      await notifier.setConsentGiven(true);
      await notifier.updateLastSyncAt(DateTime.utc(2026, 1, 1));

      final deviceIdBefore = container.read(syncSettingsProvider).deviceId;

      await notifier.disableAndClear();

      final settings = container.read(syncSettingsProvider);
      expect(settings.enabled, isFalse);
      expect(settings.lastSyncAt, isNull);
      expect(settings.consentGiven, isFalse);
      expect(settings.deviceId, equals(deviceIdBefore));
    });

    test('persistence round-trip restores values after dispose', () async {
      final notifier = container.read(syncSettingsProvider.notifier);
      await notifier.setEnabled(true);
      await notifier.setConsentGiven(true);
      final syncTime = DateTime.utc(2026, 3, 9, 10, 30, 0);
      await notifier.updateLastSyncAt(syncTime);

      // Allow _load() to persist deviceId
      await Future<void>.delayed(Duration.zero);

      final originalDeviceId = container.read(syncSettingsProvider).deviceId;

      // Dispose and create a new container
      container.dispose();

      container = ProviderContainer();
      // Read to trigger build() and _load()
      container.read(syncSettingsProvider);

      // Allow async _load() to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final restored = container.read(syncSettingsProvider);
      expect(restored.enabled, isTrue);
      expect(restored.consentGiven, isTrue);
      expect(restored.lastSyncAt, equals(syncTime));
      expect(restored.deviceId, equals(originalDeviceId));
    });
  });

  group('SyncStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle with no error and no lastSyncAt', () {
      final syncState = container.read(syncStateProvider);

      expect(syncState.status, equals(SyncStatus.idle));
      expect(syncState.errorMessage, isNull);
      expect(syncState.lastSyncAt, isNull);
    });

    test('setStatus updates status and lastSyncAt', () {
      final notifier = container.read(syncStateProvider.notifier);

      notifier.setStatus(SyncStatus.syncing);
      expect(container.read(syncStateProvider).status, equals(SyncStatus.syncing));

      final now = DateTime.utc(2026, 3, 9, 14, 0, 0);
      notifier.setStatus(SyncStatus.success, lastSyncAt: now);

      final syncState = container.read(syncStateProvider);
      expect(syncState.status, equals(SyncStatus.success));
      expect(syncState.lastSyncAt, equals(now));
    });

    test('setStatus with error sets errorMessage', () {
      final notifier = container.read(syncStateProvider.notifier);

      notifier.setStatus(SyncStatus.error, error: 'Network unavailable');

      final syncState = container.read(syncStateProvider);
      expect(syncState.status, equals(SyncStatus.error));
      expect(syncState.errorMessage, equals('Network unavailable'));
    });
  });
}
