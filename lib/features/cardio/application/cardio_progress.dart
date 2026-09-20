import 'cardio_history_entry.dart';

/// One session's pace, for the trend line.
class PacePoint {
  final DateTime date;
  final double minutesPerKm;

  const PacePoint({required this.date, required this.minutesPerKm});
}

/// Summary figures for the cardio Progress view over the last [weeks]
/// calendar weeks (Monday-based, local time), computed from history
/// entries. Pure: no clock, no repository.
class CardioProgress {
  final double totalDistanceKm;
  final int sessionCount;
  final Duration totalDuration;

  /// Distance per calendar week, oldest first, one entry per week in the
  /// period (the last is the current week).
  final List<double> weeklyDistanceKm;

  /// Fastest session pace in the period, or null when no session had a
  /// distance.
  final double? bestPaceMinutesPerKm;

  /// Mean of the sessions' average heart rates, or null when none had one.
  final int? avgHeartRate;

  /// Sessions with a pace, oldest first.
  final List<PacePoint> paceTrend;

  const CardioProgress({
    required this.totalDistanceKm,
    required this.sessionCount,
    required this.totalDuration,
    required this.weeklyDistanceKm,
    required this.bestPaceMinutesPerKm,
    required this.avgHeartRate,
    required this.paceTrend,
  });

  static CardioProgress compute(
    List<CardioHistoryEntry> entries, {
    required DateTime now,
    required int weeks,
  }) {
    final thisWeekStart = _weekStart(now.toLocal());
    final periodStart = thisWeekStart.subtract(Duration(days: 7 * (weeks - 1)));

    final inPeriod = entries
        .where((e) => !e.startedAt.toLocal().isBefore(periodStart))
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final weekly = List<double>.filled(weeks, 0);
    var distance = 0.0;
    var seconds = 0;
    double? bestPace;
    var hrSum = 0;
    var hrCount = 0;
    final pace = <PacePoint>[];

    for (final e in inPeriod) {
      final local = e.startedAt.toLocal();
      // Calendar arithmetic, not Duration division: DST-length weeks would
      // otherwise land a session in the wrong bucket.
      final bucket = _weeksBetween(periodStart, _weekStart(local));
      final km = e.distanceKm;
      if (km != null) {
        distance += km;
        if (bucket >= 0 && bucket < weeks) weekly[bucket] += km;
      }
      seconds += e.session.durationSeconds;
      final p = e.paceMinutesPerKm;
      if (p != null) {
        if (bestPace == null || p < bestPace) bestPace = p;
        pace.add(PacePoint(date: e.startedAt, minutesPerKm: p));
      }
      final hr = e.session.avgHeartRate;
      if (hr != null) {
        hrSum += hr;
        hrCount++;
      }
    }

    return CardioProgress(
      totalDistanceKm: distance,
      sessionCount: inPeriod.length,
      totalDuration: Duration(seconds: seconds),
      weeklyDistanceKm: weekly,
      bestPaceMinutesPerKm: bestPace,
      avgHeartRate: hrCount == 0 ? null : (hrSum / hrCount).round(),
      paceTrend: pace,
    );
  }

  /// Local midnight of the Monday of [local]'s week.
  static DateTime _weekStart(DateTime local) {
    final day = DateTime(local.year, local.month, local.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static int _weeksBetween(DateTime a, DateTime b) {
    final days = DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;
    return days ~/ 7;
  }
}
