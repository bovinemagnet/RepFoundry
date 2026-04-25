import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';

void main() {
  group('calculateZones (via HeartRateZoneLegend prerequisites)', () {
    test('age 30 → Tanaka max 187, 5 zones', () {
      const profile = HealthProfile(age: 30);
      final config = calculateZones(profile)!;

      expect(config.zones, hasLength(5));
      expect(config.maxHr, 187);
    });

    test('age 45 → Tanaka max 177', () {
      const profile = HealthProfile(age: 45);
      final config = calculateZones(profile)!;

      expect(config.maxHr, 177);
    });

    test('age 20 → Tanaka max 194', () {
      const profile = HealthProfile(age: 20);
      final config = calculateZones(profile)!;

      expect(config.maxHr, 194);
    });

    test('Fox 220 opt-in is still available', () {
      const profile = HealthProfile(age: 30, maxHrFormula: MaxHrFormula.fox220);
      final config = calculateZones(profile)!;
      expect(config.maxHr, 190);
    });
  });

  group('currentZoneFromConfig', () {
    final config = calculateZones(const HealthProfile(age: 30))!;
    // Tanaka max = 187. Zone bands: Z1 50-60% (94-112), Z3 70-80% (131-150),
    // Z4 80-90% (150-168), Z5 90-100% (168-187).

    test('returns zone 1 for low HR within training range', () {
      final zone = currentZoneFromConfig(100, config);
      expect(zone?.zoneNumber, 1);
    });

    test('returns zone 3 at 70-80% max HR', () {
      final zone = currentZoneFromConfig(140, config);
      expect(zone?.zoneNumber, 3);
    });

    test('returns zone 4 at 80-90% max HR', () {
      final zone = currentZoneFromConfig(160, config);
      expect(zone?.zoneNumber, 4);
    });

    test('returns zone 5 at 90-100% max HR', () {
      final zone = currentZoneFromConfig(175, config);
      expect(zone?.zoneNumber, 5);
    });

    test('returns null for very low bpm', () {
      final zone = currentZoneFromConfig(40, config);
      expect(zone, isNull);
    });
  });

  group('CalculatedZone', () {
    test('zone 3 BPM ranges calculated correctly for age 30 (Tanaka)', () {
      final config = calculateZones(const HealthProfile(age: 30))!;
      final zone3 = config.zones[2];
      expect(zone3.zoneNumber, 3);
      // 70% of 187 = 130.9 → 131
      expect(zone3.lowerBound, 131);
      // 80% of 187 = 149.6 → 150
      expect(zone3.upperBound, 150);
    });

    test('dual labels are populated', () {
      final config = calculateZones(const HealthProfile(age: 30))!;
      expect(config.zones[0].displayLabel, 'Easy (Recovery)');
      expect(config.zones[2].displayLabel, 'Moderate (Aerobic)');
    });

    test('zone 5 has nullable upperBound', () {
      final config = calculateZones(const HealthProfile(age: 30))!;
      expect(config.zones[4].upperBound, isNull);
    });
  });
}
