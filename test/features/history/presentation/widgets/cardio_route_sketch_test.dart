import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_track_point.dart';
import 'package:rep_foundry/features/history/presentation/widgets/cardio_route_sketch.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1, 7);

  test('projectTrack maps the track into the box, keeping aspect ratio', () {
    final points = [
      CardioTrackPoint(timestamp: t0, latitude: 0, longitude: 0),
      CardioTrackPoint(timestamp: t0, latitude: 0.001, longitude: 0.002),
    ];

    final offsets = projectTrack(points, const Size(200, 100), padding: 0);

    // Longitude spans twice the latitude, so it fills the width and the
    // latitude is centred vertically at half height.
    expect(offsets.first.dx, closeTo(0, 0.001));
    expect(offsets.first.dy, closeTo(100, 0.001));
    expect(offsets.last.dx, closeTo(200, 0.001));
    expect(offsets.last.dy, closeTo(0, 0.001));
  });

  test('a single point sits in the centre', () {
    final offsets = projectTrack(
      [CardioTrackPoint(timestamp: t0, latitude: 1, longitude: 1)],
      const Size(200, 100),
      padding: 0,
    );

    expect(offsets.single, const Offset(100, 50));
  });

  testWidgets('renders a CustomPaint for the points', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CardioRouteSketch(points: [
        CardioTrackPoint(timestamp: t0, latitude: 0, longitude: 0),
        CardioTrackPoint(timestamp: t0, latitude: 1, longitude: 1),
      ]),
    ));

    expect(find.byType(CustomPaint), findsWidgets);
  });
}
