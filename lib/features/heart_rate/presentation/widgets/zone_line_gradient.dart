import 'package:flutter/material.dart';
import 'package:hr_zones/hr_zones.dart';

/// A vertical gradient that paints every BPM in the colour of its training
/// zone, changing colour with a hard edge at each zone threshold (#131).
///
/// The gradient runs from [topBpm] at the top of the painted rect to
/// [bottomBpm] at the bottom, so apply it over a rect whose top edge sits at
/// [topBpm] and bottom edge at [bottomBpm]. BPMs outside every zone (below
/// zone 1, or in a gap between custom zones) take [belowZonesColour].
///
/// Every colour is scaled by [opacity]. With [fade], the opacity also falls
/// linearly to zero at the bottom, as an area fill does.
LinearGradient zoneLineGradient(
  ZoneConfiguration config, {
  required double topBpm,
  required double bottomBpm,
  required Color belowZonesColour,
  double opacity = 1,
  bool fade = false,
}) {
  Color colourAt(double bpm) {
    for (final zone in config.zones) {
      final upper = zone.upperBound;
      if (bpm >= zone.lowerBound && (upper == null || bpm < upper)) {
        return Color(zone.color);
      }
    }
    return belowZonesColour;
  }

  final span = topBpm - bottomBpm;
  if (span <= 0) {
    final colour = colourAt(topBpm);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colour.withValues(alpha: colour.a * opacity),
        colour.withValues(alpha: colour.a * opacity * (fade ? 0 : 1)),
      ],
      stops: const [0, 1],
    );
  }

  // Zone edges strictly inside the range, highest first.
  final edges = <double>{
    for (final zone in config.zones) ...[
      zone.lowerBound.toDouble(),
      if (zone.upperBound != null) zone.upperBound!.toDouble(),
    ],
  }.where((bpm) => bpm > bottomBpm && bpm < topBpm).toList()
    ..sort((a, b) => b.compareTo(a));
  final breakpoints = [topBpm, ...edges, bottomBpm];

  final colors = <Color>[];
  final stops = <double>[];
  void addStop(Color colour, double bpm) {
    final t = (topBpm - bpm) / span;
    final alpha = colour.a * opacity * (fade ? 1 - t : 1);
    colors.add(colour.withValues(alpha: alpha));
    stops.add(t);
  }

  for (var i = 0; i < breakpoints.length - 1; i++) {
    final upper = breakpoints[i];
    final lower = breakpoints[i + 1];
    final colour = colourAt((upper + lower) / 2);
    addStop(colour, upper);
    addStop(colour, lower);
  }

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: colors,
    stops: stops,
  );
}
