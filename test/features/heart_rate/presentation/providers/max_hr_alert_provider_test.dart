import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/max_hr_alert_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MaxHrAlertNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      // Allow the async _load() to complete.
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has vibration and sound enabled', () {
      final state = container.read(maxHrAlertProvider);
      expect(state.vibrationEnabled, isTrue);
      expect(state.soundEnabled, isTrue);
      expect(state.cooldownSeconds, 15);
      expect(state.isEnabled, isTrue);
    });

    test('toggleVibration disables vibration', () async {
      final notifier = container.read(maxHrAlertProvider.notifier);
      await notifier.toggleVibration();
      final state = container.read(maxHrAlertProvider);
      expect(state.vibrationEnabled, isFalse);
      expect(state.soundEnabled, isTrue);
      expect(state.isEnabled, isTrue);
    });

    test('toggleSound disables sound', () async {
      final notifier = container.read(maxHrAlertProvider.notifier);
      await notifier.toggleSound();
      final state = container.read(maxHrAlertProvider);
      expect(state.soundEnabled, isFalse);
      expect(state.vibrationEnabled, isTrue);
    });

    test('isEnabled returns false when both disabled', () async {
      final notifier = container.read(maxHrAlertProvider.notifier);
      await notifier.toggleVibration();
      await notifier.toggleSound();
      expect(container.read(maxHrAlertProvider).isEnabled, isFalse);
    });

    test('setCooldown updates cooldown seconds', () async {
      final notifier = container.read(maxHrAlertProvider.notifier);
      await notifier.setCooldown(30);
      expect(container.read(maxHrAlertProvider).cooldownSeconds, 30);
    });

    test('persists values via SharedPreferences', () async {
      final notifier = container.read(maxHrAlertProvider.notifier);
      await notifier.toggleVibration();
      await notifier.setCooldown(60);
      container.dispose();

      // Create a new container — should load persisted values
      container = ProviderContainer();
      // Trigger the provider so build() and _load() are called.
      container.read(maxHrAlertProvider);
      // Allow the async _load() chain to fully complete (multiple microtasks).
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(maxHrAlertProvider);
      expect(state.vibrationEnabled, isFalse);
      expect(state.soundEnabled, isTrue);
      expect(state.cooldownSeconds, 60);
    });
  });
}
