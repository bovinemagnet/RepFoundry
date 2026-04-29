import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/settings/presentation/providers/show_exercise_images_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShowExerciseImagesNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default value is true when no preference is stored', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(showExerciseImagesProvider), isTrue);
    });

    test('loads stored true value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'show_exercise_images': true});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(showExerciseImagesProvider);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(showExerciseImagesProvider), isTrue);
    });

    test('loads stored false value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'show_exercise_images': false});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(showExerciseImagesProvider);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(showExerciseImagesProvider), isFalse);
    });

    test('toggle flips value from true to false and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(showExerciseImagesProvider.notifier);
      expect(container.read(showExerciseImagesProvider), isTrue);

      await notifier.toggle();
      expect(container.read(showExerciseImagesProvider), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_exercise_images'), isFalse);
    });

    test('toggle flips back to true and persists', () async {
      SharedPreferences.setMockInitialValues({'show_exercise_images': false});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for _load to complete.
      container.read(showExerciseImagesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(showExerciseImagesProvider.notifier);
      await notifier.toggle();

      expect(container.read(showExerciseImagesProvider), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_exercise_images'), isTrue);
    });
  });
}
