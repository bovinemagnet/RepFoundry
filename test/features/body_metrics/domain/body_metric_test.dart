import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';

void main() {
  group('BodyMetric', () {
    test('create generates a unique id and UTC date', () {
      final metric = BodyMetric.create(weight: 80.5);

      expect(metric.id, isNotEmpty);
      expect(metric.weight, 80.5);
      expect(metric.date.isUtc, isTrue);
      expect(metric.bodyFatPercent, isNull);
      expect(metric.notes, isNull);
    });

    test('create with all fields', () {
      final metric = BodyMetric.create(
        weight: 75.0,
        bodyFatPercent: 15.5,
        notes: 'Morning measurement',
      );

      expect(metric.weight, 75.0);
      expect(metric.bodyFatPercent, 15.5);
      expect(metric.notes, 'Morning measurement');
    });

    test('copyWith updates weight', () {
      final original = BodyMetric.create(weight: 80.0);
      final updated = original.copyWith(weight: 79.0);

      expect(updated.weight, 79.0);
      expect(updated.id, original.id);
    });

    test('equality by id', () {
      final a = BodyMetric.create(weight: 80.0);
      final b = a.copyWith(weight: 79.0);

      expect(a, equals(b));
    });
  });
}
