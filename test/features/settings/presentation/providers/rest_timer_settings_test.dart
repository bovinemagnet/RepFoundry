import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/features/settings/presentation/providers/rest_timer_settings_provider.dart';

void main() {
  group('RestTimerSettings', () {
    test('defaults both to true', () {
      const settings = RestTimerSettings();
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.soundEnabled, isTrue);
    });

    test('copyWith overrides specified fields', () {
      const settings = RestTimerSettings();
      final updated = settings.copyWith(vibrationEnabled: false);
      expect(updated.vibrationEnabled, isFalse);
      expect(updated.soundEnabled, isTrue);
    });
  });

  group('RestTimerSettingsNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads defaults when no prefs exist', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(restTimerSettingsProvider);
      // Before async load completes, defaults apply
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.soundEnabled, isTrue);
    });

    test('loads saved values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'rest_timer_vibration': false,
        'rest_timer_sound': false,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger the read so the notifier is created
      container.read(restTimerSettingsProvider);

      // Wait for async _load() to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final settings = container.read(restTimerSettingsProvider);
      expect(settings.vibrationEnabled, isFalse);
      expect(settings.soundEnabled, isFalse);
    });

    test('toggleVibration flips value and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(restTimerSettingsProvider.notifier);
      expect(
          container.read(restTimerSettingsProvider).vibrationEnabled, isTrue);

      await notifier.toggleVibration();
      expect(
          container.read(restTimerSettingsProvider).vibrationEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rest_timer_vibration'), isFalse);
    });

    test('toggleSound flips value and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(restTimerSettingsProvider.notifier);
      expect(container.read(restTimerSettingsProvider).soundEnabled, isTrue);

      await notifier.toggleSound();
      expect(container.read(restTimerSettingsProvider).soundEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rest_timer_sound'), isFalse);
    });
  });
}
