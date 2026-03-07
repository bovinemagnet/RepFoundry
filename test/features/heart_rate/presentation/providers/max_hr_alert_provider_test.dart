import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/max_hr_alert_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MaxHrAlertNotifier', () {
    late MaxHrAlertNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      notifier = MaxHrAlertNotifier();
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state has vibration and sound enabled', () {
      expect(notifier.state.vibrationEnabled, isTrue);
      expect(notifier.state.soundEnabled, isTrue);
      expect(notifier.state.cooldownSeconds, 15);
      expect(notifier.state.isEnabled, isTrue);
    });

    test('toggleVibration disables vibration', () async {
      await notifier.toggleVibration();
      expect(notifier.state.vibrationEnabled, isFalse);
      expect(notifier.state.soundEnabled, isTrue);
      expect(notifier.state.isEnabled, isTrue);
    });

    test('toggleSound disables sound', () async {
      await notifier.toggleSound();
      expect(notifier.state.soundEnabled, isFalse);
      expect(notifier.state.vibrationEnabled, isTrue);
    });

    test('isEnabled returns false when both disabled', () async {
      await notifier.toggleVibration();
      await notifier.toggleSound();
      expect(notifier.state.isEnabled, isFalse);
    });

    test('setCooldown updates cooldown seconds', () async {
      await notifier.setCooldown(30);
      expect(notifier.state.cooldownSeconds, 30);
    });

    test('persists values via SharedPreferences', () async {
      await notifier.toggleVibration();
      await notifier.setCooldown(60);
      notifier.dispose();

      // Create a new notifier — should load persisted values
      notifier = MaxHrAlertNotifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.vibrationEnabled, isFalse);
      expect(notifier.state.soundEnabled, isTrue);
      expect(notifier.state.cooldownSeconds, 60);
    });
  });
}
