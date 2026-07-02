/// Weight display units.
///
/// All weights are stored in kg (domain models, Drift, sync snapshots);
/// conversion to/from lbs happens only at the presentation boundary.
enum WeightUnit { kg, lbs }

/// 1 kg = 2.20462 lbs.
const double lbsPerKg = 2.20462;

/// Countries that customarily use pounds for body/lifting weight.
const Set<String> _poundCountries = {'US', 'LR', 'MM'};

/// First-launch default for a device locale country code.
WeightUnit defaultWeightUnitForCountry(String? countryCode) =>
    _poundCountries.contains(countryCode?.toUpperCase())
        ? WeightUnit.lbs
        : WeightUnit.kg;

/// Parses the persisted `weight_unit` preference value.
WeightUnit weightUnitFromStorage(String? value) =>
    value == 'lbs' ? WeightUnit.lbs : WeightUnit.kg;

extension WeightUnitConversion on WeightUnit {
  /// Converts a stored kg value into this display unit.
  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg * lbsPerKg;

  /// Converts a value entered in this unit back to kg for storage.
  double toKg(double value) => this == WeightUnit.kg ? value : value / lbsPerKg;

  /// Formats a stored kg value in this unit, trimming to at most 1 dp.
  String formatFromKg(double kg) {
    final value = fromKg(kg);
    final oneDp = double.parse(value.toStringAsFixed(1));
    return oneDp == oneDp.truncateToDouble()
        ? oneDp.toInt().toString()
        : oneDp.toStringAsFixed(1);
  }
}
