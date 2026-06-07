import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/features/settings/presentation/providers/theme_mode_provider.dart';

void main() {
  group('themeModeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to dark when no preference is stored', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('loads a stored preference', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger creation, then wait for the async _load() to complete.
      container.read(themeModeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('loads system mode', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'system'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('set updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });
  });
}
