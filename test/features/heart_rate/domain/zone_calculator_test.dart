import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/models/health_profile.dart';
import 'package:rep_foundry/features/heart_rate/domain/zone_calculator.dart';

void main() {
  group('calculateZones', () {
    test('returns null when no age or max HR data', () {
      const profile = HealthProfile();
      expect(calculateZones(profile), isNull);
    });

    test('age only → percent of estimated max, medium reliability', () {
      const profile = HealthProfile(age: 49);
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.percentOfEstimatedMax);
      expect(config.reliability, ZoneReliability.medium);
      expect(config.zones, hasLength(5));

      // PRD acceptance: age 49 → max 171
      // Z1: 50% of 171 = 86, 60% = 103
      expect(config.zones[0].lowerBpm, 86);
      expect(config.zones[0].upperBpm, 103);
    });

    test('resting HR + age → HRR/Karvonen, medium reliability', () {
      const profile = HealthProfile(age: 49, restingHeartRate: 58);
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.hrr);
      expect(config.reliability, ZoneReliability.medium);

      // PRD acceptance: max 171, reserve = 171 - 58 = 113
      // Zone 3 (70-80%): lower = 58 + 113*0.70 = 137, upper = 58 + 113*0.80 = 148
      final zone3 = config.zones[2];
      expect(zone3.zoneNumber, 3);
      expect(zone3.lowerBpm, 137);
      expect(zone3.upperBpm, 148);
    });

    test('measured max → percent of measured, high reliability', () {
      const profile = HealthProfile(age: 49, measuredMaxHeartRate: 180);
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.percentOfMeasuredMax);
      expect(config.reliability, ZoneReliability.high);
      // Z1: 50% of 180 = 90
      expect(config.zones[0].lowerBpm, 90);
    });

    test('measured max takes priority over age-based estimate', () {
      const profile = HealthProfile(age: 49, measuredMaxHeartRate: 180);
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.percentOfMeasuredMax);
      // Should use 180 not 171
      expect(config.zones[4].upperBpm, 180); // 100% of 180
    });

    test('clinician cap → high reliability, overrides everything', () {
      const profile = HealthProfile(
        age: 49,
        restingHeartRate: 58,
        measuredMaxHeartRate: 180,
        clinicianMaxHr: 150,
      );
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.clinicianCap);
      expect(config.reliability, ZoneReliability.high);
      // Should use 150 as max
      expect(config.zones[4].upperBpm, 150);
    });

    test('custom zones → high reliability, top priority', () {
      const profile = HealthProfile(
        age: 49,
        clinicianMaxHr: 150,
        customZones: [
          CustomZoneBoundary(lowerBpm: 60, upperBpm: 100, label: 'Easy'),
          CustomZoneBoundary(lowerBpm: 100, upperBpm: 140, label: 'Moderate'),
          CustomZoneBoundary(lowerBpm: 140, upperBpm: 170, label: 'Hard'),
        ],
      );
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.custom);
      expect(config.reliability, ZoneReliability.high);
      expect(config.zones, hasLength(3));
      expect(config.zones[0].effortLabel, 'Easy');
      expect(config.zones[1].lowerBpm, 100);
    });

    test('caution mode with resting HR → HRR but low reliability', () {
      const profile = HealthProfile(
        age: 49,
        restingHeartRate: 58,
        takingBetaBlocker: true,
      );
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.hrr);
      expect(config.reliability, ZoneReliability.low);
      expect(config.reason, contains('beta blocker'));
    });

    test('caution mode without resting HR → percent of max, low reliability',
        () {
      const profile = HealthProfile(
        age: 49,
        hasHeartCondition: true,
      );
      final config = calculateZones(profile)!;

      expect(config.activeMethod, ZoneMethod.percentOfEstimatedMax);
      expect(config.reliability, ZoneReliability.low);
      expect(config.reason, contains('heart condition'));
    });

    test('caution mode with both flags mentions both', () {
      const profile = HealthProfile(
        age: 49,
        takingBetaBlocker: true,
        hasHeartCondition: true,
      );
      final config = calculateZones(profile)!;

      expect(config.reason, contains('beta blocker'));
      expect(config.reason, contains('heart condition'));
    });

    test('clinician cap overrides caution mode (no low reliability)', () {
      const profile = HealthProfile(
        age: 49,
        takingBetaBlocker: true,
        clinicianMaxHr: 140,
      );
      final config = calculateZones(profile)!;

      // Clinician cap takes priority over caution mode
      expect(config.activeMethod, ZoneMethod.clinicianCap);
      expect(config.reliability, ZoneReliability.high);
    });

    test('all 5 zones have dual labels', () {
      const profile = HealthProfile(age: 30);
      final config = calculateZones(profile)!;

      expect(config.zones[0].displayLabel, 'Easy (Recovery)');
      expect(config.zones[1].displayLabel, 'Light (Aerobic)');
      expect(config.zones[2].displayLabel, 'Moderate (Aerobic)');
      expect(config.zones[3].displayLabel, 'Hard (Anaerobic)');
      expect(config.zones[4].displayLabel, contains('VO'));
    });

    test('HRR formula: restingHR + pct * (maxHR - restingHR)', () {
      const profile = HealthProfile(age: 49, restingHeartRate: 58);
      final config = calculateZones(profile)!;

      // max = 171, reserve = 113
      // 80% HRR = 58 + 0.80 * 113 = 58 + 90.4 = 148
      expect(config.zones[2].upperBpm, 148);
    });
  });

  group('currentZoneFromConfig', () {
    final config = calculateZones(const HealthProfile(age: 30))!;
    // max = 190

    test('returns null for very low BPM', () {
      expect(currentZoneFromConfig(40, config), isNull);
    });

    test('returns zone 1 at 50-60% of max', () {
      // 50% of 190 = 95
      final zone = currentZoneFromConfig(95, config);
      expect(zone, isNotNull);
      expect(zone!.zoneNumber, 1);
    });

    test('returns zone 5 at 90%+ of max', () {
      // 90% of 190 = 171
      final zone = currentZoneFromConfig(175, config);
      expect(zone, isNotNull);
      expect(zone!.zoneNumber, 5);
    });

    test('returns correct zone at boundary', () {
      // Zone 3 lower = 70% of 190 = 133
      final zone = currentZoneFromConfig(133, config);
      expect(zone, isNotNull);
      expect(zone!.zoneNumber, 3);
    });
  });
}
