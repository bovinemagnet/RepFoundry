import 'package:flutter/material.dart';

/// Heart rate training zones based on maximum heart rate (220 - age).
class HeartRateZone {
  final String name;
  final double minPercent;
  final double maxPercent;
  final Color colour;

  const HeartRateZone({
    required this.name,
    required this.minPercent,
    required this.maxPercent,
    required this.colour,
  });

  int minBpm(int maxHr) => (maxHr * minPercent).round();
  int maxBpm(int maxHr) => (maxHr * maxPercent).round();
}

const heartRateZones = [
  HeartRateZone(
    name: 'Rest',
    minPercent: 0.0,
    maxPercent: 0.50,
    colour: Color(0xFF90CAF9), // light blue
  ),
  HeartRateZone(
    name: 'Fat Burn',
    minPercent: 0.50,
    maxPercent: 0.60,
    colour: Color(0xFF66BB6A), // green
  ),
  HeartRateZone(
    name: 'Endurance',
    minPercent: 0.60,
    maxPercent: 0.70,
    colour: Color(0xFFFFEE58), // yellow
  ),
  HeartRateZone(
    name: 'Aerobic',
    minPercent: 0.70,
    maxPercent: 0.80,
    colour: Color(0xFFFFA726), // orange
  ),
  HeartRateZone(
    name: 'Anaerobic',
    minPercent: 0.80,
    maxPercent: 0.90,
    colour: Color(0xFFEF5350), // red
  ),
  HeartRateZone(
    name: 'VO2 Max',
    minPercent: 0.90,
    maxPercent: 1.00,
    colour: Color(0xFFAB47BC), // purple
  ),
];

/// Returns the zone the given [bpm] falls into, or null if below all zones.
HeartRateZone? currentZone(int bpm, int maxHr) {
  for (final zone in heartRateZones.reversed) {
    if (bpm >= zone.minBpm(maxHr)) return zone;
  }
  return null;
}

/// Maximum heart rate estimate using the standard formula.
int estimateMaxHeartRate(int age) => 220 - age;

/// Widget showing the HR zone legend with BPM ranges.
class HeartRateZoneLegend extends StatelessWidget {
  const HeartRateZoneLegend({
    super.key,
    required this.maxHr,
    this.currentBpm,
  });

  final int maxHr;
  final int? currentBpm;

  @override
  Widget build(BuildContext context) {
    final activeZone =
        currentBpm != null ? currentZone(currentBpm!, maxHr) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heart Rate Zones (max $maxHr bpm)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        // Skip the 'Rest' zone (index 0) — only show training zones.
        for (final zone in heartRateZones.skip(1))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: zone.colour,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: activeZone == zone
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                ),
                Text(
                  '${zone.minBpm(maxHr)}–${zone.maxBpm(maxHr)} bpm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: activeZone == zone
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
