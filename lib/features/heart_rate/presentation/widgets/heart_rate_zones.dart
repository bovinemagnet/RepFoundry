import 'package:flutter/material.dart';

import '../../domain/zone_calculator.dart';
import 'reliability_indicator.dart';

/// Widget showing the HR zone legend with BPM ranges.
class HeartRateZoneLegend extends StatelessWidget {
  const HeartRateZoneLegend({
    super.key,
    required this.config,
    this.currentBpm,
  });

  final ZoneConfiguration config;
  final int? currentBpm;

  @override
  Widget build(BuildContext context) {
    final activeZone =
        currentBpm != null ? currentZoneFromConfig(currentBpm!, config) : null;

    final maxBpm = config.zones.isNotEmpty ? config.zones.last.upperBpm : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Heart Rate Zones (max $maxBpm bpm)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ReliabilityIndicator(config: config),
          ],
        ),
        if (config.activeMethod == ZoneMethod.clinicianCap) ...[
          const SizedBox(height: 4),
          Text(
            'Clinician-provided limits in use',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        const SizedBox(height: 8),
        for (final zone in config.zones)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(zone.colourValue),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.displayLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: activeZone?.zoneNumber == zone.zoneNumber
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                ),
                Text(
                  '${zone.lowerBpm}–${zone.upperBpm} bpm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: activeZone?.zoneNumber == zone.zoneNumber
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
