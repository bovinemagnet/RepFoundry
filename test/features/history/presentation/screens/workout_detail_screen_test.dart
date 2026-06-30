import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/history/presentation/screens/workout_detail_screen.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
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
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(buildScreen(repo, 'w1'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byTooltip('Continue Workout'), findsOneWidget);
  });
}
