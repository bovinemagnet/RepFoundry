import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/sync/presentation/providers/sync_settings_provider.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:rep_foundry/core/widgets/loading_widget.dart';
import 'package:rep_foundry/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider
            .overrideWithValue(InMemoryWorkoutRepository()),
        exerciseRepositoryProvider.overrideWithValue(
          InMemoryExerciseRepository(),
        ),
        personalRecordRepositoryProvider.overrideWithValue(
          InMemoryPersonalRecordRepository(),
        ),
        workoutTemplateRepositoryProvider.overrideWithValue(
          InMemoryWorkoutTemplateRepository(),
        ),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider.overrideWith(
          () => HealthSyncSettingsNotifier(),
        ),
        syncSettingsProvider.overrideWith(() => SyncSettingsNotifier()),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ActiveWorkoutScreen(),
      ),
    );
  }

  Exercise makeExercise(String id, String name) => Exercise(
        id: id,
        name: name,
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime(2025, 1, 1),
      );

  group('ActiveWorkoutScreen', () {
    testWidgets(
      'renders_noWorkoutState_showsStartButtonsAndNoFab',
      (tester) async {
        await tester.pumpWidget(buildScreen());

        // Settle past the initial isLoading: true microtask
        await tester.pumpAndSettle();

        expect(find.text('No active workout'), findsOneWidget);
        expect(find.text('Start Workout'), findsOneWidget);
        expect(find.text('Start Stretching'), findsOneWidget);
        expect(find.text('Start from Template'), findsOneWidget);
        expect(find.text('Start from Programme'), findsOneWidget);

        // The FAB is only shown when there is an active workout
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'showsLoadingIndicator_beforeControllerInitialises',
      (tester) async {
        await tester.pumpWidget(buildScreen());

        // The controller's build() sets isLoading: true synchronously and then
        // dispatches _init() as a microtask.  The very first frame (rendered by
        // pumpWidget) therefore shows the loading state.  We use
        // find.byType(LoadingWidget) because CircularProgressIndicator is a
        // descendant of that widget; finding it by type is more precise and does
        // not require pumping further frames that would resolve the microtask.
        expect(find.byType(LoadingWidget), findsOneWidget);
      },
    );

    testWidgets(
      'startWorkoutButton_tapped_showsActiveWorkoutTitleAndFinishButton',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        // App bar title should now include "Workout"
        expect(find.textContaining('Workout'), findsWidgets);

        // Finish action button appears in the app bar
        expect(find.text('Finish'), findsOneWidget);

        // FAB with "Add Exercise" label is visible
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Add Exercise'), findsOneWidget);
      },
    );

    testWidgets(
      'finishButton_tapped_showsConfirmationDialog',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Start a workout first so the Finish button appears
        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        // Tap the Finish text button in the app bar
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        // Confirmation dialog must contain both action buttons
        expect(find.text('Cancel'), findsOneWidget);

        // The dialog itself also has a "Finish" button (inside the AlertDialog)
        // find.text('Finish') will match both the app-bar button and the dialog
        // button, so we check there are at least two occurrences.
        expect(find.text('Finish'), findsAtLeastNWidgets(2));
      },
    );

    testWidgets(
      'handleAddExercise_scrollsNewExerciseToTop_afterAdd',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(ActiveWorkoutScreen));
        final container = ProviderScope.containerOf(element);
        final notifier =
            container.read(activeWorkoutControllerProvider.notifier);

        // Pre-fill with enough exercises to overflow the viewport.
        for (var i = 0; i < 8; i++) {
          await notifier.addExercise(makeExercise('ex-$i', 'Exercise $i'));
        }
        await tester.pumpAndSettle();

        final state = tester.state<ActiveWorkoutScreenState>(
          find.byType(ActiveWorkoutScreen),
        );
        final offsetBefore = state.scrollController.offset;

        await state.handleAddExercise(makeExercise('new-ex', 'New Exercise'));
        await tester.pumpAndSettle();

        expect(state.scrollController.offset, isNot(equals(offsetBefore)));
        expect(state.scrollController.offset, greaterThan(0.0));
      },
    );

    testWidgets(
      'handleLogSet_scrollsExerciseInputCardIntoView_afterLog',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(ActiveWorkoutScreen));
        final container = ProviderScope.containerOf(element);
        final notifier =
            container.read(activeWorkoutControllerProvider.notifier);

        // First exercise will be off-screen once we add many more.
        final target = makeExercise('target-ex', 'Target Exercise');
        await notifier.addExercise(target);
        for (var i = 0; i < 8; i++) {
          await notifier.addExercise(makeExercise('ex-$i', 'Exercise $i'));
        }
        await tester.pumpAndSettle();

        final state = tester.state<ActiveWorkoutScreenState>(
          find.byType(ActiveWorkoutScreen),
        );

        // Manually scroll past the target so the next log will need to come back up.
        state.scrollController.jumpTo(
          state.scrollController.position.maxScrollExtent,
        );
        await tester.pumpAndSettle();

        final offsetBefore = state.scrollController.offset;
        expect(offsetBefore, greaterThan(0.0));

        state.handleLogSet(
          exerciseId: 'target-ex',
          weight: 50.0,
          reps: 10,
          rpe: null,
          isWarmUp: false,
        );
        await tester.pumpAndSettle();

        // Scrolling target into view from below means offset should decrease.
        expect(state.scrollController.offset, lessThan(offsetBefore));
      },
    );

    testWidgets(
      'scrollToExercise_movesScrollOffset_whenExerciseIsBelowFold',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(ActiveWorkoutScreen));
        final container = ProviderScope.containerOf(element);
        final notifier =
            container.read(activeWorkoutControllerProvider.notifier);

        // Add enough exercises that the last one is below the fold.
        for (var i = 0; i < 10; i++) {
          await notifier.addExercise(makeExercise('ex-$i', 'Exercise $i'));
        }
        await tester.pumpAndSettle();

        final state = tester
            .state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));
        expect(state.scrollController.offset, 0.0);

        state.scrollToExercise('ex-9', alignment: 0.0);
        await tester.pumpAndSettle();

        expect(state.scrollController.offset, greaterThan(0.0));
      },
    );

    testWidgets(
      'startFromTemplate_doesNotAutoScroll_evenWithManyExercises',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(ActiveWorkoutScreen));
        final container = ProviderScope.containerOf(element);
        final notifier =
            container.read(activeWorkoutControllerProvider.notifier);

        // Pre-create exercises in the in-memory exercise repository so the
        // template can resolve them, plus matching TemplateExercise rows.
        final exerciseRepo = container.read(exerciseRepositoryProvider);
        final templateExercises = <TemplateExercise>[];
        for (var i = 0; i < 8; i++) {
          final ex = makeExercise('tmpl-ex-$i', 'Template Exercise $i');
          await exerciseRepo.createExercise(ex);
          templateExercises.add(
            TemplateExercise(
              id: 'te-$i',
              templateId: 'tmpl-1',
              exerciseId: ex.id,
              exerciseName: ex.name,
              targetSets: 3,
              targetReps: 10,
              orderIndex: i,
              updatedAt: DateTime(2025, 1, 1),
            ),
          );
        }

        final template = WorkoutTemplate(
          id: 'tmpl-1',
          name: 'Big Day',
          exercises: templateExercises,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        await notifier.startFromTemplate(template);
        await tester.pumpAndSettle();

        final state = tester.state<ActiveWorkoutScreenState>(
          find.byType(ActiveWorkoutScreen),
        );
        expect(state.scrollController.offset, 0.0);
      },
    );
  });
}
