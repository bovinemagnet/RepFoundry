import 'dart:math';

import 'package:flutter/material.dart';

/// A vertical bar chart sparkline using [CustomPainter].
///
/// Draws normalised bars scaled to the widget bounds. The most recent bar
/// (rightmost) is rendered at full opacity with a subtle glow; older bars
/// fade progressively.
class BarSparklineWidget extends StatelessWidget {
  const BarSparklineWidget({
    super.key,
    required this.data,
    this.barColor,
    this.glowColor,
    this.barSpacing = 3.0,
  });

  final List<double> data;
  final Color? barColor;
  final Color? glowColor;
  final double barSpacing;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final effectiveBarColor = barColor ?? Theme.of(context).colorScheme.primary;
    final effectiveGlowColor =
        glowColor ?? effectiveBarColor.withValues(alpha: 0.3);

    return CustomPaint(
      painter: _BarSparklinePainter(
        data: data,
        barColor: effectiveBarColor,
        glowColor: effectiveGlowColor,
        barSpacing: barSpacing,
      ),
    );
  }
}

class _BarSparklinePainter extends CustomPainter {
  _BarSparklinePainter({
    required this.data,
    required this.barColor,
    required this.glowColor,
    required this.barSpacing,
  });

  final List<double> data;
  final Color barColor;
  final Color glowColor;
  final double barSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final count = data.length;
    final totalSpacing = barSpacing * (count - 1);
    final barWidth = (size.width - totalSpacing) / count;
    if (barWidth <= 0) return;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal;

    double normalise(double v) {
      if (range == 0) return 0.6;
      return 0.15 + 0.85 * ((v - minVal) / range);
    }

    final barRadius = Radius.circular(barWidth * 0.3);

    for (var i = 0; i < count; i++) {
      final fraction = count == 1 ? 1.0 : i / (count - 1);
      final alpha = 0.20 + 0.80 * fraction;

      final barHeight = normalise(data[i]) * size.height;
      final x = i * (barWidth + barSpacing);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: barRadius,
        topRight: barRadius,
      );

      // Glow on the last bar.
      if (i == count - 1) {
        final glowPaint = Paint()
          ..color = glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(rect, glowPaint);
      }

      final barPaint = Paint()..color = barColor.withValues(alpha: alpha);
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarSparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.barColor != barColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.barSpacing != barSpacing;
  }
}
