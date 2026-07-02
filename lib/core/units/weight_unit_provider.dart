import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weight_unit.dart';

/// App-wide weight display unit, persisted under the `weight_unit` key.
///
/// On first launch (no persisted value) the unit defaults from the device
/// locale: US/LR/MM get lbs, everywhere else kg. An explicit user choice is
/// never overridden.
final weightUnitProvider = NotifierProvider<WeightUnitNotifier, WeightUnit>(
  WeightUnitNotifier.new,
);

class WeightUnitNotifier extends Notifier<WeightUnit> {
  @override
  WeightUnit build() {
    _load();
    return WeightUnit.kg;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('weight_unit');
    if (stored != null) {
      state = weightUnitFromStorage(stored);
    } else {
      state = defaultWeightUnitForCountry(
        ui.PlatformDispatcher.instance.locale.countryCode,
      );
    }
  }

  Future<void> set(WeightUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_unit', unit.name);
  }
}

extension WeightUnitLabel on WeightUnit {
  /// Localised suffix for this unit ("kg" / "lbs").
  String label(S s) => this == WeightUnit.kg ? s.kgUnit : s.lbsUnit;
}
