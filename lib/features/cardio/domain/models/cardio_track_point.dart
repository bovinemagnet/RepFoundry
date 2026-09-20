/// One GPS fix recorded during a cardio session.
class CardioTrackPoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  /// Metres above sea level, when the fix carried one.
  final double? altitude;

  /// Horizontal accuracy in metres, when the fix carried one.
  final double? accuracy;

  const CardioTrackPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardioTrackPoint &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          altitude == other.altitude &&
          accuracy == other.accuracy;

  @override
  int get hashCode =>
      Object.hash(timestamp, latitude, longitude, altitude, accuracy);
}
