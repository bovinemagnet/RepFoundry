import 'dart:math';

import 'package:flutter/material.dart';

/// A lightweight sparkline chart using [CustomPainter].
///
/// Draws a polyline scaled to the widget bounds with optional gradient fill.
/// Handles edge cases: empty data renders nothing, a single point renders a dot.
///
/// [lineGradient] and [fillGradient], when given, are painted over the whole
/// widget, whose top edge is the highest value in [data] and bottom edge the
/// lowest. They replace [lineColor] and the faded [fillColor] respectively.
class SparklineWidget extends StatelessWidget {
  const SparklineWidget({
    super.key,
    required this.data,
    this.lineColor,
    this.fillColor,
    this.lineGradient,
    this.fillGradient,
    this.strokeWidth = 1.5,
  });

  final List<double> data;
  final Color? lineColor;
  final Color? fillColor;
  final Gradient? lineGradient;
  final Gradient? fillGradient;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final effectiveLineColor =
        lineColor ?? Theme.of(context).colorScheme.primary;
    final effectiveFillColor =
        fillColor ?? effectiveLineColor.withValues(alpha: 0.15);

    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        lineColor: effectiveLineColor,
        fillColor: effectiveFillColor,
        lineGradient: lineGradient,
        fillGradient: fillGradient,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.lineGradient,
    required this.fillGradient,
    required this.strokeWidth,
  });

  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final Gradient? lineGradient;
  final Gradient? fillGradient;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final bounds = Offset.zero & size;

    if (data.length == 1) {
      final paint = Paint()
        ..color = lineColor
        ..shader = lineGradient?.createShader(bounds)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        strokeWidth * 1.5,
        paint,
      );
      return;
    }

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal;

    double normalise(double v) {
      if (range == 0) return 0.5;
      return (v - minVal) / range;
    }

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (normalise(data[i]) * size.height);
      points.add(Offset(x, y));
    }

    // Draw gradient fill below the line.
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = (fillGradient ??
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fillColor, fillColor.withValues(alpha: 0.0)],
              ))
          .createShader(bounds);
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line.
    final linePaint = Paint()
      ..color = lineColor
      ..shader = lineGradient?.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.lineGradient != lineGradient ||
        oldDelegate.fillGradient != fillGradient ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
