import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hr_zones/hr_zones.dart';

import 'zone_line_gradient.dart';

/// Real-time heart rate line chart with optional HR zone bands.
///
/// When [windowSeconds] is provided, only the most recent N seconds of
/// readings are shown (sliding window). When null, all readings are shown.
class HeartRateChart extends StatelessWidget {
  const HeartRateChart({
    super.key,
    required this.readings,
    this.zoneConfig,
    this.windowSeconds,
    this.showZoneBands = true,
    this.zoneColouredLine = true,
  });

  final List<HrReading> readings;

  /// If provided, coloured horizontal bands are drawn for each zone.
  final ZoneConfiguration? zoneConfig;

  /// If set, only show the last N seconds of readings.
  final int? windowSeconds;

  /// Whether to show coloured zone bands. When false, only threshold lines
  /// are drawn (useful for colour-sensitive users).
  final bool showZoneBands;

  /// Whether the line (and the area under it) takes the colour of the zone
  /// each BPM falls in. Needs [zoneConfig]; otherwise the line is one colour.
  final bool zoneColouredLine;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Waiting for heart rate data...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final errorColour = theme.colorScheme.error;
    final gridColour = theme.colorScheme.surfaceContainerHighest;
    final textColour = theme.colorScheme.onSurfaceVariant;

    // Apply sliding window filter
    final displayReadings = _filterReadings();

    final spots = <FlSpot>[];
    for (final r in displayReadings) {
      spots.add(FlSpot(r.elapsed.inSeconds.toDouble(), r.bpm.toDouble()));
    }

    final bpmValues = displayReadings.map((r) => r.bpm);
    final minBpm = bpmValues.reduce((a, b) => a < b ? a : b);
    final maxBpm = bpmValues.reduce((a, b) => a > b ? a : b);
    final range = maxBpm - minBpm;
    final yPadding = range == 0 ? 20.0 : range * 0.15;
    final chartMaxHr = zoneConfig != null && zoneConfig!.zones.isNotEmpty
        ? zoneConfig!.maxHr
        : null;
    final chartMinY = (minBpm - yPadding).clamp(0, double.infinity).toDouble();
    // Cap the padded top at the zone maxHr, but never below the data itself —
    // readings can exceed the configured max (e.g. a clinician cap).
    final paddedMaxY = (maxBpm + yPadding).toDouble();
    final chartMaxY = chartMaxHr != null && chartMaxHr > maxBpm
        ? paddedMaxY.clamp(0, chartMaxHr.toDouble()).toDouble()
        : paddedMaxY;

    // The line's gradient spans the whole plot area (chartMinY..chartMaxY),
    // so its zone edges sit on the threshold lines. fl_chart paints the fill
    // from the highest reading down to the floor, so its gradient does too.
    final zoneColoured =
        zoneColouredLine && zoneConfig != null && zoneConfig!.zones.isNotEmpty;
    final neutralColour = theme.colorScheme.onSurfaceVariant;
    final lineGradient = zoneColoured
        ? zoneLineGradient(
            zoneConfig!,
            topBpm: chartMaxY,
            bottomBpm: chartMinY,
            belowZonesColour: neutralColour,
          )
        : null;
    final fillGradient = zoneColoured
        ? zoneLineGradient(
            zoneConfig!,
            topBpm: maxBpm.toDouble(),
            bottomBpm: chartMinY,
            belowZonesColour: neutralColour,
            opacity: 0.1,
          )
        : null;

    final totalSeconds = displayReadings.last.elapsed.inSeconds;
    final double? minX = windowSeconds != null && readings.length > 1
        ? (readings.last.elapsed.inSeconds - windowSeconds!)
            .toDouble()
            .clamp(0, double.infinity)
        : null;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: gridColour,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _xInterval(totalSeconds),
                getTitlesWidget: (value, meta) {
                  final secs = value.toInt();
                  final mins = secs ~/ 60;
                  final remSecs = secs % 60;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$mins:${remSecs.toString().padLeft(2, '0')}',
                      style: TextStyle(color: textColour, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: textColour, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: minX,
          minY: chartMinY,
          maxY: chartMaxY,
          extraLinesData: zoneConfig != null
              ? ExtraLinesData(
                  horizontalLines: _thresholdLines(
                    zoneConfig!,
                    chartMinY,
                    chartMaxY,
                    textColour,
                  ),
                )
              : null,
          rangeAnnotations: zoneConfig != null && showZoneBands
              ? RangeAnnotations(
                  horizontalRangeAnnotations: _zoneAnnotations(
                    zoneConfig!,
                    chartMinY,
                    chartMaxY,
                  ),
                )
              : null,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final secs = spot.x.toInt();
                  final mins = secs ~/ 60;
                  final remSecs = secs % 60;
                  return LineTooltipItem(
                    '${spot.y.toInt()} bpm\n$mins:${remSecs.toString().padLeft(2, '0')}',
                    TextStyle(
                      color: errorColour,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.15,
              color: lineGradient == null ? errorColour : null,
              gradient: lineGradient,
              gradientArea: LineChartGradientArea.wholeChart,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: fillGradient == null
                    ? errorColour.withValues(alpha: 0.1)
                    : null,
                gradient: fillGradient,
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      ),
    );
  }

  List<HrReading> _filterReadings() {
    if (windowSeconds == null || readings.length <= 1) return readings;
    final cutoff = readings.last.elapsed - Duration(seconds: windowSeconds!);
    final filtered = readings.where((r) => r.elapsed >= cutoff).toList();
    return filtered.isEmpty ? [readings.last] : filtered;
  }

  List<HorizontalLine> _thresholdLines(
    ZoneConfiguration config,
    double chartMinY,
    double chartMaxY,
    Color textColour,
  ) {
    final lines = <HorizontalLine>[];
    for (final zone in config.zones) {
      final y = zone.lowerBound.toDouble();
      if (y > chartMinY && y < chartMaxY) {
        final percent = zone.lowerPercent > 0
            ? (zone.lowerPercent * 100).round()
            : (zone.lowerBound * 100 / config.maxHr).round();
        lines.add(
          HorizontalLine(
            y: y,
            color: Color(zone.color).withValues(alpha: 0.6),
            strokeWidth: 0.8,
            dashArray: [4, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              style: TextStyle(
                color: textColour,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
              labelResolver: (_) => '$percent% ${zone.lowerBound}',
            ),
          ),
        );
      }
    }
    return lines;
  }

  List<HorizontalRangeAnnotation> _zoneAnnotations(
    ZoneConfiguration config,
    double chartMinY,
    double chartMaxY,
  ) {
    final annotations = <HorizontalRangeAnnotation>[];
    for (final zone in config.zones) {
      final from = zone.lowerBound.toDouble().clamp(chartMinY, chartMaxY);
      final to = (zone.upperBound ?? config.maxHr)
          .toDouble()
          .clamp(chartMinY, chartMaxY);
      if (to > from) {
        annotations.add(
          HorizontalRangeAnnotation(
            y1: from,
            y2: to,
            color: Color(zone.color).withValues(alpha: 0.15),
          ),
        );
      }
    }
    return annotations;
  }

  double _xInterval(int totalSeconds) {
    if (totalSeconds <= 120) return 30;
    if (totalSeconds <= 600) return 60;
    if (totalSeconds <= 1800) return 300;
    return 600;
  }
}
