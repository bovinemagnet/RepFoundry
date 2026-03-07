import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/zone_calculator.dart';
import '../controllers/heart_rate_panel_state.dart';

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
  });

  final List<HrReading> readings;

  /// If provided, coloured horizontal bands are drawn for each zone.
  final ZoneConfiguration? zoneConfig;

  /// If set, only show the last N seconds of readings.
  final int? windowSeconds;

  /// Whether to show coloured zone bands. When false, only threshold lines
  /// are drawn (useful for colour-sensitive users).
  final bool showZoneBands;

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
    final chartMaxHr = zoneConfig?.zones.isNotEmpty == true
        ? zoneConfig!.zones.last.upperBpm
        : null;
    final chartMinY = (minBpm - yPadding).clamp(0, double.infinity).toDouble();
    final chartMaxY = chartMaxHr != null
        ? (maxBpm + yPadding).clamp(0, chartMaxHr.toDouble()).toDouble()
        : (maxBpm + yPadding);

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
              color: errorColour,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: errorColour.withValues(alpha: 0.1),
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
      final y = zone.lowerBpm.toDouble();
      if (y > chartMinY && y < chartMaxY) {
        lines.add(
          HorizontalLine(
            y: y,
            color: Color(zone.colourValue).withValues(alpha: 0.6),
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
              labelResolver: (_) =>
                  '${zone.lowerPercent > 0 ? '${(zone.lowerPercent * 100).round()}%' : ''} ${zone.lowerBpm}',
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
      final from = zone.lowerBpm.toDouble().clamp(chartMinY, chartMaxY);
      final to = zone.upperBpm.toDouble().clamp(chartMinY, chartMaxY);
      if (to > from) {
        annotations.add(
          HorizontalRangeAnnotation(
            y1: from,
            y2: to,
            color: Color(zone.colourValue).withValues(alpha: 0.15),
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
