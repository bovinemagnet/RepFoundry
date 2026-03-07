import 'models/health_profile.dart';

/// The method used to calculate heart rate zones.
enum ZoneMethod {
  custom,
  clinicianCap,
  hrr,
  percentOfMeasuredMax,
  percentOfEstimatedMax,
}

/// Confidence level in the zone calculation.
enum ZoneReliability { high, medium, low }

/// A single calculated heart rate training zone.
class CalculatedZone {
  final int zoneNumber;
  final String effortLabel;
  final String descriptiveLabel;
  final int lowerBpm;
  final int upperBpm;
  final double lowerPercent;
  final double upperPercent;
  final int colourValue;

  const CalculatedZone({
    required this.zoneNumber,
    required this.effortLabel,
    required this.descriptiveLabel,
    required this.lowerBpm,
    required this.upperBpm,
    required this.lowerPercent,
    required this.upperPercent,
    required this.colourValue,
  });

  /// Combined display label, e.g. "Moderate (Aerobic)".
  String get displayLabel => '$effortLabel ($descriptiveLabel)';
}

/// The complete zone configuration result.
class ZoneConfiguration {
  final List<CalculatedZone> zones;
  final ZoneMethod activeMethod;
  final ZoneReliability reliability;
  final String reason;

  const ZoneConfiguration({
    required this.zones,
    required this.activeMethod,
    required this.reliability,
    required this.reason,
  });
}

/// Standard 5-zone percentage boundaries (of max HR or HRR).
const _zoneDefs = [
  (number: 1, lower: 0.50, upper: 0.60, effort: 'Easy', desc: 'Recovery'),
  (number: 2, lower: 0.60, upper: 0.70, effort: 'Light', desc: 'Aerobic'),
  (number: 3, lower: 0.70, upper: 0.80, effort: 'Moderate', desc: 'Aerobic'),
  (number: 4, lower: 0.80, upper: 0.90, effort: 'Hard', desc: 'Anaerobic'),
  (
    number: 5,
    lower: 0.90,
    upper: 1.00,
    effort: 'Very Hard',
    desc: 'VO\u2082 Max',
  ),
];

/// Zone colours as raw int values (no Flutter dependency).
const _zoneColours = [
  0xFF66BB6A, // Z1 — green
  0xFFFFEE58, // Z2 — yellow
  0xFFFFA726, // Z3 — orange
  0xFFEF5350, // Z4 — red
  0xFFAB47BC, // Z5 — purple
];

/// Calculates heart rate zones from the given [profile] using the highest
/// priority method available.
///
/// Priority chain:
/// 1. Custom zones → high reliability
/// 2. Clinician cap → high reliability
/// 3. Caution mode active → best available but low reliability
/// 4. Resting HR (no caution) → HRR/Karvonen, medium reliability
/// 5. Measured max → percent of measured, high reliability
/// 6. Age only → percent of estimated, medium reliability
ZoneConfiguration? calculateZones(HealthProfile profile) {
  // 1. Custom zones
  if (profile.customZones != null && profile.customZones!.isNotEmpty) {
    return _customZones(profile.customZones!);
  }

  // 2. Clinician cap
  if (profile.clinicianMaxHr != null) {
    return _percentOfMaxZones(
      maxHr: profile.clinicianMaxHr!,
      method: ZoneMethod.clinicianCap,
      reliability: ZoneReliability.high,
      reason: 'Using clinician-provided maximum heart rate',
    );
  }

  // Determine available max HR for remaining methods
  final maxHr = profile.measuredMaxHeartRate ?? profile.estimatedMaxHr;

  if (maxHr == null) return null;

  // 3. Caution mode — use best available but mark low reliability
  if (profile.isCautionMode) {
    if (profile.restingHeartRate != null) {
      return _hrrZones(
        maxHr: maxHr,
        restingHr: profile.restingHeartRate!,
        reliability: ZoneReliability.low,
        reason: _cautionReason(profile),
      );
    }
    return _percentOfMaxZones(
      maxHr: maxHr,
      method: profile.measuredMaxHeartRate != null
          ? ZoneMethod.percentOfMeasuredMax
          : ZoneMethod.percentOfEstimatedMax,
      reliability: ZoneReliability.low,
      reason: _cautionReason(profile),
    );
  }

  // 4. Resting HR available (no caution) → HRR/Karvonen
  if (profile.restingHeartRate != null) {
    return _hrrZones(
      maxHr: maxHr,
      restingHr: profile.restingHeartRate!,
      reliability: ZoneReliability.medium,
      reason: 'Using heart rate reserve (Karvonen) method',
    );
  }

  // 5. Measured max
  if (profile.measuredMaxHeartRate != null) {
    return _percentOfMaxZones(
      maxHr: profile.measuredMaxHeartRate!,
      method: ZoneMethod.percentOfMeasuredMax,
      reliability: ZoneReliability.high,
      reason: 'Using measured maximum heart rate',
    );
  }

  // 6. Age-based estimated max
  return _percentOfMaxZones(
    maxHr: maxHr,
    method: ZoneMethod.percentOfEstimatedMax,
    reliability: ZoneReliability.medium,
    reason: 'Using age-estimated maximum heart rate (220 \u2212 age)',
  );
}

