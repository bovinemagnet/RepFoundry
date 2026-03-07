import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/models/health_profile.dart';
import 'package:rep_foundry/features/heart_rate/domain/zone_calculator.dart';

void main() {
  group('calculateZones (via HeartRateZoneLegend prerequisites)', () {
    test('age 30 → max 190, 5 zones', () {
      const profile = HealthProfile(age: 30);
      final config = calculateZones(profile)!;

      expect(config.zones, hasLength(5));
      expect(config.zones.last.upperBpm, 190);
    });

    test('age 45 → max 175', () {
      const profile = HealthProfile(age: 45);
      final config = calculateZones(profile)!;

      expect(config.zones.last.upperBpm, 175);
    });

    test('age 20 → max 200', () {
      const profile = HealthProfile(age: 20);
      final config = calculateZones(profile)!;

      expect(config.zones.last.upperBpm, 200);
    });
  });

  group('currentZoneFromConfig', () {
    final config = calculateZones(const HealthProfile(age: 30))!;

    test('returns zone 1 for low HR within training range', () {
      // Z1: 50-60% of 190 = 95-114
      final zone = currentZoneFromConfig(100, config);
      expect(zone, isNotNull);
      expect(zone!.zoneNumber, 1);
    });

    test('returns zone 3 at 70-80% max HR', () {
      // Z3: 70-80% of 190 = 133-152
      final zone = currentZoneFromConfig(140, config);
      expect(zone, isNotNull);
      expect(zone!.zoneNumber, 3);
    });

    test('returns zone 4 at 80-90% max HR', () {
      // Z4: 80-90% of 190 = 152-171
      final zone = currentZoneFromConfig(160, config);
      expect(zone, isNotNull);
      expect(zone!.zoneNumber, 4);
    });

    test('returns zone 5 at 90-100% max HR', () {
      // Z5: 90-100% of 190 = 171-190
      final zone = currentZoneFromConfig(175, config);
      expect(zone, isNotNull);
      expect(zone!.zoneNumber, 5);
    });

    test('returns null for very low bpm', () {
      final zone = currentZoneFromConfig(40, config);
      expect(zone, isNull);
    });
  });

  group('CalculatedZone', () {
    test('zone 3 BPM ranges calculated correctly for age 30', () {
      final config = calculateZones(const HealthProfile(age: 30))!;
      final zone3 = config.zones[2];
      expect(zone3.zoneNumber, 3);
      expect(zone3.lowerBpm, 133);
      expect(zone3.upperBpm, 152);
    });

    test('zones have dual display labels', () {
      final config = calculateZones(const HealthProfile(age: 30))!;
      expect(config.zones[0].displayLabel, 'Easy (Recovery)');
      expect(config.zones[2].displayLabel, 'Moderate (Aerobic)');
    });
  });
}
