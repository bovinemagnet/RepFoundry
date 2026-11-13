import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/application/calculate_progress_use_case.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';
import 'package:rep_foundry/features/mcp/application/tools/exercise_tools.dart';

import '../../support/mcp_fixture.dart';

void main() {
  late McpFixture f;
  late Exercise bench;
  late Exercise squat;

  setUp(() async {
    f = McpFixture();
    bench = await f.exercise('Zz Bench Press', MuscleGroup.chest);
    squat = await f.exercise('Zz Back Squat', MuscleGroup.quadriceps);
  });

  group('list_exercises', () {
    ListExercisesTool tool() =>
        ListExercisesTool(f.exercises, f.workouts, f.scope());

    List<Map<String, Object?>> rows(Map<String, Object?> r) =>
        (r['exercises']! as List).cast<Map<String, Object?>>();

    test('counts the sessions each exercise was used in', () async {
      final a = await f.workout(DateTime(2026, 3, 1));
      final b = await f.workout(DateTime(2026, 3, 3));
      await f.set(a, bench, weight: 100, reps: 5);
      await f.set(a, bench, weight: 100, reps: 5, order: 2);
      await f.set(b, bench, weight: 100, reps: 5);
      final r = rows(await tool().call({'query': 'Zz Bench'}));
      final row = r.single;
      expect(row['name'], 'Zz Bench Press');
      expect(row['times_used'], 2);
      expect(row['muscle_group'], 'chest');
      expect(row['category'], 'strength');
      expect(row['equipment'], 'barbell');
      expect(row['is_custom'], isFalse);
    });

    test('filters by muscle group', () async {
      final r = rows(await tool().call({'muscle_group': 'quadriceps'}));
      expect(r.map((e) => e['muscle_group']).toSet(), {'quadriceps'});
      expect(r.map((e) => e['name']), contains('Zz Back Squat'));
    });

    test('rejects an unknown muscle group', () async {
      await expectLater(
          tool().call({'muscle_group': 'wings'}), throwsA(isA<McpToolError>()));
    });

    test('sorts by name', () async {
      final names =
          rows(await tool().call({})).map((e) => e['name']! as String);
      expect(names, orderedEquals([...names]..sort()));
    });
  });

  group('get_exercise_history', () {
    GetExerciseHistoryTool tool({bool includeClients = false}) =>
        GetExerciseHistoryTool(
            f.exercises,
            CalculateProgressUseCase(workoutRepository: f.workouts),
            f.scope(includeClients: includeClients));

    test('groups sets by session, newest first, with working-set totals',
        () async {
      final older = await f.workout(DateTime(2026, 3, 1));
      final newer = await f.workout(DateTime(2026, 3, 8));
      await f.set(older, bench, weight: 40, reps: 10, warmUp: true);
      await f.set(older, bench, weight: 90, reps: 5, order: 2);
      await f.set(newer, bench, weight: 100, reps: 3);
      await f.set(newer, squat, weight: 140, reps: 3, order: 2);

      final r = await tool().call({'exercise_id': bench.id});
      expect(r['name'], 'Zz Bench Press');
      final sessions = (r['sessions']! as List).cast<Map<String, Object?>>();
      expect(sessions.map((s) => s['workout_id']), [newer.id, older.id]);
      expect((sessions.last['sets']! as List), hasLength(2));
      expect(r['total_volume_kg'], 750);
      expect(r['max_estimated_1rm_kg'], 110);
    });

    test('limits the number of sessions and filters by date', () async {
      for (var d = 1; d <= 5; d++) {
        final w = await f.workout(DateTime(2026, 3, d));
        await f.set(w, bench, weight: 100, reps: 5);
      }
      final r = await tool().call({'exercise_id': bench.id, 'limit': 2});
      expect(r['sessions'], hasLength(2));
      final ranged =
          await tool().call({'exercise_id': bench.id, 'from': '2026-03-04'});
      expect(ranged['sessions'], hasLength(2));
    });

    test('pages sessions with next_cursor', () async {
      for (var d = 1; d <= 5; d++) {
        final w = await f.workout(DateTime(2026, 3, d));
        await f.set(w, bench, weight: 100, reps: 5);
      }
      final seen = <Object?>[];
      final sizes = <int>[];
      Object? cursor;
      do {
        final r = await tool().call({
          'exercise_id': bench.id,
          'limit': 2,
          if (cursor != null) 'cursor': cursor,
        });
        final sessions = r['sessions']! as List;
        sizes.add(sessions.length);
        seen.addAll(sessions.map((e) => (e as Map)['workout_id']));
        cursor = r['next_cursor'];
      } while (cursor != null);
      expect(sizes, [2, 2, 1]);
      expect(seen.toSet(), hasLength(5));
    });

    test('rejects an unknown exercise', () async {
      await expectLater(
          tool().call({'exercise_id': 'nope'}), throwsA(isA<McpToolError>()));
    });

    test("reads another client's history only when client data is on",
        () async {
      final theirs =
          await f.workout(DateTime(2026, 3, 1), clientId: otherClientId);
      await f.set(theirs, bench, weight: 60, reps: 5);
      final mine = await tool().call({'exercise_id': bench.id});
      expect(mine['sessions'], isEmpty);
      await expectLater(
          tool().call({'exercise_id': bench.id, 'client_id': otherClientId}),
          throwsA(isA<McpToolError>()));
      final r = await tool(includeClients: true)
          .call({'exercise_id': bench.id, 'client_id': otherClientId});
      expect(r['sessions'], hasLength(1));
    });
  });

  group('list_personal_records', () {
    ListPersonalRecordsTool tool() =>
        ListPersonalRecordsTool(f.records, f.exercises, f.scope());

    Future<void> record(RecordType type, double value, DateTime at,
        {String clientId = kSelfClientId, String? exerciseId}) {
      return f.records.createRecord(PersonalRecord(
        id: '${type.name}-$value-${at.millisecondsSinceEpoch}-$clientId',
        exerciseId: exerciseId ?? bench.id,
        recordType: type,
        value: value,
        achievedAt: at.toUtc(),
        clientId: clientId,
        updatedAt: at.toUtc(),
      ));
    }

    test('labels each record with its unit, newest first', () async {
      await record(RecordType.maxWeight, 100, DateTime(2026, 3, 1));
      await record(RecordType.maxReps, 12, DateTime(2026, 3, 2));
      await record(RecordType.maxVolume, 1500, DateTime(2026, 3, 3));
      await record(RecordType.estimatedOneRepMax, 116.67, DateTime(2026, 3, 4));
      final r = (await tool().call({}))['records']! as List;
      final rows = r.cast<Map<String, Object?>>();
      expect(rows.map((e) => e['record_type']),
          ['estimatedOneRepMax', 'maxVolume', 'maxReps', 'maxWeight']);
      expect(rows.map((e) => e['unit']), ['kg', 'kg_x_reps', 'reps', 'kg']);
      expect(rows.first['exercise_name'], 'Zz Bench Press');
      expect(rows.first['value'], 116.67);
    });

    test('pages records with next_cursor', () async {
      for (var d = 1; d <= 25; d++) {
        await record(RecordType.maxWeight, 100.0 + d, DateTime(2026, 1, d));
      }
      final seen = <Object?>[];
      final sizes = <int>[];
      Object? cursor;
      do {
        final r = await tool()
            .call({'limit': 10, if (cursor != null) 'cursor': cursor});
        final rows = r['records']! as List;
        sizes.add(rows.length);
        seen.addAll(rows.map((e) => (e as Map)['value']));
        cursor = r['next_cursor'];
      } while (cursor != null);
      expect(sizes, [10, 10, 5]);
      expect(seen.toSet(), hasLength(25));
    });

    test('filters by exercise and date, and hides other clients', () async {
      await record(RecordType.maxWeight, 100, DateTime(2026, 1, 1));
      await record(RecordType.maxWeight, 110, DateTime(2026, 3, 1));
      await record(RecordType.maxWeight, 150, DateTime(2026, 3, 1),
          exerciseId: squat.id);
      await record(RecordType.maxWeight, 60, DateTime(2026, 3, 1),
          clientId: otherClientId);
      final r = (await tool().call(
          {'exercise_id': bench.id, 'from': '2026-02-01'}))['records']! as List;
      expect(r.map((e) => (e as Map)['value']), [110]);
    });
  });
}