/// Returns the zone the given [bpm] falls into, or null if below all zones.
CalculatedZone? currentZoneFromConfig(int bpm, ZoneConfiguration config) {
  for (final zone in config.zones.reversed) {
    if (bpm >= zone.lowerBpm) return zone;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

ZoneConfiguration _customZones(List<CustomZoneBoundary> boundaries) {
  final zones = <CalculatedZone>[];
  for (var i = 0; i < boundaries.length && i < 5; i++) {
    final b = boundaries[i];
    zones.add(CalculatedZone(
      zoneNumber: i + 1,
      effortLabel: b.label,
      descriptiveLabel: 'Custom',
      lowerBpm: b.lowerBpm,
      upperBpm: b.upperBpm,
      lowerPercent: 0,
      upperPercent: 0,
      colourValue: _zoneColours[i % _zoneColours.length],
    ));
  }
  return ZoneConfiguration(
    zones: zones,
    activeMethod: ZoneMethod.custom,
    reliability: ZoneReliability.high,
    reason: 'Using custom zone boundaries',
  );
}

ZoneConfiguration _percentOfMaxZones({
  required int maxHr,
  required ZoneMethod method,
  required ZoneReliability reliability,
  required String reason,
}) {
  final zones = <CalculatedZone>[];
  for (var i = 0; i < _zoneDefs.length; i++) {
    final def = _zoneDefs[i];
    zones.add(CalculatedZone(
      zoneNumber: def.number,
      effortLabel: def.effort,
      descriptiveLabel: def.desc,
      lowerBpm: (maxHr * def.lower).round(),
      upperBpm: (maxHr * def.upper).round(),
      lowerPercent: def.lower,
      upperPercent: def.upper,
      colourValue: _zoneColours[i],
    ));
  }
  return ZoneConfiguration(
    zones: zones,
    activeMethod: method,
    reliability: reliability,
    reason: reason,
  );
}

ZoneConfiguration _hrrZones({
  required int maxHr,
  required int restingHr,
  required ZoneReliability reliability,
  required String reason,
}) {
  final reserve = maxHr - restingHr;
  final zones = <CalculatedZone>[];
  for (var i = 0; i < _zoneDefs.length; i++) {
    final def = _zoneDefs[i];
    zones.add(CalculatedZone(
      zoneNumber: def.number,
      effortLabel: def.effort,
      descriptiveLabel: def.desc,
      lowerBpm: (restingHr + reserve * def.lower).round(),
      upperBpm: (restingHr + reserve * def.upper).round(),
      lowerPercent: def.lower,
      upperPercent: def.upper,
      colourValue: _zoneColours[i],
    ));
  }
  return ZoneConfiguration(
    zones: zones,
    activeMethod: ZoneMethod.hrr,
    reliability: reliability,
    reason: reason,
  );
}

String _cautionReason(HealthProfile profile) {
  final parts = <String>[];
  if (profile.takingBetaBlocker) parts.add('beta blocker medication');
  if (profile.hasHeartCondition) parts.add('heart condition');
  return 'Caution mode: ${parts.join(' and ')} reported. '
      'Consider setting a clinician-provided maximum heart rate.';
}
