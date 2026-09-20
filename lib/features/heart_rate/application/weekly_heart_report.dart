enum HeartSessionKind { strength, cardio }

/// One session in the last seven days that carried heart-rate data.
class HeartSessionSummary {
  final String workoutId;
  final HeartSessionKind kind;
  final String title;
  final DateTime startedAt;
  final int avgBpm;
  final int peakBpm;

  const HeartSessionSummary({
    required this.workoutId,
    required this.kind,
    required this.title,
    required this.startedAt,
    required this.avgBpm,
    required this.peakBpm,
  });
}

/// The last seven days of heart-rate activity, assembled from strength
/// workouts (per-set summaries) and cardio sessions (per-second samples).
class WeeklyHeartReport {
  /// Sessions with heart-rate data, newest first.
  final List<HeartSessionSummary> sessions;

  /// Mean of the sessions' averages, or null with no sessions.
  final int? avgBpm;
  final int? peakBpm;

  /// Highest reading each day, oldest day first, seven entries; null on
  /// days without heart-rate data.
  final List<int?> dailyPeakBpm;

  /// Seconds of cardio samples that fell in each zone number, when zones
  /// were available. Strength sets carry only summaries, so they do not
  /// contribute here.
  final Map<int, int> secondsInZone;

  const WeeklyHeartReport({
    required this.sessions,
    required this.avgBpm,
    required this.peakBpm,
    required this.dailyPeakBpm,
    required this.secondsInZone,
  });

  bool get isEmpty => sessions.isEmpty;
}
