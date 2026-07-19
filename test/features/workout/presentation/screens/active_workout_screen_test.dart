import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rep_foundry/core/heart_rate/hr_session_recorder.dart';
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

import '../../../cardio/data/fake_heart_rate_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen({bool wrapInOuterScaffold = false}) {
    // When [wrapInOuterScaffold] is true the screen is nested inside an outer
    // Scaffold, mirroring the production ShellRoute's ScaffoldWithNavBar. The
    // outer Scaffold consumes (zeroes) the keyboard's bottom viewInsets for its
    // body, so the inner screen cannot detect the keyboard via
    // MediaQuery.viewInsetsOf — this is the condition the FAB-hide guard must
    // survive.
    const screen = ActiveWorkoutScreen();
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
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: wrapInOuterScaffold ? const Scaffold(body: screen) : screen,
      ),
    );
  }

  Exercise makeExercise(
    String id,
    String name, {
    EquipmentType equipmentType = EquipmentType.barbell,
  }) =>
      Exercise(
        id: id,
        name: name,
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: equipmentType,
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
      'addExerciseFab_hidesWhenKeyboardOpen_evenNestedInOuterScaffold',
      (tester) async {
        // Reproduces the production layout: the screen is nested inside an
        // outer Scaffold (ScaffoldWithNavBar) which consumes the keyboard's
        // bottom viewInset for its body. The "Add Exercise" FAB must still hide
        // when the keyboard opens so it does not cover the "Log Set" button.
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(buildScreen(wrapInOuterScaffold: true));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        // With no keyboard the FAB is visible.
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // Simulate the soft keyboard opening.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        // The FAB must be gone so it cannot overlap the Log Set CTA.
        expect(find.byType(FloatingActionButton), findsNothing);

        // Closing the keyboard brings the FAB back.
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsOneWidget);
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
      'newlyAddedExercise_isExpanded_previousCollapsesToAddSet',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        final state = tester
            .state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));

        await state.handleAddExercise(makeExercise('ex-a', 'Exercise A'));
        await tester.pumpAndSettle();
        await state.handleAddExercise(makeExercise('ex-b', 'Exercise B'));
        await tester.pumpAndSettle();

        // Only the most-recently-added exercise shows the Log Set input.
        expect(find.text('LOG SET'), findsOneWidget);
        // The previous exercise collapses to a compact Add Set affordance.
        expect(find.text('ADD SET'), findsOneWidget);
      },
    );

    testWidgets(
      'tappingAddSet_expandsThatExercise_andCollapsesOthers',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        final state = tester
            .state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));

        await state.handleAddExercise(makeExercise('ex-a', 'Exercise A'));
        await tester.pumpAndSettle();
        await state.handleAddExercise(makeExercise('ex-b', 'Exercise B'));
        await tester.pumpAndSettle();

        // Exercise A is collapsed — tapping its Add Set expands it.
        await tester.tap(find.text('ADD SET'));
        await tester.pumpAndSettle();

        // Still exactly one expanded input, and one collapsed affordance:
        // expansion moved from B to A rather than stacking two inputs.
        expect(find.text('LOG SET'), findsOneWidget);
        expect(find.text('ADD SET'), findsOneWidget);
      },
    );

    testWidgets(
      'tappingCollapse_hidesSetInput_leavingAllExercisesCollapsed',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();

        final state = tester
            .state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen));

        await state.handleAddExercise(makeExercise('ex-a', 'Exercise A'));
        await tester.pumpAndSettle();
        await state.handleAddExercise(makeExercise('ex-b', 'Exercise B'));
        await tester.pumpAndSettle();

        // Collapse the expanded exercise via its close control.
        await tester.tap(find.byTooltip('Collapse'));
        await tester.pumpAndSettle();

        // No input is shown; both exercises now offer Add Set.
        expect(find.text('LOG SET'), findsNothing);
        expect(find.text('ADD SET'), findsNWidgets(2));
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

  group('heart rate chip', () {
    testWidgets('logged set shows avg/peak BPM captured from the monitor',
        (tester) async {
      final hrService = FakeHeartRateService();
      addTearDown(hrService.dispose);

      await tester.pumpWidget(
        ProviderScope(
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
            heartRateServiceProvider.overrideWithValue(hrService),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: ActiveWorkoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(ActiveWorkoutScreen));
      final container = ProviderScope.containerOf(element);
      // Start the recorder buffering before readings arrive.
      container.read(hrSessionRecorderProvider.notifier);
      final notifier = container.read(activeWorkoutControllerProvider.notifier);

      await notifier.startWorkout();
      await notifier.addExercise(makeExercise('ex-1', 'Bench Press'));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        hrService.emitHeartRate(130);
        hrService.emitHeartRate(150);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await notifier.logSet(exerciseId: 'ex-1', weight: 100, reps: 5);
      });
      await tester.pumpAndSettle();

      expect(find.text('♥ 140/150'), findsOneWidget);
    });

    testWidgets('logged set without HR data shows no heart chip',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(ActiveWorkoutScreen));
      final container = ProviderScope.containerOf(element);
      final notifier = container.read(activeWorkoutControllerProvider.notifier);

      await notifier.startWorkout();
      await notifier.addExercise(makeExercise('ex-1', 'Bench Press'));
      await notifier.logSet(exerciseId: 'ex-1', weight: 100, reps: 5);
      await tester.pumpAndSettle();

      expect(find.textContaining('♥'), findsNothing);
    });
  });

  group('swipe navigation', () {
    Widget buildRouterScreen() {
      final router = GoRouter(
        initialLocation: '/workout',
        routes: [
          GoRoute(
            path: '/workout',
            builder: (context, state) => const ActiveWorkoutScreen(),
          ),
          GoRoute(
            path: '/heart-rate',
            builder: (context, state) =>
                const Scaffold(body: Text('heart-rate destination')),
          ),
        ],
      );
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
        child: MaterialApp.router(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    testWidgets('leftward fling navigates to the heart rate panel',
        (tester) async {
      await tester.pumpWidget(buildRouterScreen());
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(ActiveWorkoutScreen),
        const Offset(-300, 0),
        1200,
      );
      await tester.pumpAndSettle();

      expect(find.text('heart-rate destination'), findsOneWidget);
    });

    testWidgets('rightward fling stays on the workout screen', (tester) async {
      await tester.pumpWidget(buildRouterScreen());
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(ActiveWorkoutScreen),
        const Offset(300, 0),
        1200,
      );
      await tester.pumpAndSettle();

      expect(find.text('heart-rate destination'), findsNothing);
      expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
    });
  });

  group('warm-up ramp', () {
    Future<void> startWithExercise(
      WidgetTester tester,
      Exercise exercise,
    ) async {
      // Pin kg so ramp weights are deterministic regardless of test locale.
      SharedPreferences.setMockInitialValues({'weight_unit': 'kg'});
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();

      final state = tester.state<ActiveWorkoutScreenState>(
        find.byType(ActiveWorkoutScreen),
      );
      await state.handleAddExercise(exercise);
      await tester.pumpAndSettle();
      // Let the input card's 350 ms autofocus timer fire so it isn't left
      // pending when the test disposes.
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('action is hidden for bodyweight exercises', (tester) async {
      await startWithExercise(
        tester,
        makeExercise('bw', 'Pull-up', equipmentType: EquipmentType.bodyweight),
      );

      expect(find.text('ADD WARM-UP'), findsNothing);
    });

    testWidgets('barbell exercise previews and inserts a ramp', (tester) async {
      await startWithExercise(
        tester,
        makeExercise('bb', 'Bench Press'),
      );

      // Enter a working weight so the ramp has a basis.
      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.pumpAndSettle();

      expect(find.text('ADD WARM-UP'), findsOneWidget);
      await tester.tap(find.text('ADD WARM-UP'));
      await tester.pumpAndSettle();

      // Preview sheet lists the computed ramp steps.
      expect(find.textContaining('× 10'), findsOneWidget); // bar × 10
      expect(find.text('ADD 4 WARM-UP SETS'), findsOneWidget);

      await tester.tap(find.text('ADD 4 WARM-UP SETS'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ActiveWorkoutScreen)),
      );
      final sets =
          container.read(activeWorkoutControllerProvider).setsByExercise['bb']!;
      expect(sets, hasLength(4));
      expect(sets.every((s) => s.isWarmUp), isTrue);
      expect(sets.map((s) => s.setOrder), orderedEquals([1, 2, 3, 4]));
      expect(sets.first.weight, 20.0); // empty bar
      expect(sets.last.weight, 80.0); // 80% of 100
    });
  });
}
