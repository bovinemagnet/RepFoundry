import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rendered pixels of a widget, for asserting what was actually painted.
class PixelProbe {
  PixelProbe._(this._bytes, this.width, this.height);

  final ByteData _bytes;
  final int width;
  final int height;

  /// Captures the [RepaintBoundary] found by [finder] at a pixel ratio of 1,
  /// so probe coordinates match logical pixels.
  static Future<PixelProbe> capture(WidgetTester tester, Finder finder) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
    final probe = await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final probe = PixelProbe._(bytes!, image.width, image.height);
      image.dispose();
      return probe;
    });
    return probe!;
  }

  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      _bytes.getUint8(i + 3),
      _bytes.getUint8(i),
      _bytes.getUint8(i + 1),
      _bytes.getUint8(i + 2),
    );
  }

  /// Whether any pixel in the column at [x], between [fromY] and [toY], is
  /// close to [colour].
  bool columnContains(int x, Color colour, {int fromY = 0, int? toY}) {
    for (var y = fromY; y < (toY ?? height); y++) {
      if (isClose(at(x, y), colour)) return true;
    }
    return false;
  }

  /// Whether [a] and [b] match on each RGB channel within [tolerance].
  static bool isClose(Color a, Color b, {int tolerance = 12}) {
    int ch(double v) => (v * 255).round();
    return (ch(a.r) - ch(b.r)).abs() <= tolerance &&
        (ch(a.g) - ch(b.g)).abs() <= tolerance &&
        (ch(a.b) - ch(b.b)).abs() <= tolerance;
  }
}
