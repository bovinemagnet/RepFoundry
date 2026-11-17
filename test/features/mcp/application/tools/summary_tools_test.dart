import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/muscle_balance_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/weekly_volume_provider.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/mcp/application/mcp_args.dart';
import 'package:rep_foundry/features/mcp/application/tools/summary_tools.dart';

import '../../support/fake_client_repository.dart';
import '../../support/mcp_fixture.dart';

class _MeActiveClient extends ActiveClientNotifier {
  @override
  Future<Client> build() async => testClient(kSelfClientId, name: 'Me');
}

void main() {
  late McpFixture f;
  late Exercise bench;
  late Exercise squat;
  // A Wednesday, so "this week" started two days earlier.
  final now = DateTime(2026, 11, 11, 12);

  setUp(() async {
    f = McpFixture();
    bench = await f.exercise('Bench', MuscleGroup.chest);
    squat = await f.exercise('Squat', MuscleGroup.quadriceps);
  });

  GetTrainingSummaryTool tool() =>
      GetTrainingSummaryTool(f.workouts, f.exercises, f.scope(), () => now);

  List<Map<String, Object?>> weeks(Map<String, Object?> r) =>
      (r['weeks']! as List).cast<Map<String, Object?>>();

  test('reports weekly volume, load and muscle balance', () async {
    final lastWeek = await f.workout(DateTime(2026, 11, 3, 9));
    await f.set(lastWeek, bench, weight: 100, reps: 5, rpe: 8);
    await f.set(lastWeek, bench, weight: 50, reps: 5, warmUp: true, order: 2);
    final thisWeek = await f.workout(DateTime(2026, 11, 10, 9));
    await f.set(thisWeek, squat, weight: 100, reps: 10, rpe: 6);
    await f.set(thisWeek, squat, weight: 100, reps: 5, order: 2);

    final r = await tool().call({});
    final w = weeks(r);
    expect(w.map((e) => e['week_start']), ['2026-11-02', '2026-11-09']);
    expect(w.map((e) => e['total_volume_kg']), [500, 1500]);
    expect(w.last['percent_change'], 200);
    expect(w.map((e) => e['working_set_count']), [1, 2]);
    expect(w.map((e) => e['avg_rpe']), [8, 6]);
    expect(w.map((e) => e['load']), [8, 12]);
    final balance = (r['muscle_balance']! as List).cast<Map<String, Object?>>();
    expect(balance.map((m) => m['muscle_group']), ['chest', 'quadriceps']);
    expect(balance.map((m) => m['volume_percent']), [25, 75]);
  });

  test('reports a null average RPE for a week with no RPE', () async {
    final w = await f.workout(DateTime(2026, 11, 10, 9));
    await f.set(w, bench, weight: 100, reps: 5);
    expect(weeks(await tool().call({})).single['avg_rpe'], isNull);
  });

  test('counts only weeks inside the window, current week included', () async {
    // The week just before an eight-week window.
    final old = await f.workout(DateTime(2026, 9, 15, 9));
    await f.set(old, bench, weight: 100, reps: 5);
    final edge = await f.workout(DateTime(2026, 9, 21, 9)); // 8th week back
    await f.set(edge, bench, weight: 100, reps: 5);
    final eight = weeks(await tool().call({'weeks': 8}));
    expect(eight.map((e) => e['week_start']), ['2026-09-21']);
    // Control: widening the window brings the old session in.
    final twelve = weeks(await tool().call({'weeks': 12}));
    expect(twelve.map((e) => e['week_start']), ['2026-09-14', '2026-09-21']);
  });

  test('excludes sessions still in progress', () async {
    final live = await f.workout(DateTime(2026, 11, 10, 9), length: null);
    await f.set(live, bench, weight: 100, reps: 5);
    expect(weeks(await tool().call({})), isEmpty);
  });

  test('matches the analytics screen for the same data', () async {
    final recent = DateTime.now();
    for (var d = 1; d <= 3; d++) {
      final w = await f.workout(recent.subtract(Duration(days: d)));
      await f.set(w, bench, weight: 100, reps: 5);
      await f.set(w, squat, weight: 120, reps: 5, order: 2);
    }
    final container = ProviderContainer(overrides: [
      activeClientProvider.overrideWith(_MeActiveClient.new),
      workoutRepositoryProvider.overrideWithValue(f.workouts),
      exerciseRepositoryProvider.overrideWithValue(f.exercises),
    ]);
    addTearDown(container.dispose);

    final screenWeeks = await container.read(weeklyVolumeProvider.future);
    final screenBalance = await container.read(muscleBalanceProvider.future);
    final r = await GetTrainingSummaryTool(
            f.workouts, f.exercises, f.scope(), DateTime.now)
        .call({});

    expect(weeks(r).map((e) => e['total_volume_kg']),
        screenWeeks.map((e) => round2(e.totalVolume)));
    expect(
        (r['muscle_balance']! as List).map((m) => (m as Map)['volume_percent']),
        screenBalance.map((m) => round2(m.volumePercent)));
  });
}
