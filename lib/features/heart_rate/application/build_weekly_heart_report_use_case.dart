import 'package:hr_zones/hr_zones.dart';

import '../../cardio/domain/repositories/cardio_session_repository.dart';
import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import 'weekly_heart_report.dart';

/// Builds the [WeeklyHeartReport] for one client from stored data. Pure
/// apart from the repositories: the caller passes `now` and the zones.
class BuildWeeklyHeartReportUseCase {
  final WorkoutRepository _workoutRepository;
  final CardioSessionRepository _cardioSessionRepository;
  final ExerciseRepository _exerciseRepository;

  const BuildWeeklyHeartReportUseCase({
    required WorkoutRepository workoutRepository,
    required CardioSessionRepository cardioSessionRepository,
    required ExerciseRepository exerciseRepository,
  })  : _workoutRepository = workoutRepository,
        _cardioSessionRepository = cardioSessionRepository,
        _exerciseRepository = exerciseRepository;

  static const int days = 7;

  Future<WeeklyHeartReport> execute({
    required String clientId,
    required DateTime now,
    ZoneConfiguration? zones,
  }) async {
    final local = now.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    final periodStart = today.subtract(const Duration(days: days - 1));

    final workouts = await _workoutRepository.getWorkoutHistory(
      clientId: clientId,
      limit: 500,
    );
    final recent = workouts
        .where((w) => !w.startedAt.toLocal().isBefore(periodStart))
        .toList();
    if (recent.isEmpty) return _empty();

    final exercises = await _exerciseRepository.getAllExercises();
    final names = {for (final e in exercises) e.id: e.name};

    final sessions = <HeartSessionSummary>[];
    final secondsInZone = <int, int>{};

    for (final workout in recent) {
      final cardioSessions =
          await _cardioSessionRepository.getSessionsForWorkout(workout.id);
      var summarised = false;
      for (final session in cardioSessions) {
        final samples =
            await _cardioSessionRepository.getHeartRateSamples(session.id);
        final int? avg;
        final int? peak;
        if (samples.isNotEmpty) {
          final bpms = samples.map((s) => s.bpm).toList();
          avg = (bpms.reduce((a, b) => a + b) / bpms.length).round();
          peak = bpms.reduce((a, b) => a > b ? a : b);
          if (zones != null) {
            for (final s in samples) {
              final zone = currentZoneFromConfig(s.bpm, zones)?.zoneNumber;
              if (zone != null) {
                secondsInZone[zone] = (secondsInZone[zone] ?? 0) + 1;
              }
            }
          }
        } else {
          avg = session.avgHeartRate;
          peak = session.avgHeartRate;
        }
        if (avg == null || peak == null) continue;
        sessions.add(HeartSessionSummary(
          workoutId: workout.id,
          kind: HeartSessionKind.cardio,
          title: names[session.exerciseId] ?? session.exerciseId,
          startedAt: workout.startedAt,
          avgBpm: avg,
          peakBpm: peak,
        ));
        summarised = true;
      }
      if (summarised) continue;

      final sets = await _workoutRepository.getSetsForWorkout(workout.id);
      final avgs = [
        for (final s in sets)
          if (s.avgHeartRate != null) s.avgHeartRate!
      ];
      final peaks = [
        for (final s in sets)
          if (s.peakHeartRate != null) s.peakHeartRate!
      ];
      if (avgs.isEmpty) continue;
      sessions.add(HeartSessionSummary(
        workoutId: workout.id,
        kind: HeartSessionKind.strength,
        title: workout.notes ?? '',
        startedAt: workout.startedAt,
        avgBpm: (avgs.reduce((a, b) => a + b) / avgs.length).round(),
        peakBpm: (peaks.isEmpty ? avgs : peaks).reduce((a, b) => a > b ? a : b),
      ));
    }

    if (sessions.isEmpty) return _empty();
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final dailyPeak = List<int?>.filled(days, null);
    for (final s in sessions) {
      final l = s.startedAt.toLocal();
      final day = DateTime(l.year, l.month, l.day);
      final index = DateTime.utc(day.year, day.month, day.day)
          .difference(DateTime.utc(
              periodStart.year, periodStart.month, periodStart.day))
          .inDays;
      if (index < 0 || index >= days) continue;
      final current = dailyPeak[index];
      if (current == null || s.peakBpm > current) dailyPeak[index] = s.peakBpm;
    }

    return WeeklyHeartReport(
      sessions: sessions,
      avgBpm: (sessions.map((s) => s.avgBpm).reduce((a, b) => a + b) /
              sessions.length)
          .round(),
      peakBpm: sessions.map((s) => s.peakBpm).reduce((a, b) => a > b ? a : b),
      dailyPeakBpm: dailyPeak,
      secondsInZone: secondsInZone,
    );
  }

  WeeklyHeartReport _empty() => WeeklyHeartReport(
        sessions: const [],
        avgBpm: null,
        peakBpm: null,
        dailyPeakBpm: List<int?>.filled(days, null),
        secondsInZone: const {},
      );
}
