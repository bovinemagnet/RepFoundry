import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/features/settings/presentation/providers/plate_settings_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<PlateSettings> loaded(ProviderContainer container) async {
    container.read(plateSettingsProvider);
    // Wait for the async _load() to complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return container.read(plateSettingsProvider);
  }

  test('defaults to a standard bar and every plate size, per unit', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = await loaded(container);

    expect(settings.forUnit(WeightUnit.kg).bar, 20);
    expect(settings.forUnit(WeightUnit.kg).plates, kgPlateSizes.toSet());
    expect(settings.forUnit(WeightUnit.lbs).bar, 45);
    expect(settings.forUnit(WeightUnit.lbs).plates, lbsPlateSizes.toSet());
  });

  test('loads saved values', () async {
    SharedPreferences.setMockInitialValues({
      'plate_bar_kg': 15.0,
      'plate_sizes_kg': ['20', '1.25'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final kg = (await loaded(container)).forUnit(WeightUnit.kg);

    expect(kg.bar, 15);
    expect(kg.plates, {20.0, 1.25});
  });

  test('setBar changes only that unit and persists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await loaded(container);

    await container
        .read(plateSettingsProvider.notifier)
        .setBar(WeightUnit.lbs, 35);

    final settings = container.read(plateSettingsProvider);
    expect(settings.forUnit(WeightUnit.lbs).bar, 35);
    expect(settings.forUnit(WeightUnit.kg).bar, 20);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('plate_bar_lbs'), 35);
  });

  test('togglePlate removes and restores a size, surviving a reload', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await loaded(container);
    final notifier = container.read(plateSettingsProvider.notifier);

    await notifier.togglePlate(WeightUnit.kg, 25);
    expect(
      container.read(plateSettingsProvider).forUnit(WeightUnit.kg).plates,
      isNot(contains(25.0)),
    );

    final reloaded = ProviderContainer();
    addTearDown(reloaded.dispose);
    final kg = (await loaded(reloaded)).forUnit(WeightUnit.kg);
    expect(kg.plates, isNot(contains(25.0)));
    expect(kg.plates, contains(20.0));

    await notifier.togglePlate(WeightUnit.kg, 25);
    expect(
      container.read(plateSettingsProvider).forUnit(WeightUnit.kg).plates,
      contains(25.0),
    );
  });

  test('ensureLoaded resolves once the saved setup is in place', () async {
    SharedPreferences.setMockInitialValues({'plate_bar_kg': 15.0});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(plateSettingsProvider.notifier).ensureLoaded();

    expect(
      container.read(plateSettingsProvider).forUnit(WeightUnit.kg).bar,
      15,
    );
  });
}
