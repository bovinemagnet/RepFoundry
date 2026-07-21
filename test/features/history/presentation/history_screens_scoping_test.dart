import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/history/presentation/screens/history_list_screen.dart';
import 'package:rep_foundry/features/history/presentation/screens/workout_detail_screen.dart';
import 'package:rep_foundry/features/history/presentation/widgets/calendar_heatmap.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the three read sites that Task 9 initially missed: the mobile
/// history tab, the PR lookup in the workout detail screen, and the calendar
/// heatmap. Each should reflect the *active* client, not always "Me".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('workoutDaysProvider reflects the active client', () async {
    SharedPreferences.setMockInitialValues({});
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final repo = container.read(workoutRepositoryProvider);
    final sarah = Client.create(name: 'Sarah', colour: 0);
    await container.read(clientRepositoryProvider).createClient(sarah);

    final mine = Workout.create();
    await repo.createWorkout(mine);
    await (database.update(database.workouts)
          ..where((t) => t.id.equals(mine.id)))
        .write(const db.WorkoutsCompanion(completedAt: Value(0)));

    await container.read(activeClientProvider.future);
    // Active = Me → sees the Me workout day.
    final asMe = await container.read(workoutDaysProvider.future);
    expect(asMe, isNotEmpty);

    // Switch to Sarah → no workout days.
    await container.read(activeClientProvider.notifier).setActive(sarah);
    final asSarah = await container.read(workoutDaysProvider.future);
    expect(asSarah, isEmpty);
  });

  testWidgets('HistoryListScreen mobile history tab reflects the active client',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final repo = container.read(workoutRepositoryProvider);
    final sarah = Client.create(name: 'Sarah', colour: 0);
    await container.read(clientRepositoryProvider).createClient(sarah);

    final now = DateTime.now().toUtc();
    final mine = Workout(
      id: 'w-me',
      startedAt: now,
      completedAt: now.add(const Duration(minutes: 30)),
      clientId: kSelfClientId,
      updatedAt: now,
    );
    await repo.createWorkout(mine);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: HistoryListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Active = Me → the completed workout shows, empty state absent.
    expect(find.text('No workouts yet'), findsNothing);

    // Switch to Sarah → back to the empty state.
    await container.read(activeClientProvider.notifier).setActive(sarah);
    await tester.pumpAndSettle();

    expect(find.text('No workouts yet'), findsOneWidget);
  });

  testWidgets(
      'WorkoutDetailScreen PR badge reflects the active client\'s records',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final workoutRepo = container.read(workoutRepositoryProvider);
    final prRepo = container.read(personalRecordRepositoryProvider);
    final sarah = Client.create(name: 'Sarah', colour: 0);
    await container.read(clientRepositoryProvider).createClient(sarah);

    final now = DateTime.now().toUtc();
    final workout = Workout(
      id: 'w-me',
      startedAt: now,
      completedAt: now.add(const Duration(minutes: 30)),
      clientId: kSelfClientId,
      updatedAt: now,
    );
    await workoutRepo.createWorkout(workout);
    final set = WorkoutSet.create(
      workoutId: workout.id,
      exerciseId: '1',
      setOrder: 0,
      weight: 100,
      reps: 5,
    );
    await workoutRepo.addSet(set);

    // A PR for "Me" tied to this set.
    await prRepo.createRecord(PersonalRecord.create(
      exerciseId: '1',
      recordType: RecordType.maxWeight,
      value: 100,
      workoutSetId: set.id,
    ));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: WorkoutDetailScreen(workoutId: workout.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Active = Me → the PR trophy badge shows for the set's exercise card.
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);

    // Switch to Sarah, who has no PRs → badge disappears.
    await container.read(activeClientProvider.notifier).setActive(sarah);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.emoji_events), findsNothing);
  });
}
