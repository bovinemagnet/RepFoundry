import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/heart_rate_zones.dart';

void main() {
  group('estimateMaxHeartRate', () {
    test('returns 220 minus age', () {
      expect(estimateMaxHeartRate(30), 190);
      expect(estimateMaxHeartRate(45), 175);
      expect(estimateMaxHeartRate(20), 200);
    });
  });

  group('currentZone', () {
    test('returns Rest zone for low HR', () {
      final zone = currentZone(80, 190);
      expect(zone, isNotNull);
      expect(zone!.name, 'Rest');
    });

    test('returns Fat Burn zone at 50-60% max HR', () {
      // 50% of 190 = 95, 60% of 190 = 114
      final zone = currentZone(100, 190);
      expect(zone, isNotNull);
      expect(zone!.name, 'Fat Burn');
    });

    test('returns Aerobic zone at 70-80% max HR', () {
      // 70% of 190 = 133, 80% of 190 = 152
      final zone = currentZone(140, 190);
      expect(zone, isNotNull);
      expect(zone!.name, 'Aerobic');
    });

    test('returns Anaerobic zone at 80-90% max HR', () {
      // 80% of 190 = 152, 90% of 190 = 171
      final zone = currentZone(160, 190);
      expect(zone, isNotNull);
      expect(zone!.name, 'Anaerobic');
    });

    test('returns VO2 Max zone at 90-100% max HR', () {
      // 90% of 190 = 171
      final zone = currentZone(175, 190);
      expect(zone, isNotNull);
      expect(zone!.name, 'VO2 Max');
    });

    test('returns Rest zone for 0 bpm', () {
      final zone = currentZone(0, 190);
      expect(zone, isNotNull);
      expect(zone!.name, 'Rest');
    });
  });

  group('HeartRateZone', () {
    test('minBpm and maxBpm calculate correctly', () {
      // Aerobic zone: 70-80%
      final aerobic = heartRateZones[3];
      expect(aerobic.name, 'Aerobic');
      expect(aerobic.minBpm(190), 133);
      expect(aerobic.maxBpm(190), 152);
    });
  });
}
