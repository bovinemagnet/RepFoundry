/// One heart-rate reading recorded during a cardio session.
class CardioHeartRateSample {
  final DateTime timestamp;
  final int bpm;

  const CardioHeartRateSample({required this.timestamp, required this.bpm});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardioHeartRateSample &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          bpm == other.bpm;

  @override
  int get hashCode => Object.hash(timestamp, bpm);
}
