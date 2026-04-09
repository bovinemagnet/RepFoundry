import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_settings.dart';

void main() {
  group('SyncSettings', () {
    test('default enabled is false', () {
      const settings = SyncSettings(deviceId: 'device-1');
      expect(settings.enabled, isFalse);
    });

    test('default lastSyncAt is null', () {
      const settings = SyncSettings(deviceId: 'device-1');
      expect(settings.lastSyncAt, isNull);
    });

    test('default consentGiven is false', () {
      const settings = SyncSettings(deviceId: 'device-1');
      expect(settings.consentGiven, isFalse);
    });

    test('stores provided deviceId', () {
      const settings = SyncSettings(deviceId: 'my-device-abc');
      expect(settings.deviceId, 'my-device-abc');
    });

    test('copyWith updates enabled and preserves other fields', () {
      const original = SyncSettings(
        deviceId: 'device-1',
        enabled: false,
        consentGiven: false,
      );
      final updated = original.copyWith(enabled: true);

      expect(updated.enabled, isTrue);
      expect(updated.deviceId, original.deviceId);
      expect(updated.lastSyncAt, original.lastSyncAt);
      expect(updated.consentGiven, original.consentGiven);
    });

    test('copyWith updates lastSyncAt and preserves other fields', () {
      const original = SyncSettings(deviceId: 'device-1');
      final syncTime = DateTime.utc(2024, 3, 15, 10, 30);
      final updated = original.copyWith(lastSyncAt: syncTime);

      expect(updated.lastSyncAt, syncTime);
      expect(updated.deviceId, original.deviceId);
      expect(updated.enabled, original.enabled);
      expect(updated.consentGiven, original.consentGiven);
    });

    test('copyWith updates deviceId and preserves other fields', () {
      const original = SyncSettings(
        deviceId: 'old-device',
        enabled: true,
        consentGiven: true,
      );
      final updated = original.copyWith(deviceId: 'new-device');

      expect(updated.deviceId, 'new-device');
      expect(updated.enabled, original.enabled);
      expect(updated.lastSyncAt, original.lastSyncAt);
      expect(updated.consentGiven, original.consentGiven);
    });

    test('copyWith updates consentGiven and preserves other fields', () {
      const original = SyncSettings(deviceId: 'device-1', consentGiven: false);
      final updated = original.copyWith(consentGiven: true);

      expect(updated.consentGiven, isTrue);
      expect(updated.deviceId, original.deviceId);
      expect(updated.enabled, original.enabled);
      expect(updated.lastSyncAt, original.lastSyncAt);
    });

    test('copyWith with no arguments returns equivalent settings', () {
      final lastSync = DateTime.utc(2024, 1, 1);
      final original = SyncSettings(
        deviceId: 'device-xyz',
        enabled: true,
        lastSyncAt: lastSync,
        consentGiven: true,
      );
      final copy = original.copyWith();

      expect(copy.deviceId, original.deviceId);
      expect(copy.enabled, original.enabled);
      expect(copy.lastSyncAt, original.lastSyncAt);
      expect(copy.consentGiven, original.consentGiven);
    });

    test('copyWith can update all fields simultaneously', () {
      const original = SyncSettings(deviceId: 'old-device');
      final newSyncAt = DateTime.utc(2025, 6, 1);
      final updated = original.copyWith(
        enabled: true,
        lastSyncAt: newSyncAt,
        deviceId: 'new-device',
        consentGiven: true,
      );

      expect(updated.enabled, isTrue);
      expect(updated.lastSyncAt, newSyncAt);
      expect(updated.deviceId, 'new-device');
      expect(updated.consentGiven, isTrue);
    });
  });
}
