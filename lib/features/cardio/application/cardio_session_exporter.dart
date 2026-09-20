import '../domain/models/cardio_heart_rate_sample.dart';
import '../domain/models/cardio_session.dart';
import '../domain/models/cardio_track_point.dart';

/// Renders a saved cardio session's recordings as two files: a GPX 1.1
/// track (opens in map and route tools) and a heart-rate CSV. Pure string
/// builders; writing and sharing the files is the caller's job.
class CardioSessionExporter {
  const CardioSessionExporter._();

  static String gpx(
    CardioSession session, {
    required String exerciseName,
    required DateTime startedAt,
    required List<CardioTrackPoint> points,
  }) {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="RepFoundry" '
          'xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <metadata>')
      ..writeln('    <time>${_iso(startedAt)}</time>')
      ..writeln('  </metadata>')
      ..writeln('  <trk>')
      ..writeln('    <name>${_escape(exerciseName)}</name>')
      ..writeln('    <trkseg>');
    for (final p in points) {
      b.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}">');
      if (p.altitude != null) b.writeln('        <ele>${p.altitude}</ele>');
      b
        ..writeln('        <time>${_iso(p.timestamp)}</time>')
        ..writeln('      </trkpt>');
    }
    b
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');
    return b.toString();
  }

  static String heartRateCsv(List<CardioHeartRateSample> samples) {
    final b = StringBuffer()..writeln('timestamp,bpm');
    for (final s in samples) {
      b.writeln('${_iso(s.timestamp)},${s.bpm}');
    }
    return b.toString();
  }

  /// `cardio-<exercise>-<yyyy-MM-dd-HHmm>` in local time, safe for a file
  /// name on every platform.
  static String fileStem({
    required String exerciseName,
    required DateTime startedAt,
  }) {
    final local = startedAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final slug = exerciseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'cardio-$slug-${local.year}-${two(local.month)}-${two(local.day)}-'
        '${two(local.hour)}${two(local.minute)}';
  }

  static String _iso(DateTime t) => t.toUtc().toIso8601String();

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
