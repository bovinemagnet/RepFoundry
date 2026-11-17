import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';
import 'package:rep_foundry/features/mcp/application/tools/workout_tools.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';

import '../../support/fake_client_repository.dart';
import '../../support/mcp_fixture.dart';

void main() {
  late McpFixture f;
  late Exercise bench;
  late Exercise squat;

  setUp(() async {
    f = McpFixture();
    bench = await f.exercise('Bench Press', MuscleGroup.chest);
    squat = await f.exercise('Back Squat', MuscleGroup.quadriceps);
  });

  ListWorkoutsTool listTool({bool includeClients = false}) => ListWorkoutsTool(
      f.workouts, f.exercises, f.scope(includeClients: includeClients));

  GetWorkoutTool getTool({bool includeClients = false}) => GetWorkoutTool(
      f.workouts,
      f.exercises,
      f.cardio,
      f.stretching,
      f.scope(includeClients: includeClients));

  List<Map<String, Object?>> workoutsOf(Map<String, Object?> r) =>
      (r['workouts']! as List).cast<Map<String, Object?>>();

  group('list_workouts', () {
    test('pages through 25 workouts without gaps or duplicates', () async {
      final start = DateTime(2026, 1, 1, 7);
      for (var i = 0; i < 25; i++) {
        await f.workout(start.add(Duration(days: i)));
      }
      final tool = listTool();
      final seen = <String>[];
      final pageSizes = <int>[];
      Object? cursor;
      do {
        final r = await tool
            .call({'limit': 10, if (cursor != null) 'cursor': cursor});
        final page = workoutsOf(r);
        pageSizes.add(page.length);
        seen.addAll(page.map((w) => w['id']! as String));
        cursor = r['next_cursor'];
      } while (cursor != null);
      expect(pageSizes, [10, 10, 5]);
      expect(seen.toSet(), hasLength(25));
    });

    test('ends with a null cursor when the last page is exactly full',
        () async {
      final start = DateTime(2026, 1, 1, 7);
      for (var i = 0; i < 20; i++) {
        await f.workout(start.add(Duration(days: i)));
      }
      final first = await listTool().call({'limit': 10});
      final second =
          await listTool().call({'limit': 10, 'cursor': first['next_cursor']});
      expect(workoutsOf(second), hasLength(10));
      expect(second['next_cursor'], isNull);
    });

    test('lists newest first', () async {
      final old = await f.workout(DateTime(2026, 1, 1));
      final recent = await f.workout(DateTime(2026, 2, 1));
      final ids = workoutsOf(await listTool().call({})).map((w) => w['id']);
      expect(ids, [recent.id, old.id]);
    });

    test('filters by from and to', () async {
      await f.workout(DateTime(2026, 1, 1));
      final mid = await f.workout(DateTime(2026, 1, 15));
      await f.workout(DateTime(2026, 2, 1));
      final r =
          await listTool().call({'from': '2026-01-10', 'to': '2026-01-20'});
      expect(workoutsOf(r).map((w) => w['id']), [mid.id]);
      expect(r['next_cursor'], isNull);
    });

    test('summarises exercises, working sets and volume without warm-ups',
        () async {
      final w = await f.workout(DateTime(2026, 3, 1, 9), notes: 'Felt strong');
      await f.set(w, bench, weight: 40, reps: 10, warmUp: true);
      await f.set(w, bench, weight: 100, reps: 5, order: 2);
      await f.set(w, squat, weight: 120, reps: 5, order: 3);
      final row = workoutsOf(await listTool().call({})).single;
      expect(row['exercises'], ['Bench Press', 'Back Squat']);
      expect(row['working_set_count'], 2);
      expect(row['total_volume_kg'], 1100);
      expect(row['duration_seconds'], 3600);
      expect(row['notes'], 'Felt strong');
      expect(
          DateTime.parse(row['started_at']! as String)
              .isAtSameMomentAs(DateTime(2026, 3, 1, 9)),
          isTrue);
    });

    test('excludes a deleted workout', () async {
      final w = await f.workout(DateTime(2026, 3, 1));
      await f.workouts.deleteWorkout(w.id);
      expect(workoutsOf(await listTool().call({})), isEmpty);
    });

    test('shows an in-progress workout separately on the first page', () async {
      await f.workout(DateTime(2026, 3, 1));
      final live = await f.workout(DateTime(2026, 3, 2), length: null);
      await f.set(live, bench, weight: 80, reps: 8);
      final r = await listTool().call({});
      final inProgress = r['in_progress']! as Map<String, Object?>;
      expect(inProgress['id'], live.id);
      expect(inProgress['completed_at'], isNull);
      expect(inProgress['duration_seconds'], isNull);
      expect(inProgress['total_volume_kg'], 640);
      expect(workoutsOf(r).map((w) => w['id']), isNot(contains(live.id)));
    });

    test("does not show another client's in-progress workout", () async {
      await f.workout(DateTime(2026, 3, 2),
          length: null, clientId: otherClientId);
      expect((await listTool().call({}))['in_progress'], isNull);
    });

    test("never lists another client's workouts by default", () async {
      await f.workout(DateTime(2026, 3, 1), clientId: otherClientId);
      expect(workoutsOf(await listTool().call({})), isEmpty);
      // Positive control: the same workout is visible when asked for.
      final r = await listTool(includeClients: true)
          .call({'client_id': otherClientId});
      expect(workoutsOf(r), hasLength(1));
    });
  });

  group('get_workout', () {
    test('returns sets grouped by exercise in the order performed', () async {
      final w = await f.workout(DateTime(2026, 3, 1, 9));
      await f.set(w, squat, weight: 120, reps: 5, order: 1, rpe: 8);
      await f.set(w, bench,
          weight: 100, reps: 5, order: 2, avgHr: 120, peakHr: 140);
      await f.set(w, squat, weight: 125, reps: 3, order: 3);
      final r = await getTool().call({'workout_id': w.id});
      final exercises = (r['exercises']! as List).cast<Map<String, Object?>>();
      expect(exercises.map((e) => e['name']), ['Back Squat', 'Bench Press']);
      final squatSets =
          (exercises.first['sets']! as List).cast<Map<String, Object?>>();
      expect(squatSets.map((s) => s['weight_kg']), [120, 125]);
      expect(squatSets.first['rpe'], 8);
      expect(squatSets.first['estimated_1rm_kg'], 140);
      final benchSet = (exercises.last['sets']! as List).single as Map;
      expect(benchSet['avg_hr_bpm'], 120);
      expect(benchSet['peak_hr_bpm'], 140);
    });

    test('includes cardio and stretching without any location', () async {
      final w = await f.workout(DateTime(2026, 3, 1, 9));
      final run = await f.exercise('Treadmill', MuscleGroup.cardio,
          category: ExerciseCategory.cardio);
      final session = await f.cardioWithTrack(w, run);
      // Control: the session really has a recorded track.
      expect(await f.cardio.getTrackPoints(session.id), isNotEmpty);
      await f.stretching.createSession(StretchingSession(
        id: 's1',
        workoutId: w.id,
        type: 'hamstring',
        customName: 'Hamstring stretch',
        side: StretchingSide.left,
        durationSeconds: 45,
        entryMethod: StretchingEntryMethod.manual,
        updatedAt: DateTime.utc(2026),
      ));

      final r = await getTool().call({'workout_id': w.id});
      final cardio = (r['cardio']! as List).single as Map<String, Object?>;
      expect(cardio['exercise_name'], 'Treadmill');
      expect(cardio['distance_km'], 5);
      expect(cardio['duration_seconds'], 1800);
      expect(cardio['pace_min_per_km'], 6);
      expect(cardio['avg_hr_bpm'], 150);
      final stretch = (r['stretching']! as List).single as Map<String, Object?>;
      expect(stretch['name'], 'Hamstring stretch');
      expect(stretch['side'], 'left');
      expect(stretch['duration_seconds'], 45);
      expect(allKeys(r).intersection(gpsKeys), isEmpty);
    });

    test('returns an in-progress workout with no end', () async {
      final live = await f.workout(DateTime(2026, 3, 2), length: null);
      await f.set(live, bench, weight: 80, reps: 8);
      final r = await getTool().call({'workout_id': live.id});
      expect(r['completed_at'], isNull);
      expect(r['duration_seconds'], isNull);
      expect(r['exercises'], hasLength(1));
    });

    test("treats another client's workout as not found when client data is off",
        () async {
      final theirs =
          await f.workout(DateTime(2026, 3, 1), clientId: otherClientId);
      await expectLater(
          getTool().call({'workout_id': theirs.id}),
          throwsA(isA<McpToolError>()
              .having((e) => e.message, 'message', 'Workout not found')));
      // Positive control: visible once client data is on.
      final r =
          await getTool(includeClients: true).call({'workout_id': theirs.id});
      expect(r['id'], theirs.id);
    });

    test("treats a deleted client's workout as not found", () async {
      final gone = testClient('gone-client', deletedAt: DateTime.utc(2026, 2));
      final fixture = McpFixture(extraClients: [gone]);
      final theirs =
          await fixture.workout(DateTime(2026, 3, 1), clientId: gone.id);
      final tool = GetWorkoutTool(
          fixture.workouts,
          fixture.exercises,
          fixture.cardio,
          fixture.stretching,
          fixture.scope(includeClients: true));
      await expectLater(
          tool.call({'workout_id': theirs.id}), throwsA(isA<McpToolError>()));
    });

    test('treats unknown and deleted workouts as not found', () async {
      final w = await f.workout(DateTime(2026, 3, 1));
      await f.workouts.deleteWorkout(w.id);
      for (final id in [w.id, 'nope']) {
        await expectLater(
            getTool().call({'workout_id': id}), throwsA(isA<McpToolError>()));
      }
    });

    test('requires workout_id', () async {
      await expectLater(getTool().call({}), throwsA(isA<McpToolError>()));
    });
  });
}
