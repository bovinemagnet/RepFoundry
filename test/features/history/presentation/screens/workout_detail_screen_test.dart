import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
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
          workoutTemplateRepositoryProvider.overrideWithValue(templateRepo),
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
}
