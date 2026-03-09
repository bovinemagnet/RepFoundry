import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';

void main() {
  group('HealthSyncSettings', () {
    test('defaults are correct', () {
      const settings = HealthSyncSettings();
      expect(settings.enabled, isFalse);
      expect(settings.writeWorkouts, isTrue);
      expect(settings.writeWeight, isTrue);
      expect(settings.writeHeartRate, isFalse);
      expect(settings.readWeight, isFalse);
    });

    test('copyWith updates specific field', () {
      const settings = HealthSyncSettings();
      final updated = settings.copyWith(enabled: true, readWeight: true);
      expect(updated.enabled, isTrue);
      expect(updated.readWeight, isTrue);
      expect(updated.writeWorkouts, isTrue); // unchanged
    });
  });
}
