import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_heart_rate_sample.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/heart_rate/application/build_weekly_heart_report_use_case.dart';
import 'package:rep_foundry/features/heart_rate/application/weekly_heart_report.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late InMemoryWorkoutRepository workouts;
  late InMemoryCardioSessionRepository cardio;
  late InMemoryExerciseRepository exercises;
  late BuildWeeklyHeartReportUseCase useCase;

  // A Saturday morning.
  final now = DateTime(2026, 9, 19, 9);

  setUp(() {
    workouts = InMemoryWorkoutRepository();
    cardio = InMemoryCardioSessionRepository();
    exercises = InMemoryExerciseRepository();
    useCase = BuildWeeklyHeartReportUseCase(
      workoutRepository: workouts,
      cardioSessionRepository: cardio,
      exerciseRepository: exercises,
    );
  });

  Future<Workout> strength(String id, DateTime at,
      {List<(int avg, int peak)> sets = const [(130, 150)]}) async {
    final w = await workouts.createWorkout(Workout(
      id: id,
      startedAt: at,
      completedAt: at.add(const Duration(minutes: 45)),
      clientId: kSelfClientId,
      updatedAt: at,
    ));
    var order = 1;
    for (final (avg, peak) in sets) {
      await workouts.addSet(WorkoutSet.create(
        workoutId: id,
        exerciseId: '1',
        setOrder: order++,
        weight: 60,
        reps: 8,
        avgHeartRate: avg,
        peakHeartRate: peak,
      ).copyWith(timestamp: at));
    }
    return w;
  }

  Future<void> run(String id, DateTime at, List<int> bpms, {int? avg}) async {
    await workouts.createWorkout(Workout(
      id: 'w-$id',
      startedAt: at,
      completedAt: at.add(Duration(seconds: bpms.length)),
      notes: 'Cardio: Outdoor Run',
      clientId: kSelfClientId,
      updatedAt: at,
    ));
    await cardio.createSession(CardioSession(
      id: id,
      workoutId: 'w-$id',
      exerciseId: '16',
      durationSeconds: bpms.length,
      avgHeartRate: avg,
      clientId: kSelfClientId,
      updatedAt: at,
    ));
    await cardio.saveHeartRateSamples(id, [
      for (var i = 0; i < bpms.length; i++)
        CardioHeartRateSample(
            timestamp: at.add(Duration(seconds: i)), bpm: bpms[i]),
    ]);
  }

  test('covers the last seven days only', () async {
    await strength('in', now.subtract(const Duration(days: 6)));
    await strength('out', now.subtract(const Duration(days: 8)));

    final report = await useCase.execute(clientId: kSelfClientId, now: now);

    expect(report.sessions.map((s) => s.workoutId), ['in']);
  });

  test('a strength workout reports the average and peak of its set summaries',
      () async {
    await strength('a', now.subtract(const Duration(days: 1)),
        sets: [(120, 140), (140, 170)]);

    final report = await useCase.execute(clientId: kSelfClientId, now: now);

    final s = report.sessions.single;
    expect(s.kind, HeartSessionKind.strength);
    expect(s.avgBpm, 130);
    expect(s.peakBpm, 170);
  });

  test('a cardio session reports from its samples', () async {
    await run('r', now.subtract(const Duration(days: 2)), [120, 140, 160]);

    final report = await useCase.execute(clientId: kSelfClientId, now: now);

    final s = report.sessions.single;
    expect(s.kind, HeartSessionKind.cardio);
    expect(s.title, 'Treadmill');
    expect(s.avgBpm, 140);
    expect(s.peakBpm, 160);
  });

  test('workouts without any heart-rate data are left out', () async {
    await strength('none', now.subtract(const Duration(days: 1)), sets: []);
    await workouts.addSet(WorkoutSet.create(
        workoutId: 'none', exerciseId: '1', setOrder: 1, weight: 60, reps: 8));

    final report = await useCase.execute(clientId: kSelfClientId, now: now);

    expect(report.sessions, isEmpty);
    expect(report.avgBpm, isNull);
    expect(report.peakBpm, isNull);
  });

  test('weekly averages and daily peaks roll up across sessions', () async {
    await strength('a', now.subtract(const Duration(days: 1)),
        sets: [(120, 150)]);
    await run('r', now.subtract(const Duration(days: 1)), [160, 180]);
    await run('q', now.subtract(const Duration(days: 3)), [100, 110]);

    final report = await useCase.execute(clientId: kSelfClientId, now: now);

    expect(report.sessions, hasLength(3));
    expect(report.avgBpm, ((120 + 170 + 105) / 3).round());
    expect(report.peakBpm, 180);
    // Seven days, oldest first; the day before "now" is index 5.
    expect(report.dailyPeakBpm, hasLength(7));
    expect(report.dailyPeakBpm[5], 180);
    expect(report.dailyPeakBpm[3], 110);
    expect(report.dailyPeakBpm[6], isNull);
  });

  test('time in zone counts cardio samples against the given zones', () async {
    await run('r', now.subtract(const Duration(days: 1)),
        [100, 100, 150, 150, 150, 190]);
    const zones = ZoneConfiguration(
      method: ZoneMethod.percentOfEstimatedMax,
      reliability: ZoneReliability.medium,
      maxHr: 200,
      reason: 'test',
      zones: [
        CalculatedZone(
            zoneNumber: 1,
            label: 'Z1',
            effortLabel: 'Easy',
            descriptiveLabel: 'Recovery',
            lowerBound: 0,
            upperBound: 120,
            color: 0),
        CalculatedZone(
            zoneNumber: 3,
            label: 'Z3',
            effortLabel: 'Mod',
            descriptiveLabel: 'Aerobic',
            lowerBound: 120,
            upperBound: 180,
            color: 0),
        CalculatedZone(
            zoneNumber: 5,
            label: 'Z5',
            effortLabel: 'Max',
            descriptiveLabel: 'VO2',
            lowerBound: 180,
            color: 0),
      ],
    );

    final report =
        await useCase.execute(clientId: kSelfClientId, now: now, zones: zones);

    expect(report.secondsInZone, {1: 2, 3: 3, 5: 1});
  });
}
