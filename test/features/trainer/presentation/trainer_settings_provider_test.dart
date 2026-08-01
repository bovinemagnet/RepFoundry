import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('setEnabled(true) is refused without an accepted disclaimer', () async {
    // Exercises the notifier directly: the whole point of this gate is that
    // it holds independently of any UI that happens to sit in front of it,
    // so it must be provable without going through a bottom sheet.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(trainerSettingsProvider.notifier).setEnabled(true);

    expect(container.read(trainerSettingsProvider).enabled, isFalse);
  });

  test('setEnabled(true) succeeds once the disclaimer has been accepted',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(trainerSettingsProvider.notifier);
    await notifier.acceptDisclaimer();
    await notifier.setEnabled(true);

    expect(container.read(trainerSettingsProvider).enabled, isTrue);
  });

  test('revokeDisclaimer clears both disclaimerAccepted and enabled', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(trainerSettingsProvider.notifier);
    await notifier.acceptDisclaimer();
    await notifier.setEnabled(true);
    await notifier.revokeDisclaimer();

    final settings = container.read(trainerSettingsProvider);
    expect(settings.disclaimerAccepted, isFalse);
    expect(settings.enabled, isFalse);
  });

  test('a write landing before the initial load resolves is not clobbered',
      () async {
    // Regression: setEnabled/acceptDisclaimer etc. used to read and write
    // `state` without waiting for the in-flight SharedPreferences load, so a
    // write issued in the same tick as construction could be overwritten
    // once that load's `state = ...` assignment ran afterwards.
    SharedPreferences.setMockInitialValues({'trainer_countdowns': false});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(trainerSettingsProvider.notifier);
    // Fired immediately, racing the not-yet-resolved `_load()`.
    await notifier.acceptDisclaimer();

    expect(container.read(trainerSettingsProvider).disclaimerAccepted, isTrue);
    // The value the load would have applied must still land correctly.
    expect(container.read(trainerSettingsProvider).countdownsEnabled, isFalse);
  });
}
