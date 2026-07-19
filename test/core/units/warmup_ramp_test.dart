import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/warmup_ramp.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';

void main() {
  group('warmupRamp — barbell, kg', () {
    test('produces the default bar/40/60/80 ramp', () {
      final ramp = warmupRamp(
        workingKg: 100,
        equipment: EquipmentType.barbell,
        unit: WeightUnit.kg,
      );

      expect(ramp.map((s) => (s.weightKg, s.reps, s.isBarOnly)), [
        (20.0, 10, true), // empty bar
        (40.0, 5, false),
        (60.0, 3, false),
        (80.0, 1, false),
      ]);
    });

    test('rounds percentage steps to the nearest 2.5 kg', () {
      // 40% of 85 = 34 -> 35 (nearest 2.5); 60% = 51 -> 50; 80% = 68 -> 67.5
      final ramp = warmupRamp(
        workingKg: 85,
        equipment: EquipmentType.barbell,
        unit: WeightUnit.kg,
      );
      final weights = ramp.map((s) => s.weightKg).toList();
      expect(weights.first, 20.0);
      expect(weights[1], 35.0);
      expect(weights[2], 50.0);
      expect(weights[3], 67.5);
    });

    test('collapses steps at or below the bar', () {
      // Working weight 30 kg: 40% = 12, 60% = 18, both below the 20 kg bar;
      // 80% = 24 -> nearest 2.5 = 25. Only the bar and the 25 kg step remain.
      final ramp = warmupRamp(
        workingKg: 30,
        equipment: EquipmentType.barbell,
        unit: WeightUnit.kg,
      );
      expect(ramp.map((s) => s.weightKg), [20.0, 25.0]);
    });

    test('de-duplicates consecutive equal weights', () {
      // Working weight 25 kg: only the bar (20) survives collapsing; 80% = 20
      // would duplicate the bar and is dropped.
      final ramp = warmupRamp(
        workingKg: 25,
        equipment: EquipmentType.barbell,
        unit: WeightUnit.kg,
      );
      expect(ramp.map((s) => s.weightKg), [20.0]);
    });
  });

  group('warmupRamp — barbell, lbs', () {
    test('uses a 45 lb bar and rounds to 5 lb steps', () {
      // 100 kg working. In lbs: working ≈ 220.5 lb.
      // 40% ≈ 88.2 -> 90; 60% ≈ 132.3 -> 130; 80% ≈ 176.4 -> 175.
      final ramp = warmupRamp(
        workingKg: 100,
        equipment: EquipmentType.barbell,
        unit: WeightUnit.lbs,
      );

      double lbs(double kg) => kg * lbsPerKg;
      final lbsWeights =
          ramp.map((s) => double.parse(lbs(s.weightKg).toStringAsFixed(1)));

      expect(lbsWeights.first, closeTo(45.0, 0.2)); // 45 lb bar
      expect(lbsWeights.elementAt(1), closeTo(90.0, 0.2));
      expect(lbsWeights.elementAt(2), closeTo(130.0, 0.2));
      expect(lbsWeights.elementAt(3), closeTo(175.0, 0.2));
    });
  });

  group('warmupRamp — non-barbell loadable equipment', () {
    test('dumbbell drops the empty-bar step and starts at 40%', () {
      final ramp = warmupRamp(
        workingKg: 100,
        equipment: EquipmentType.dumbbell,
        unit: WeightUnit.kg,
      );
      expect(ramp.any((s) => s.isBarOnly), isFalse);
      expect(ramp.map((s) => (s.weightKg, s.reps)), [
        (40.0, 5),
        (60.0, 3),
        (80.0, 1),
      ]);
    });

    test('cable and machine are also loadable', () {
      for (final eq in [
        EquipmentType.cable,
        EquipmentType.machine,
        EquipmentType.kettlebell
      ]) {
        final ramp =
            warmupRamp(workingKg: 100, equipment: eq, unit: WeightUnit.kg);
        expect(ramp, isNotEmpty, reason: '$eq should ramp');
        expect(ramp.every((s) => !s.isBarOnly), isTrue);
      }
    });
  });

  group('warmupRamp — no ramp', () {
    test('non-loadable equipment yields an empty ramp', () {
      for (final eq in [
        EquipmentType.bodyweight,
        EquipmentType.cardioMachine,
        EquipmentType.resistanceBand,
        EquipmentType.other,
      ]) {
        expect(
          warmupRamp(workingKg: 100, equipment: eq, unit: WeightUnit.kg),
          isEmpty,
          reason: '$eq should not ramp',
        );
      }
    });

    test('zero or negative working weight yields an empty ramp', () {
      expect(
        warmupRamp(
            workingKg: 0,
            equipment: EquipmentType.barbell,
            unit: WeightUnit.kg),
        isEmpty,
      );
      expect(
        warmupRamp(
            workingKg: -20,
            equipment: EquipmentType.barbell,
            unit: WeightUnit.kg),
        isEmpty,
      );
    });
  });
}
