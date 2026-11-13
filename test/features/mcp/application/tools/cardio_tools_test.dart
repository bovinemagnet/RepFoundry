import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/cardio/application/build_cardio_history_use_case.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_heart_rate_sample.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/heart_rate/application/build_weekly_heart_report_use_case.dart';
import 'package:rep_foundry/features/mcp/application/tools/cardio_tools.dart';

import '../../support/fake_health_profile_repository.dart';
import '../../support/mcp_fixture.dart';

void main() {
  late McpFixture f;
  late Exercise run;
  late Exercise bike;
  final now = DateTime(2026, 11, 11, 12);

  setUp(() async {
    f = McpFixture();
    run = await f.exercise('Outdoor Run', MuscleGroup.cardio,
        category: ExerciseCategory.cardio);
    bike = await f.exercise('Stationary Bike', MuscleGroup.cardio,
        category: ExerciseCategory.cardio);
  });

  BuildCardioHistoryUseCase history() => BuildCardioHistoryUseCase(
        workoutRepository: f.workouts,
        cardioSessionRepository: f.cardio,
        exerciseRepository: f.exercises,
      );

  List<Map<String, Object?>> sessionsOf(Map<String, Object?> r) =>
      (r['sessions']! as List).cast<Map<String, Object?>>();

  group('list_cardio_sessions', () {
    ListCardioSessionsTool tool() =>
        ListCardioSessionsTool(history(), f.scope());

    test('lists sessions newest first without any location', () async {
      final a = await f.workout(DateTime(2026, 11, 1, 7));
      final b = await f.workout(DateTime(2026, 11, 5, 7));
      await f.cardioWithTrack(a, run, seconds: 1500, meters: 5000);
      final s = await f.cardioWithTrack(b, bike, meters: null, avgHr: null);
      // Control: the sessions really have GPS tracks.
      expect(await f.cardio.getTrackPoints(s.id), isNotEmpty);

      final r = await tool().call({});
      final rows = sessionsOf(r);
      expect(rows.map((e) => e['sport']), ['Stationary Bike', 'Outdoor Run']);
      expect(rows.last['distance_km'], 5);
      expect(rows.last['pace_min_per_km'], 5);
      expect(rows.last['duration_seconds'], 1500);
      expect(rows.first['distance_km'], isNull);
      expect(rows.first['avg_hr_bpm'], isNull);
      expect(allKeys(r).intersection(gpsKeys), isEmpty);
    });

    test('filters by sport, ignoring case', () async {
      final w = await f.workout(DateTime(2026, 11, 1, 7));
      await f.cardioWithTrack(w, run);
      await f.cardioWithTrack(w, bike);
      final rows = sessionsOf(await tool().call({'sport': 'outdoor run'}));
      expect(rows.map((e) => e['sport']), ['Outdoor Run']);
    });

    test('pages without overlap', () async {
      for (var d = 1; d <= 5; d++) {
        await f.cardioWithTrack(await f.workout(DateTime(2026, 10, d, 7)), run);
      }
      final first = await tool().call({'limit': 3});
      final second =
          await tool().call({'limit': 3, 'cursor': first['next_cursor']});
      final ids =
          [...sessionsOf(first), ...sessionsOf(second)].map((e) => e['id']);
      expect(ids.toSet(), hasLength(5));
      expect(second['next_cursor'], isNull);
    });

    test('excludes a soft-deleted session', () async {
      final w = await f.workout(DateTime(2026, 11, 1, 7));
      final kept = await f.cardioWithTrack(w, run);
      await f.cardio.createSession(CardioSession(
        id: 'deleted-session',
        workoutId: w.id,
        exerciseId: bike.id,
        durationSeconds: 600,
        clientId: kSelfClientId,
        updatedAt: DateTime.utc(2026, 11, 2),
        deletedAt: DateTime.utc(2026, 11, 2),
      ));
      final ids = sessionsOf(await tool().call({})).map((e) => e['id']);
      expect(ids, [kept.id]);
    });

    test("hides another client's sessions", () async {
      final theirs =
          await f.workout(DateTime(2026, 11, 1), clientId: otherClientId);
      await f.cardioWithTrack(theirs, run);
      expect(sessionsOf(await tool().call({})), isEmpty);
    });
  });

  test('get_cardio_progress summarises six weeks, oldest week first', () async {
    final w = await f.workout(DateTime(2026, 11, 10, 7));
    await f.cardioWithTrack(w, run, seconds: 1800, meters: 6000, avgHr: 140);
    final old = await f.workout(DateTime(2026, 10, 20, 7));
    await f.cardioWithTrack(old, bike, seconds: 600, meters: 3000, avgHr: 120);

    final all =
        await GetCardioProgressTool(history(), f.scope(), () => now).call({});
    expect(all['weeks'], 6);
    expect(all['weekly_distance_km'], [0, 0, 3, 0, 0, 6]);
    expect(all['session_count'], 2);
    expect(all['total_distance_km'], 9);
    expect(all['total_duration_seconds'], 2400);
    expect(all['best_pace_min_per_km'], 3.33);
    expect(all['avg_hr_bpm'], 130);

    final runOnly = await GetCardioProgressTool(history(), f.scope(), () => now)
        .call({'sport': 'Outdoor Run'});
    expect(runOnly['session_count'], 1);
    expect(runOnly['weekly_distance_km'], [0, 0, 0, 0, 0, 6]);
  });

  group('get_weekly_heart_report', () {
    GetWeeklyHeartReportTool tool(FakeHealthProfileRepository profiles) =>
        GetWeeklyHeartReportTool(
          BuildWeeklyHeartReportUseCase(
            workoutRepository: f.workouts,
            cardioSessionRepository: f.cardio,
            exerciseRepository: f.exercises,
          ),
          profiles,
          f.scope(),
          () => now,
        );

    test('reports sessions, daily peaks and time in zone', () async {
      final bench = await f.exercise('Bench', MuscleGroup.chest);
      final lift = await f.workout(DateTime(2026, 11, 9, 9));
      await f.set(lift, bench, weight: 100, reps: 5, avgHr: 110, peakHr: 130);
      final ride = await f.workout(DateTime(2026, 11, 10, 9));
      final session = await f.cardioWithTrack(ride, bike, avgHr: 150);
      await f.cardio.saveHeartRateSamples(session.id, [
        for (var i = 0; i < 60; i++)
          CardioHeartRateSample(
              timestamp: ride.startedAt.add(Duration(seconds: i)), bpm: 150),
      ]);

      final r = await tool(FakeHealthProfileRepository(
          {kSelfClientId: const HealthProfile(age: 40)})).call({});
      final sessions = (r['sessions']! as List).cast<Map<String, Object?>>();
      expect(sessions.map((s) => s['kind']), ['cardio', 'strength']);
      expect(sessions.last['peak_bpm'], 130);
      expect(r['daily_peak_bpm'], hasLength(7));
      final zones = r['seconds_in_zone']! as Map<String, Object?>;
      expect(zones.keys, everyElement(matches(RegExp(r'^[1-5]$'))));
      expect(
          zones.values.fold<int>(0, (a, b) => a + (b! as int)), greaterThan(0));
    });

    test('reports no time in zone without a profile to derive zones from',
        () async {
      final ride = await f.workout(DateTime(2026, 11, 10, 9));
      final session = await f.cardioWithTrack(ride, bike);
      await f.cardio.saveHeartRateSamples(session.id, [
        CardioHeartRateSample(timestamp: ride.startedAt, bpm: 150),
      ]);
      final r = await tool(FakeHealthProfileRepository()).call({});
      expect(r['seconds_in_zone'], isEmpty);
    });
  });
}
