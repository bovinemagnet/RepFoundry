import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/models/health_profile.dart';
import 'package:rep_foundry/features/heart_rate/domain/time_in_zone_calculator.dart';
import 'package:rep_foundry/features/heart_rate/domain/zone_calculator.dart';
import 'package:rep_foundry/features/heart_rate/presentation/controllers/heart_rate_panel_state.dart';

void main() {
  // Age 30 → max 190
  final config = calculateZones(const HealthProfile(age: 30))!;

  group('calculateTimeInZones', () {
    test('returns zero durations for empty readings', () {
      final summary = calculateTimeInZones([], config);
      expect(summary.zoneTime.values.every((d) => d == Duration.zero), isTrue);
      expect(summary.moderateOrHigher, Duration.zero);
    });

    test('returns zero durations for single reading', () {
      final readings = [
        const HrReading(bpm: 150, elapsed: Duration(seconds: 0)),
      ];
      final summary = calculateTimeInZones(readings, config);
      expect(summary.zoneTime.values.every((d) => d == Duration.zero), isTrue);
    });

    test('distributes time across zones correctly', () {
      // max 190; zone boundaries:
      // Z1: 95-114, Z2: 114-133, Z3: 133-152, Z4: 152-171, Z5: 171-190
      final readings = [
        const HrReading(bpm: 100, elapsed: Duration(seconds: 0)), // Z1
        const HrReading(bpm: 100, elapsed: Duration(seconds: 10)), // Z1
        const HrReading(bpm: 140, elapsed: Duration(seconds: 20)), // Z3
        const HrReading(bpm: 140, elapsed: Duration(seconds: 30)), // Z3
        const HrReading(bpm: 160, elapsed: Duration(seconds: 40)), // Z4
        const HrReading(bpm: 160, elapsed: Duration(seconds: 50)), // end
      ];

      final summary = calculateTimeInZones(readings, config);

      // Two Z1 readings covering 0-10s and 10-20s = 20s total
      expect(summary.zoneTime[1], const Duration(seconds: 20)); // Z1
      expect(summary.zoneTime[2], Duration.zero); // Z2
      expect(summary.zoneTime[3], const Duration(seconds: 20)); // Z3
      expect(summary.zoneTime[4], const Duration(seconds: 10)); // Z4
      expect(summary.zoneTime[5], Duration.zero); // Z5
    });

    test('moderateOrHigher sums zones 3+', () {
      final readings = [
        const HrReading(bpm: 140, elapsed: Duration(seconds: 0)), // Z3
        const HrReading(bpm: 160, elapsed: Duration(seconds: 10)), // Z4
        const HrReading(bpm: 160, elapsed: Duration(seconds: 20)), // end
      ];

      final summary = calculateTimeInZones(readings, config);
      expect(summary.moderateOrHigher, const Duration(seconds: 20));
    });

    test('recoveryHrDrop calculated when last gap >= 55s', () {
      final readings = [
        const HrReading(bpm: 170, elapsed: Duration(seconds: 0)),
        const HrReading(bpm: 175, elapsed: Duration(seconds: 10)),
        const HrReading(bpm: 160, elapsed: Duration(seconds: 20)),
        // 60s gap — simulates post-exercise recovery reading
        const HrReading(bpm: 120, elapsed: Duration(seconds: 80)),
      ];

      final summary = calculateTimeInZones(readings, config);
      // Peak = 175, last reading = 120, drop = 55
      expect(summary.recoveryHrDrop, 55);
    });

    test('recoveryHrDrop is null when last gap < 55s', () {
      final readings = [
        const HrReading(bpm: 170, elapsed: Duration(seconds: 0)),
        const HrReading(bpm: 160, elapsed: Duration(seconds: 10)),
        const HrReading(bpm: 150, elapsed: Duration(seconds: 15)),
      ];

      final summary = calculateTimeInZones(readings, config);
      expect(summary.recoveryHrDrop, isNull);
    });

    test('BPM below all zones does not add to any zone time', () {
      final readings = [
        const HrReading(bpm: 50, elapsed: Duration(seconds: 0)), // below Z1
        const HrReading(bpm: 50, elapsed: Duration(seconds: 10)),
      ];

      final summary = calculateTimeInZones(readings, config);
      expect(summary.zoneTime.values.every((d) => d == Duration.zero), isTrue);
    });
  });
}
