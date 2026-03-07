import '../presentation/controllers/heart_rate_panel_state.dart';
import 'zone_calculator.dart';

/// Summary of time spent in each heart rate zone.
class TimeInZoneSummary {
  /// Duration spent in each zone, keyed by zone number (1–5).
  final Map<int, Duration> zoneTime;

  /// Total time at moderate intensity or higher (zones 3+).
  final Duration moderateOrHigher;

  /// Heart rate drop from peak to 60 seconds after stopping, if available.
  final int? recoveryHrDrop;

  const TimeInZoneSummary({
    required this.zoneTime,
    required this.moderateOrHigher,
    this.recoveryHrDrop,
  });
}

/// Calculates how long the user spent in each zone.
///
/// Each reading is assumed to represent a 1-second interval up to the next
/// reading. The last reading covers no additional time.
TimeInZoneSummary calculateTimeInZones(
  List<HrReading> readings,
  ZoneConfiguration config,
) {
  final zoneTime = <int, Duration>{};
  for (final zone in config.zones) {
    zoneTime[zone.zoneNumber] = Duration.zero;
  }

  if (readings.length < 2) {
    return TimeInZoneSummary(
      zoneTime: zoneTime,
      moderateOrHigher: Duration.zero,
    );
  }

  for (var i = 0; i < readings.length - 1; i++) {
    final zone = currentZoneFromConfig(readings[i].bpm, config);
    if (zone != null) {
      final interval = readings[i + 1].elapsed - readings[i].elapsed;
      zoneTime[zone.zoneNumber] = zoneTime[zone.zoneNumber]! + interval;
    }
  }

  var moderateOrHigher = Duration.zero;
  for (final entry in zoneTime.entries) {
    if (entry.key >= 3) {
      moderateOrHigher += entry.value;
    }
  }

  // Recovery HR drop: difference between peak and reading ~60s after the last
  // reading (if data is available — the caller may append a post-exercise
  // reading at elapsed + 60s).
  int? recoveryDrop;
  if (readings.length >= 2) {
    final peakBpm = readings.map((r) => r.bpm).reduce((a, b) => a > b ? a : b);
    final lastReading = readings.last;
    final exerciseEnd = readings[readings.length - 2].elapsed;
    final gap = lastReading.elapsed - exerciseEnd;
    if (gap.inSeconds >= 55) {
      recoveryDrop = peakBpm - lastReading.bpm;
    }
  }

  return TimeInZoneSummary(
    zoneTime: zoneTime,
    moderateOrHigher: moderateOrHigher,
    recoveryHrDrop: recoveryDrop,
  );
}
