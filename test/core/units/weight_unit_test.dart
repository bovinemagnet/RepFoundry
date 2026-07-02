import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';

void main() {
  group('WeightUnit conversions', () {
    test('kg is identity in both directions', () {
      expect(WeightUnit.kg.fromKg(100), 100);
      expect(WeightUnit.kg.toKg(100), 100);
    });

    test('fromKg converts kg to lbs', () {
      expect(WeightUnit.lbs.fromKg(100), closeTo(220.462, 0.001));
    });

    test('toKg converts lbs to kg', () {
      expect(WeightUnit.lbs.toKg(220.462), closeTo(100, 0.001));
    });

    test('entered lbs value round-trips to the same display value', () {
      final storedKg = WeightUnit.lbs.toKg(220.5);
      expect(WeightUnit.lbs.formatFromKg(storedKg), '220.5');
    });
  });

  group('formatFromKg', () {
    test('trims whole numbers to no decimal places', () {
      expect(WeightUnit.kg.formatFromKg(60), '60');
    });

    test('keeps a single decimal place when needed', () {
      expect(WeightUnit.kg.formatFromKg(62.5), '62.5');
    });

    test('rounds converted values to one decimal place', () {
      // 100 kg -> 220.462 lbs -> displayed as 220.5
      expect(WeightUnit.lbs.formatFromKg(100), '220.5');
    });
  });

  group('defaultWeightUnitForCountry', () {
    test('US, LR and MM default to lbs', () {
      expect(defaultWeightUnitForCountry('US'), WeightUnit.lbs);
      expect(defaultWeightUnitForCountry('LR'), WeightUnit.lbs);
      expect(defaultWeightUnitForCountry('MM'), WeightUnit.lbs);
    });

    test('other and unknown countries default to kg', () {
      expect(defaultWeightUnitForCountry('GB'), WeightUnit.kg);
      expect(defaultWeightUnitForCountry('AU'), WeightUnit.kg);
      expect(defaultWeightUnitForCountry(null), WeightUnit.kg);
      expect(defaultWeightUnitForCountry(''), WeightUnit.kg);
    });
  });

  group('weightUnitFromStorage', () {
    test('parses stored strings, defaulting to kg', () {
      expect(weightUnitFromStorage('lbs'), WeightUnit.lbs);
      expect(weightUnitFromStorage('kg'), WeightUnit.kg);
      expect(weightUnitFromStorage(null), WeightUnit.kg);
      expect(weightUnitFromStorage('bogus'), WeightUnit.kg);
    });
  });
}
