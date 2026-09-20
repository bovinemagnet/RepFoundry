import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../cardio/domain/models/cardio_track_point.dart';

/// Projects a GPS track into [size] (minus [padding] on every side),
/// preserving the shape: longitude is scaled by cos(latitude) so a route
/// is not squashed east–west, and the track is fitted to the box on its
/// longer axis and centred on the other. Latitude increases upwards.
List<Offset> projectTrack(
  List<CardioTrackPoint> points,
  Size size, {
  double padding = 12,
}) {
  if (points.isEmpty) return const [];
  final box = Size(size.width - 2 * padding, size.height - 2 * padding);
  final midLat =
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  final cosLat = math.cos(midLat * math.pi / 180);

  final xs = points.map((p) => p.longitude * cosLat).toList();
  final ys = points.map((p) => p.latitude).toList();
  final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
  final spanX = maxX - minX, spanY = maxY - minY;
  if (spanX == 0 && spanY == 0) {
    return [Offset(size.width / 2, size.height / 2)];
  }
  final scale = math.min(
    spanX == 0 ? double.infinity : box.width / spanX,
    spanY == 0 ? double.infinity : box.height / spanY,
  );
  final drawnW = spanX * scale, drawnH = spanY * scale;
  final left = padding + (box.width - drawnW) / 2;
  final top = padding + (box.height - drawnH) / 2;

  return [
    for (var i = 0; i < points.length; i++)
      Offset(
        left + (xs[i] - minX) * scale,
        top + (maxY - ys[i]) * scale,
      ),
  ];
}

/// The recorded route drawn as a line on a dark tile, with start and end
/// markers — a map-free sketch of where the session went.
class CardioRouteSketch extends StatelessWidget {
  const CardioRouteSketch({super.key, required this.points, this.height = 180});

  final List<CardioTrackPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        color: cs.surfaceContainerLow,
        child: CustomPaint(
          painter: _RoutePainter(
            points: points,
            line: cs.primary,
            halo: cs.primaryContainer,
            grid: cs.surfaceContainer,
            marker: cs.surface,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.points,
    required this.line,
    required this.halo,
    required this.grid,
    required this.marker,
  });

  final List<CardioTrackPoint> points;
  final Color line;
  final Color halo;
  final Color grid;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var x = 40.0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 40.0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final offsets = projectTrack(points, size);
    if (offsets.isEmpty) return;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = halo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(offsets.first, 6, Paint()..color = marker);
    canvas.drawCircle(
      offsets.first,
      6,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(offsets.last, 6, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.points != points || old.line != line;
}
