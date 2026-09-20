import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/application/cardio_session_exporter.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_heart_rate_sample.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_track_point.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1, 7, 30);
  final session = CardioSession(
    id: 'c1',
    workoutId: 'w1',
    exerciseId: '16',
    durationSeconds: 1800,
    distanceMeters: 5000,
    clientId: kSelfClientId,
    updatedAt: t0,
  );

  group('CardioSessionExporter.gpx', () {
    test('writes a GPX 1.1 track with one point per fix', () {
      final gpx = CardioSessionExporter.gpx(
        session,
        exerciseName: 'Outdoor Run',
        startedAt: t0,
        points: [
          CardioTrackPoint(
            timestamp: t0,
            latitude: 51.5074,
            longitude: -0.1278,
            altitude: 12.5,
          ),
          CardioTrackPoint(
            timestamp: t0.add(const Duration(seconds: 5)),
            latitude: 51.508,
            longitude: -0.129,
          ),
        ],
      );

      expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1"'));
      expect(gpx, contains('<name>Outdoor Run</name>'));
      expect(gpx, contains('<trkpt lat="51.5074" lon="-0.1278">'));
      expect(gpx, contains('<ele>12.5</ele>'));
      expect(gpx, contains('<time>2026-05-01T07:30:00.000Z</time>'));
      expect(gpx, contains('<trkpt lat="51.508" lon="-0.129">'));
      expect(gpx, contains('<time>2026-05-01T07:30:05.000Z</time>'));
      // A fix without altitude writes no <ele>.
      expect('<ele>'.allMatches(gpx), hasLength(1));
      expect(gpx.trim(), endsWith('</gpx>'));
    });

    test('escapes the exercise name', () {
      final gpx = CardioSessionExporter.gpx(
        session,
        exerciseName: 'Row & <Sprint>',
        startedAt: t0,
        points: const [],
      );

      expect(gpx, contains('<name>Row &amp; &lt;Sprint&gt;</name>'));
    });
  });

  group('CardioSessionExporter.heartRateCsv', () {
    test('writes one ISO-8601 UTC timestamp and bpm per line', () {
      final csv = CardioSessionExporter.heartRateCsv([
        CardioHeartRateSample(timestamp: t0, bpm: 131),
        CardioHeartRateSample(
            timestamp: t0.add(const Duration(seconds: 1)), bpm: 142),
      ]);

      expect(
          csv,
          'timestamp,bpm\n'
          '2026-05-01T07:30:00.000Z,131\n'
          '2026-05-01T07:30:01.000Z,142\n');
    });
  });

  group('CardioSessionExporter.fileStem', () {
    test('names files by exercise and local start time', () {
      final stem = CardioSessionExporter.fileStem(
        exerciseName: 'Outdoor Run',
        startedAt: DateTime(2026, 5, 1, 17, 30),
      );

      expect(stem, 'cardio-outdoor-run-2026-05-01-1730');
    });
  });
}
