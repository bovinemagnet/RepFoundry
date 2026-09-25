import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/pyramid.dart';

void main() {
  List<double> weights(List<({double weight, int reps})> sets) =>
      sets.map((s) => s.weight).toList();

  group('pyramidSets', () {
    test('five sets, reps falling from 12 to 4', () {
      final sets = pyramidSets(top: 100, base: 20, step: 2.5, minimum: 20);

      expect(sets.map((s) => s.reps), [12, 10, 8, 6, 4]);
    });

    test('climbs to the top set in loadable barbell steps', () {
      final sets = pyramidSets(top: 100, base: 20, step: 2.5, minimum: 20);

      expect(weights(sets), [77.5, 82.5, 90, 95, 100]);
    });

    test('works in pounds', () {
      final sets = pyramidSets(top: 225, base: 45, step: 5, minimum: 45);

      expect(weights(sets), [175, 190, 200, 215, 225]);
    });

    test('dumbbell steps start from zero, never below one step', () {
      final sets = pyramidSets(top: 30, base: 0, step: 2.5, minimum: 2.5);

      expect(weights(sets), [22.5, 25, 27.5, 27.5, 30]);
    });

    test('never drops below the minimum', () {
      final sets = pyramidSets(top: 22.5, base: 20, step: 2.5, minimum: 20);

      expect(weights(sets), everyElement(greaterThanOrEqualTo(20)));
      expect(weights(sets).last, 22.5);
    });

    test('the top set is exactly the working weight', () {
      final sets = pyramidSets(top: 101, base: 20, step: 2.5, minimum: 20);

      expect(sets.last.weight, 101);
    });

    test('never climbs past the top set', () {
      // 94 % of 24 is 22.7, which rounds up to a 25 kg load.
      final sets = pyramidSets(top: 24, base: 20, step: 5, minimum: 20);

      expect(weights(sets), everyElement(lessThanOrEqualTo(24)));
    });

    test('no working weight, no pyramid', () {
      expect(pyramidSets(top: 0, base: 20, step: 2.5, minimum: 20), isEmpty);
    });
  });
}
