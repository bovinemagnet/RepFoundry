import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/zone_line_gradient.dart';

const _z1 = Color(0xFF4FC3F7);
const _z2 = Color(0xFF81C784);
const _z3 = Color(0xFFFFD54F);
const _neutral = Color(0xFF888888);

/// Three contiguous zones: 100–120, 120–140, 140+ (max 180).
ZoneConfiguration _config() {
  return const ZoneConfiguration(
    zones: [
      CalculatedZone(
        zoneNumber: 1,
        label: 'Z1',
        effortLabel: 'Easy',
        descriptiveLabel: 'Recovery',
        lowerBound: 100,
        upperBound: 120,
        color: 0xFF4FC3F7,
      ),
      CalculatedZone(
        zoneNumber: 2,
        label: 'Z2',
        effortLabel: 'Light',
        descriptiveLabel: 'Aerobic',
        lowerBound: 120,
        upperBound: 140,
        color: 0xFF81C784,
      ),
      CalculatedZone(
        zoneNumber: 3,
        label: 'Z3',
        effortLabel: 'Moderate',
        descriptiveLabel: 'Aerobic',
        lowerBound: 140,
        color: 0xFFFFD54F,
      ),
    ],
    method: ZoneMethod.percentOfEstimatedMax,
    reliability: ZoneReliability.medium,
    maxHr: 180,
    reason: 'Estimated',
  );
}

/// The gradient's colour at fraction [t] (0 = top, 1 = bottom), taking the
/// colour of the stop band that contains [t].
Color _colourAt(LinearGradient g, double t) {
  final stops = g.stops!;
  for (var i = 0; i < stops.length - 1; i++) {
    if (t >= stops[i] && t <= stops[i + 1]) return g.colors[i];
  }
  return g.colors.last;
}

void main() {
  group('zoneLineGradient', () {
    test('runs top to bottom', () {
      final g = zoneLineGradient(
        _config(),
        topBpm: 160,
        bottomBpm: 90,
        belowZonesColour: _neutral,
      );

      expect(g.begin, Alignment.topCenter);
      expect(g.end, Alignment.bottomCenter);
      expect(g.stops!.first, 0);
      expect(g.stops!.last, 1);
    });

    test('paints each BPM in its zone colour, highest zone at the top', () {
      // 160 → 90 spans 70 bpm. Thresholds: 140 at 20/70, 120 at 40/70,
      // 100 at 60/70.
      final g = zoneLineGradient(
        _config(),
        topBpm: 160,
        bottomBpm: 90,
        belowZonesColour: _neutral,
      );

      expect(_colourAt(g, 0.1), _z3); // 153 bpm
      expect(_colourAt(g, 0.4), _z2); // 132 bpm
      expect(_colourAt(g, 0.7), _z1); // 111 bpm
      expect(_colourAt(g, 0.95), _neutral); // 93.5 bpm, below zone 1
    });

    test('changes colour with a hard edge exactly at each threshold', () {
      final g = zoneLineGradient(
        _config(),
        topBpm: 160,
        bottomBpm: 90,
        belowZonesColour: _neutral,
      );

      expect(g.colors, [_z3, _z3, _z2, _z2, _z1, _z1, _neutral, _neutral]);
      expect(g.stops, [
        0,
        closeTo(20 / 70, 1e-9),
        closeTo(20 / 70, 1e-9),
        closeTo(40 / 70, 1e-9),
        closeTo(40 / 70, 1e-9),
        closeTo(60 / 70, 1e-9),
        closeTo(60 / 70, 1e-9),
        1,
      ]);
    });

    test('only includes zones inside the BPM range', () {
      final g = zoneLineGradient(
        _config(),
        topBpm: 135,
        bottomBpm: 125,
        belowZonesColour: _neutral,
      );

      expect(g.colors, [_z2, _z2]);
      expect(g.stops, [0, 1]);
    });

    test('a flat range is a single colour for the zone of that BPM', () {
      final g = zoneLineGradient(
        _config(),
        topBpm: 130,
        bottomBpm: 130,
        belowZonesColour: _neutral,
      );

      expect(g.colors, [_z2, _z2]);
      expect(g.stops, [0, 1]);
    });

    test('a BPM exactly on a threshold belongs to the higher zone', () {
      final g = zoneLineGradient(
        _config(),
        topBpm: 120,
        bottomBpm: 120,
        belowZonesColour: _neutral,
      );

      expect(g.colors.first, _z2);
    });

    test('gaps between custom zones are painted in the neutral colour', () {
      const gapped = ZoneConfiguration(
        zones: [
          CalculatedZone(
            zoneNumber: 1,
            label: 'Z1',
            effortLabel: 'Easy',
            descriptiveLabel: 'Custom',
            lowerBound: 100,
            upperBound: 110,
            color: 0xFF4FC3F7,
          ),
          CalculatedZone(
            zoneNumber: 2,
            label: 'Z2',
            effortLabel: 'Light',
            descriptiveLabel: 'Custom',
            lowerBound: 120,
            color: 0xFF81C784,
          ),
        ],
        method: ZoneMethod.custom,
        reliability: ZoneReliability.high,
        maxHr: 180,
        reason: 'Custom',
      );

      final g = zoneLineGradient(
        gapped,
        topBpm: 130,
        bottomBpm: 100,
        belowZonesColour: _neutral,
      );

      expect(g.colors, [_z2, _z2, _neutral, _neutral, _z1, _z1]);
    });

    test('opacity scales every colour', () {
      final g = zoneLineGradient(
        _config(),
        topBpm: 135,
        bottomBpm: 125,
        belowZonesColour: _neutral,
        opacity: 0.2,
      );

      for (final c in g.colors) {
        expect(c.a, closeTo(0.2, 1e-6));
        expect(c.withValues(alpha: 1), _z2);
      }
    });

    test('fade takes opacity to zero at the bottom', () {
      final g = zoneLineGradient(
        _config(),
        topBpm: 160,
        bottomBpm: 90,
        belowZonesColour: _neutral,
        opacity: 0.5,
        fade: true,
      );

      expect(g.colors.first.a, closeTo(0.5, 1e-6));
      expect(g.colors.last.a, closeTo(0, 1e-6));
      // Midway down, at the 140 bpm threshold (20/70), half-way-ish faded.
      expect(g.colors[1].a, closeTo(0.5 * (1 - 20 / 70), 1e-6));
      // Hue still follows the zone.
      expect(g.colors[2].withValues(alpha: 1), _z2);
    });
  });
}
