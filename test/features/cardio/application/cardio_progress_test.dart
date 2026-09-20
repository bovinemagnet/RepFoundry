import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/application/cardio_history_entry.dart';
import 'package:rep_foundry/features/cardio/application/cardio_progress.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  // A Saturday, 09:00 local, so "this week" is unambiguous.
  final now = DateTime(2026, 9, 19, 9);

  CardioHistoryEntry entry({
    required String id,
    required DateTime startedAt,
    String exerciseId = 'run',
    String exerciseName = 'Outdoor Run',
    int durationSeconds = 1800,
    double? distanceMeters = 5000,
    int? avgHeartRate = 150,
  }) {
    return CardioHistoryEntry(
      session: CardioSession(
        id: id,
        workoutId: 'w-$id',
        exerciseId: exerciseId,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        avgHeartRate: avgHeartRate,
        clientId: kSelfClientId,
        updatedAt: startedAt,
      ),
      startedAt: startedAt,
      exerciseName: exerciseName,
    );
  }

  group('CardioProgress.compute', () {
    test('sums distance, sessions and time for the period', () {
      final stats = CardioProgress.compute(
        [
          entry(id: 'a', startedAt: now.subtract(const Duration(days: 1))),
          entry(
              id: 'b',
              startedAt: now.subtract(const Duration(days: 8)),
              distanceMeters: 8030,
              durationSeconds: 2840),
          entry(
              id: 'c',
              startedAt: now.subtract(const Duration(days: 50)),
              distanceMeters: 99000),
        ],
        now: now,
        weeks: 6,
      );

      expect(stats.totalDistanceKm, closeTo(13.03, 0.001));
      expect(stats.sessionCount, 2);
      expect(stats.totalDuration, const Duration(seconds: 4640));
    });

    test('buckets distance into calendar weeks, oldest first', () {
      final stats = CardioProgress.compute(
        [
          entry(
              id: 'a',
              startedAt: now.subtract(const Duration(days: 1)),
              distanceMeters: 5000),
          entry(
              id: 'b',
              startedAt: now.subtract(const Duration(days: 2)),
              distanceMeters: 3000),
          entry(
              id: 'c',
              startedAt: now.subtract(const Duration(days: 9)),
              distanceMeters: 4000),
        ],
        now: now,
        weeks: 6,
      );

      expect(stats.weeklyDistanceKm, hasLength(6));
      expect(stats.weeklyDistanceKm.last, closeTo(8.0, 0.001));
      expect(stats.weeklyDistanceKm[4], closeTo(4.0, 0.001));
      expect(stats.weeklyDistanceKm.take(4), everyElement(0));
    });

    test('best pace is the fastest session with a distance', () {
      final stats = CardioProgress.compute(
        [
          entry(
              id: 'a',
              startedAt: now,
              distanceMeters: 5000,
              durationSeconds: 1800), // 6:00
          entry(
              id: 'b',
              startedAt: now,
              distanceMeters: 5000,
              durationSeconds: 1500), // 5:00
          entry(
              id: 'c',
              startedAt: now,
              distanceMeters: null,
              durationSeconds: 60),
        ],
        now: now,
        weeks: 6,
      );

      expect(stats.bestPaceMinutesPerKm, closeTo(5.0, 0.001));
    });

    test('average heart rate ignores sessions without one', () {
      final stats = CardioProgress.compute(
        [
          entry(id: 'a', startedAt: now, avgHeartRate: 140),
          entry(id: 'b', startedAt: now, avgHeartRate: 160),
          entry(id: 'c', startedAt: now, avgHeartRate: null),
        ],
        now: now,
        weeks: 6,
      );

      expect(stats.avgHeartRate, 150);
    });

    test('pace trend lists sessions with a pace, oldest first', () {
      final stats = CardioProgress.compute(
        [
          entry(
              id: 'new',
              startedAt: now,
              distanceMeters: 5000,
              durationSeconds: 1500),
          entry(
              id: 'old',
              startedAt: now.subtract(const Duration(days: 3)),
              distanceMeters: 5000,
              durationSeconds: 1800),
          entry(id: 'none', startedAt: now, distanceMeters: null),
        ],
        now: now,
        weeks: 6,
      );

      expect(stats.paceTrend.map((p) => p.minutesPerKm), [6.0, 5.0]);
    });

    test('empty input gives empty stats, not NaN', () {
      final stats = CardioProgress.compute(const [], now: now, weeks: 6);

      expect(stats.totalDistanceKm, 0);
      expect(stats.bestPaceMinutesPerKm, isNull);
      expect(stats.avgHeartRate, isNull);
      expect(stats.weeklyDistanceKm, everyElement(0));
    });
  });

  group('CardioHistoryEntry', () {
    test('paceMinutesPerKm mirrors the session', () {
      final e = entry(
          id: 'a', startedAt: now, distanceMeters: 5000, durationSeconds: 1800);
      expect(e.paceMinutesPerKm, closeTo(6.0, 0.001));
    });
  });
}
