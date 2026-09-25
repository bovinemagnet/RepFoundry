import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/app/router.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/core/foreground/foreground_keep_alive.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/cardio/data/fake_foreground_session_service.dart';

class _Entitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _CoachOn extends TrainerSettingsNotifier {
  @override
  TrainerSettings build() =>
      const TrainerSettings(enabled: true, disclaimerAccepted: true);
}

class _NoWorkout extends ActiveWorkoutController {
  @override
  ActiveWorkoutState build() => const ActiveWorkoutState();
}

class _WorkoutInProgress extends ActiveWorkoutController {
  @override
  ActiveWorkoutState build() =>
      ActiveWorkoutState(activeWorkout: Workout.create());
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the app shell keeps the coach alive through a workout',
      (tester) async {
    final service = FakeForegroundSessionService();
    final container = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(_Entitled()),
      trainerSettingsProvider.overrideWith(_CoachOn.new),
      activeWorkoutControllerProvider.overrideWith(_WorkoutInProgress.new),
      foregroundKeepAliveProvider
          .overrideWithValue(ForegroundKeepAlive(service)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: container.read(routerProvider),
      ),
    ));
    await tester.pump();

    expect(service.last?.coachActive, isTrue);
  });

  testWidgets('the app shell offers a one-tap workout when effort is noticed',
      (tester) async {
    final container = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(_Entitled()),
      trainerSettingsProvider.overrideWith(_CoachOn.new),
      activeWorkoutControllerProvider.overrideWith(_NoWorkout.new),
      foregroundKeepAliveProvider.overrideWithValue(
          ForegroundKeepAlive(FakeForegroundSessionService())),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: container.read(routerProvider),
      ),
    ));
    await tester.pump();

    container.read(trainerEventBusProvider).emit(const ActivityDetected());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Start workout'), findsOneWidget);
  });
}
