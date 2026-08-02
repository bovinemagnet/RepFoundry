import 'package:hr_zones/hr_zones.dart';

/// The zone containing [bpm], or null when the reading sits below zone 1.
///
/// Bounds follow the package's convention: `lowerBound` inclusive,
/// `upperBound` exclusive. The top zone has a null `upperBound` and absorbs
/// everything above it — a reading past the configured maximum is still "in"
/// the top zone, and the above-cap warning is what handles that case.
int? zoneNumberFor(ZoneConfiguration config, int bpm) {
  for (final zone in config.zones) {
    if (bpm < zone.lowerBound) continue;
    final upper = zone.upperBound;
    if (upper == null || bpm < upper) return zone.zoneNumber;
  }
  return bpm >= config.zones.first.lowerBound
      ? config.zones.last.zoneNumber
      : null;
}
