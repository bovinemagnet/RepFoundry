import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/units/weight_unit.dart';

/// Plate sizes offered for each unit, heaviest first.
const List<double> kgPlateSizes = [25, 20, 15, 10, 5, 2.5, 1.25];
const List<double> lbsPlateSizes = [45, 35, 25, 10, 5, 2.5];

/// Bar weights offered for each unit; the first is the default.
const List<double> kgBarWeights = [20, 15, 10];
const List<double> lbsBarWeights = [45, 35, 25];

/// The bar and the plate sizes available, in one unit's own numbers.
class PlateSetup {
  final double bar;
  final Set<double> plates;

  const PlateSetup({required this.bar, required this.plates});
}

/// Separate setups for kg and lbs, so neither is a converted approximation of
/// the other.
class PlateSettings {
  final PlateSetup kg;
  final PlateSetup lbs;

  const PlateSettings({required this.kg, required this.lbs});

  static final defaults = PlateSettings(
    kg: PlateSetup(bar: kgBarWeights.first, plates: kgPlateSizes.toSet()),
    lbs: PlateSetup(bar: lbsBarWeights.first, plates: lbsPlateSizes.toSet()),
  );

  PlateSetup forUnit(WeightUnit unit) => unit == WeightUnit.kg ? kg : lbs;

  PlateSettings withSetup(WeightUnit unit, PlateSetup setup) =>
      unit == WeightUnit.kg
          ? PlateSettings(kg: setup, lbs: lbs)
          : PlateSettings(kg: kg, lbs: setup);
}

class PlateSettingsNotifier extends Notifier<PlateSettings> {
  @override
  PlateSettings build() {
    _load();
    return PlateSettings.defaults;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    PlateSetup read(WeightUnit unit) {
      final fallback = PlateSettings.defaults.forUnit(unit);
      final sizes = prefs.getStringList(_sizesKey(unit));
      return PlateSetup(
        bar: prefs.getDouble(_barKey(unit)) ?? fallback.bar,
        plates:
            sizes == null ? fallback.plates : sizes.map(double.parse).toSet(),
      );
    }

    state = PlateSettings(kg: read(WeightUnit.kg), lbs: read(WeightUnit.lbs));
  }

  Future<void> setBar(WeightUnit unit, double bar) async {
    final setup = state.forUnit(unit);
    state = state.withSetup(unit, PlateSetup(bar: bar, plates: setup.plates));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_barKey(unit), bar);
  }

  Future<void> togglePlate(WeightUnit unit, double plate) async {
    final setup = state.forUnit(unit);
    final plates = {...setup.plates};
    if (!plates.remove(plate)) plates.add(plate);
    state = state.withSetup(unit, PlateSetup(bar: setup.bar, plates: plates));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _sizesKey(unit),
      plates.map((p) => p.toString()).toList(),
    );
  }

  static String _barKey(WeightUnit unit) => 'plate_bar_${unit.name}';
  static String _sizesKey(WeightUnit unit) => 'plate_sizes_${unit.name}';
}

final plateSettingsProvider =
    NotifierProvider<PlateSettingsNotifier, PlateSettings>(
  PlateSettingsNotifier.new,
);
