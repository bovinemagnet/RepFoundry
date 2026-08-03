import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/trainer/domain/hr_zone_lookup.dart';

ZoneConfiguration _config() => calculateZones(
      const HealthProfile(age: 40),
    )!;

void main() {
  group('zoneNumberFor', () {
    test('returns null below the bottom of zone 1', () {
      final config = _config();
      final belowZone1 = config.zones.first.lowerBound - 1;

      expect(zoneNumberFor(config, belowZone1), isNull);
    });

    test('returns the zone containing the reading', () {
      final config = _config();
      for (final zone in config.zones) {
        expect(zoneNumberFor(config, zone.lowerBound), zone.zoneNumber,
            reason: 'lower bound of zone ${zone.zoneNumber} is inclusive');
      }
    });

    test('an upper bound belongs to the next zone up, not its own', () {
      final config = _config();
      final zone1 = config.zones.first;

      expect(zoneNumberFor(config, zone1.upperBound!), 2);
    });

    test('readings above the top zone stay in the top zone', () {
      final config = _config();

      expect(zoneNumberFor(config, config.maxHr + 40),
          config.zones.last.zoneNumber);
    });
  });
}
