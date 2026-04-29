import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_bands_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ZoneBandsNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default value is true (zone bands shown)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(zoneBandsProvider), isTrue);
    });

    test('loads stored false value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'hr_show_zone_bands': false});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(zoneBandsProvider);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(zoneBandsProvider), isFalse);
    });

    test('toggle flips from true to false and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(zoneBandsProvider.notifier);
      await notifier.toggle();

      expect(container.read(zoneBandsProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hr_show_zone_bands'), isFalse);
    });

    test('toggle is reversible', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(zoneBandsProvider.notifier);
      await notifier.toggle();
      await notifier.toggle();

      expect(container.read(zoneBandsProvider), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hr_show_zone_bands'), isTrue);
    });
  });
}
