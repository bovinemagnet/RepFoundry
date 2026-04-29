import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/chart_window_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChartWindowNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default value is 60 seconds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(chartWindowProvider), 60);
    });

    test('exposes the canonical allowed values list', () {
      expect(ChartWindowNotifier.allowedValues, [30, 60, 90, 120, 300]);
    });

    test('loads a stored allowed value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'hr_chart_window_seconds': 120,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(chartWindowProvider);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(chartWindowProvider), 120);
    });

    test('ignores a stored value that is not in the allowed list', () async {
      SharedPreferences.setMockInitialValues({
        'hr_chart_window_seconds': 45,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(chartWindowProvider);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should fall back to default rather than 45.
      expect(container.read(chartWindowProvider), 60);
    });

    test('setWindow updates state and persists when value is allowed',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chartWindowProvider.notifier);
      await notifier.setWindow(300);

      expect(container.read(chartWindowProvider), 300);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('hr_chart_window_seconds'), 300);
    });

    test('setWindow is a no-op for a disallowed value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chartWindowProvider.notifier);
      await notifier.setWindow(45);

      expect(container.read(chartWindowProvider), 60);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('hr_chart_window_seconds'), isNull);
    });
  });
}
