import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_coloured_line_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ZoneColouredLineNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default value is true (line follows the zone colours)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(zoneColouredLineProvider), isTrue);
    });

    test('loads stored false value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'hr_zone_coloured_line': false});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(zoneColouredLineProvider);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(zoneColouredLineProvider), isFalse);
    });

    test('toggle flips from true to false and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(zoneColouredLineProvider.notifier);
      await notifier.toggle();

      expect(container.read(zoneColouredLineProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hr_zone_coloured_line'), isFalse);
    });

    test('toggle is reversible', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(zoneColouredLineProvider.notifier);
      await notifier.toggle();
      await notifier.toggle();

      expect(container.read(zoneColouredLineProvider), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hr_zone_coloured_line'), isTrue);
    });
  });
}
