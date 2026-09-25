import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/trainer/presentation/widgets/activity_nudge_listener.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _Entitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _RecordingWorkout extends ActiveWorkoutController {
  int starts = 0;

  @override
  ActiveWorkoutState build() => const ActiveWorkoutState();

  @override
  Future<void> startWorkout() async => starts++;
}

void main() {
  late ProviderContainer container;

  Future<void> pumpShell(WidgetTester tester) async {
    container = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(_Entitled()),
      activeWorkoutControllerProvider.overrideWith(_RecordingWorkout.new),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder: (_, __) => const ActivityNudgeListener(
            child: Scaffold(body: Text('history screen')),
          ),
        ),
        GoRoute(
          path: '/workout',
          builder: (_, __) => const Scaffold(body: Text('workout screen')),
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  void emit(TrainerEvent event) =>
      container.read(trainerEventBusProvider).emit(event);

  testWidgets('offers to start a workout when effort is noticed',
      (tester) async {
    await pumpShell(tester);

    emit(const ActivityDetected());
    await tester.pumpAndSettle();

    expect(find.text('Looks like you’re working out.'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('one tap starts a workout and opens the workout tab',
      (tester) async {
    await pumpShell(tester);
    emit(const ActivityDetected());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    final workout = container.read(activeWorkoutControllerProvider.notifier)
        as _RecordingWorkout;
    expect(workout.starts, 1);
    expect(find.text('workout screen'), findsOneWidget);
  });

  testWidgets('other coach events show nothing', (tester) async {
    await pumpShell(tester);

    emit(const WorkoutStarted());
    emit(const HeartRateSignalLost());
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });
}
