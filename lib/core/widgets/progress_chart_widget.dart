import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A themed line chart showing progression over time using [fl_chart].
///
/// Displays date on the x-axis and a numeric value on the y-axis,
/// with touch tooltips and animated drawing.
class ProgressChartWidget extends StatelessWidget {
  const ProgressChartWidget({
    super.key,
    required this.dataPoints,
    required this.label,
  });

  final List<ProgressDataPoint> dataPoints;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final gridColor = theme.colorScheme.surfaceContainerHighest;
    final textColor = theme.colorScheme.onSurfaceVariant;

    final spots = <FlSpot>[];
    for (var i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i].value));
    }

    final values = dataPoints.map((d) => d.value);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;
    final yPadding = yRange == 0 ? 10.0 : yRange * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yRange == 0 ? 5 : null,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: gridColor,
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
                    interval: _bottomInterval(dataPoints.length),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= dataPoints.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat.MMMd()
                              .format(dataPoints[idx].date.toLocal()),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(color: textColor, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: minY - yPadding,
              maxY: maxY + yPadding,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final idx = spot.x.toInt();
                      final date = idx >= 0 && idx < dataPoints.length
                          ? DateFormat.yMMMd()
                              .format(dataPoints[idx].date.toLocal())
                          : '';
                      return LineTooltipItem(
                        '$date\n${spot.y.toStringAsFixed(1)}',
                        TextStyle(
                          color: primaryColor,
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
                  curveSmoothness: 0.2,
                  color: primaryColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: dataPoints.length <= 20,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 2.5,
                      color: primaryColor,
                      strokeColor: primaryColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }

  double _bottomInterval(int count) {
    if (count <= 5) return 1;
    if (count <= 15) return 3;
    if (count <= 30) return 5;
    return (count / 6).ceilToDouble();
  }
}

/// A single data point for [ProgressChartWidget].
class ProgressDataPoint {
  final DateTime date;
  final double value;

  const ProgressDataPoint({required this.date, required this.value});
}
