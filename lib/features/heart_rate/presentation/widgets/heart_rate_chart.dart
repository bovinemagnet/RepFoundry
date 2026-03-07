import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../controllers/heart_rate_panel_state.dart';
import 'heart_rate_zones.dart';

/// Real-time heart rate line chart with optional HR zone bands.
class HeartRateChart extends StatelessWidget {
  const HeartRateChart({
    super.key,
    required this.readings,
    this.maxHr,
  });

  final List<HrReading> readings;

  /// If provided, coloured horizontal bands are drawn for each HR zone.
  final int? maxHr;

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

    final spots = <FlSpot>[];
    for (final r in readings) {
      spots.add(FlSpot(r.elapsed.inSeconds.toDouble(), r.bpm.toDouble()));
    }

    final bpmValues = readings.map((r) => r.bpm);
    final minBpm = bpmValues.reduce((a, b) => a < b ? a : b);
    final maxBpm = bpmValues.reduce((a, b) => a > b ? a : b);
    final range = maxBpm - minBpm;
    final yPadding = range == 0 ? 20.0 : range * 0.15;
    final chartMinY = (minBpm - yPadding).clamp(0, double.infinity).toDouble();
    final chartMaxY = maxHr != null
        ? (maxBpm + yPadding).clamp(0, maxHr!.toDouble()).toDouble()
        : (maxBpm + yPadding);

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
                interval: _xInterval(readings.last.elapsed.inSeconds),
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
          minY: chartMinY,
          maxY: chartMaxY,
          rangeAnnotations: maxHr != null
              ? RangeAnnotations(
                  horizontalRangeAnnotations: _zoneAnnotations(
                    maxHr!,
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

  List<HorizontalRangeAnnotation> _zoneAnnotations(
    int maxHr,
    double chartMinY,
    double chartMaxY,
  ) {
    final annotations = <HorizontalRangeAnnotation>[];
    // Skip the 'Rest' zone — only show training zones.
    for (final zone in heartRateZones.skip(1)) {
      final from = zone.minBpm(maxHr).toDouble().clamp(chartMinY, chartMaxY);
      final to = zone.maxBpm(maxHr).toDouble().clamp(chartMinY, chartMaxY);
      if (to > from) {
        annotations.add(
          HorizontalRangeAnnotation(
            y1: from,
            y2: to,
            color: zone.colour.withValues(alpha: 0.15),
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
