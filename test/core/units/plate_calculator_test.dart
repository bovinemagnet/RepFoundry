import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/plate_calculator.dart';

void main() {
  const kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  const lbPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

  group('platesForWeight', () {
    test('loads the largest plates first', () {
      final result = platesForWeight(target: 140, bar: 20, plates: kgPlates);

      expect(result.perSide, [
        (plate: 25.0, count: 2),
        (plate: 10.0, count: 1),
      ]);
      expect(result.loaded, 140);
      expect(result.isExact, isTrue);
    });

    test('uses only the plate sizes available', () {
      final result = platesForWeight(
        target: 100,
        bar: 20,
        plates: [15.0, 10.0, 5.0],
      );

      expect(result.perSide, [
        (plate: 15.0, count: 2),
        (plate: 10.0, count: 1),
      ]);
    });

    test('works in pounds', () {
      final result = platesForWeight(target: 225, bar: 45, plates: lbPlates);

      expect(result.perSide, [(plate: 45.0, count: 2)]);
      expect(result.isExact, isTrue);
    });

    test('accepts plates in any order', () {
      final result = platesForWeight(
        target: 70,
        bar: 20,
        plates: [5.0, 25.0, 10.0],
      );

      expect(result.perSide, [(plate: 25.0, count: 1)]);
    });

    test('reports the closest lighter load and the shortfall', () {
      final result = platesForWeight(target: 101, bar: 20, plates: kgPlates);

      expect(result.loaded, 100);
      expect(result.shortfall, 1);
      expect(result.isExact, isFalse);
    });

    test('an exact load has no shortfall', () {
      final result = platesForWeight(target: 102.5, bar: 20, plates: kgPlates);

      expect(result.shortfall, 0);
      expect(result.isExact, isTrue);
    });

    test('the empty bar needs no plates', () {
      final result = platesForWeight(target: 20, bar: 20, plates: kgPlates);

      expect(result.perSide, isEmpty);
      expect(result.isExact, isTrue);
      expect(result.isBelowBar, isFalse);
    });

    test('a target lighter than the bar is flagged', () {
      final result = platesForWeight(target: 15, bar: 20, plates: kgPlates);

      expect(result.perSide, isEmpty);
      expect(result.isBelowBar, isTrue);
      expect(result.isExact, isFalse);
      expect(result.shortfall, 0);
    });

    test('no plates at all leaves only the bar', () {
      final result = platesForWeight(target: 60, bar: 20, plates: const []);

      expect(result.perSide, isEmpty);
      expect(result.loaded, 20);
      expect(result.shortfall, 40);
    });
  });
}
