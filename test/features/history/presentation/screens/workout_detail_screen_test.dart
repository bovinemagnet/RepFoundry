import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/core/share/share_files_provider.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_heart_rate_sample.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_track_point.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/history/presentation/screens/workout_detail_screen.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// An [AsyncNotifier] override that resolves the active client to the fixed
/// "Me" client, without touching the database.
class _FixedActiveClientNotifier extends ActiveClientNotifier {
  _FixedActiveClientNotifier(this._client);

  final Client _client;

  @override
  Future<Client> build() async => _client;
}

final _meClient = Client(
  id: kSelfClientId,
  name: 'Me',
  colour: 0xFF4CAF50,
  notes: null,
  isSelf: true,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  deletedAt: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen(InMemoryWorkoutRepository repo, String workoutId) {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        exerciseRepositoryProvider
            .overrideWithValue(InMemoryExerciseRepository()),
        personalRecordRepositoryProvider
            .overrideWithValue(InMemoryPersonalRecordRepository()),
        stretchingSessionRepositoryProvider
            .overrideWithValue(InMemoryStretchingSessionRepository()),
        cardioSessionRepositoryProvider
            .overrideWithValue(InMemoryCardioSessionRepository()),
        activeClientProvider.overrideWith(
          () => _FixedActiveClientNotifier(_meClient),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: WorkoutDetailScreen(workoutId: workoutId),
      ),
    );
  }

  testWidgets('shows a Continue Workout action for a completed workout',
      (tester) async {
    final repo = InMemoryWorkoutRepository();
    final now = DateTime.utc(2026, 6, 1, 9);
    await repo.createWorkout(
      Workout(
        id: 'w1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 45)),
        clientId: kSelfClientId,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(buildScreen(repo, 'w1'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byTooltip('Continue Workout'), findsOneWidget);
  });

  testWidgets('saves the workout as a template via the action', (tester) async {
    final repo = InMemoryWorkoutRepository();
    final exerciseRepo = InMemoryExerciseRepository();
    final templateRepo = InMemoryWorkoutTemplateRepository();
    final now = DateTime.utc(2026, 6, 1, 9);

    final bench = Exercise.create(
      name: 'Bench Press',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.chest,
      equipmentType: EquipmentType.barbell,
    );
    await exerciseRepo.createExercise(bench);

    await repo.createWorkout(
      Workout(
        id: 'w1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 45)),
        clientId: kSelfClientId,
        updatedAt: now,
      ),
    );
    await repo.addSet(WorkoutSet.create(
      workoutId: 'w1',
      exerciseId: bench.id,
      setOrder: 0,
      weight: 60,
      reps: 5,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(repo),
          exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
          personalRecordRepositoryProvider
              .overrideWithValue(InMemoryPersonalRecordRepository()),
          stretchingSessionRepositoryProvider
              .overrideWithValue(InMemoryStretchingSessionRepository()),
          cardioSessionRepositoryProvider
              .overrideWithValue(InMemoryCardioSessionRepository()),
          workoutTemplateRepositoryProvider.overrideWithValue(templateRepo),
          activeClientProvider.overrideWith(
            () => _FixedActiveClientNotifier(_meClient),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: WorkoutDetailScreen(workoutId: 'w1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save as Template'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'My Template');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final templates = await templateRepo.getAllTemplates();
    expect(templates, hasLength(1));
    expect(templates.single.name, 'My Template');
    expect(templates.single.exercises.single.exerciseName, 'Bench Press');
  });

  testWidgets('shows a heart rate column when sets carry HR summaries',
      (tester) async {
    final repo = InMemoryWorkoutRepository();
    final now = DateTime.utc(2026, 6, 1, 9);
    await repo.createWorkout(
      Workout(
        id: 'w1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 45)),
        clientId: kSelfClientId,
        updatedAt: now,
      ),
    );
    await repo.addSet(WorkoutSet.create(
      workoutId: 'w1',
      exerciseId: '1',
      setOrder: 1,
      weight: 60,
      reps: 5,
      avgHeartRate: 142,
      peakHeartRate: 168,
    ));
    await repo.addSet(WorkoutSet.create(
      workoutId: 'w1',
      exerciseId: '1',
      setOrder: 2,
      weight: 60,
      reps: 5,
    ));

    await tester.pumpWidget(buildScreen(repo, 'w1'));
    await tester.pumpAndSettle();

    expect(find.text('HR'), findsOneWidget);
    expect(find.text('142/168'), findsOneWidget);
  });

  testWidgets('hides the heart rate column when no set carries HR data',
      (tester) async {
    final repo = InMemoryWorkoutRepository();
    final now = DateTime.utc(2026, 6, 1, 9);
    await repo.createWorkout(
      Workout(
        id: 'w1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 45)),
        clientId: kSelfClientId,
        updatedAt: now,
      ),
    );
    await repo.addSet(WorkoutSet.create(
      workoutId: 'w1',
      exerciseId: '1',
      setOrder: 1,
      weight: 60,
      reps: 5,
    ));

    await tester.pumpWidget(buildScreen(repo, 'w1'));
    await tester.pumpAndSettle();

    expect(find.text('HR'), findsNothing);
  });

  group('cardio session review and export', () {
    final t0 = DateTime.utc(2026, 5, 1, 7, 30);

    Future<
        ({
          InMemoryWorkoutRepository workouts,
          InMemoryCardioSessionRepository cardio,
          Workout workout
        })> seedCardio({bool withRecordings = true}) async {
      final workouts = InMemoryWorkoutRepository();
      final cardio = InMemoryCardioSessionRepository();
      final workout = await workouts.createWorkout(Workout(
        id: 'w-cardio',
        startedAt: t0,
        completedAt: t0.add(const Duration(minutes: 30)),
        notes: 'Cardio: Treadmill',
        clientId: kSelfClientId,
        updatedAt: t0,
      ));
      final session = await cardio.createSession(CardioSession(
        id: 'c1',
        workoutId: workout.id,
        exerciseId: '16', // Treadmill (seeded)
        durationSeconds: 1800,
        distanceMeters: 5000,
        avgHeartRate: 145,
        clientId: kSelfClientId,
        updatedAt: t0,
      ));
      if (withRecordings) {
        await cardio.saveTrackPoints(session.id, [
          CardioTrackPoint(timestamp: t0, latitude: 51.5, longitude: -0.1),
          CardioTrackPoint(
              timestamp: t0.add(const Duration(seconds: 5)),
              latitude: 51.501,
              longitude: -0.101),
        ]);
        await cardio.saveHeartRateSamples(session.id, [
          CardioHeartRateSample(timestamp: t0, bpm: 140),
          CardioHeartRateSample(
              timestamp: t0.add(const Duration(seconds: 1)), bpm: 150),
          CardioHeartRateSample(
              timestamp: t0.add(const Duration(seconds: 2)), bpm: 145),
        ]);
      }
      return (workouts: workouts, cardio: cardio, workout: workout);
    }

    Widget buildCardioScreen(
      InMemoryWorkoutRepository workouts,
      InMemoryCardioSessionRepository cardio, {
      required List<({String name, String content})> shared,
    }) {
      return ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(workouts),
          cardioSessionRepositoryProvider.overrideWithValue(cardio),
          exerciseRepositoryProvider
              .overrideWithValue(InMemoryExerciseRepository()),
          personalRecordRepositoryProvider
              .overrideWithValue(InMemoryPersonalRecordRepository()),
          stretchingSessionRepositoryProvider
              .overrideWithValue(InMemoryStretchingSessionRepository()),
          activeClientProvider.overrideWith(
            () => _FixedActiveClientNotifier(_meClient),
          ),
          shareFilesProvider.overrideWithValue((files, names) async {
            for (var i = 0; i < files.length; i++) {
              shared.add(
                  (name: names[i], content: await files[i].readAsString()));
            }
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: WorkoutDetailScreen(workoutId: 'w-cardio'),
        ),
      );
    }

    testWidgets('shows the session stats and recording counts', (tester) async {
      final seeded = await seedCardio();
      await tester.pumpWidget(
          buildCardioScreen(seeded.workouts, seeded.cardio, shared: []));
      await tester.pumpAndSettle();

      expect(find.text('Treadmill'), findsOneWidget);
      expect(find.textContaining('30:00'), findsOneWidget);
      expect(find.textContaining('5.00 km'), findsOneWidget);
      expect(find.textContaining('145 bpm'), findsOneWidget);
      expect(find.textContaining('2 GPS points'), findsOneWidget);
      expect(find.textContaining('3 heart rate readings'), findsOneWidget);
    });

    testWidgets('Export shares a GPX track and a heart-rate CSV',
        (tester) async {
      final seeded = await seedCardio();
      final shared = <({String name, String content})>[];
      await tester.pumpWidget(
          buildCardioScreen(seeded.workouts, seeded.cardio, shared: shared));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      expect(shared.map((f) => f.name).toList()..sort(), [
        'cardio-treadmill-${_localStamp(t0)}-heart-rate.csv',
        'cardio-treadmill-${_localStamp(t0)}.gpx',
      ]);
      final gpx = shared.firstWhere((f) => f.name.endsWith('.gpx')).content;
      expect(gpx, contains('<trkpt lat="51.501" lon="-0.101">'));
      final csv = shared.firstWhere((f) => f.name.endsWith('.csv')).content;
      expect(csv, contains('2026-05-01T07:30:01.000Z,150'));
    });

    testWidgets('Export is unavailable when nothing was recorded',
        (tester) async {
      final seeded = await seedCardio(withRecordings: false);
      await tester.pumpWidget(
          buildCardioScreen(seeded.workouts, seeded.cardio, shared: []));
      await tester.pumpAndSettle();

      expect(find.text('Treadmill'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.ancestor(
            of: find.text('Export'), matching: find.byType(TextButton)),
      );
      expect(button.onPressed, isNull);
    });
  });
}

String _localStamp(DateTime utc) {
  final l = utc.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)}-${two(l.hour)}${two(l.minute)}';
}
