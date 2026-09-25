import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/sync/presentation/providers/sync_settings_provider.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/trainer/domain/tempo_cue.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Entitlements implements EntitlementService {
  _Entitlements(this.entitled);
  final bool entitled;

  @override
  bool has(Entitlement entitlement) => entitled;
}

class _Settings extends TrainerSettingsNotifier {
  _Settings(this._seed);
  final TrainerSettings _seed;

  @override
  TrainerSettings build() => _seed;
}

const _coachOn = TrainerSettings(enabled: true, disclaimerAccepted: true);

void main() {
  late List<RepTempo> spoken;

  Future<void> startWithBench(
    WidgetTester tester, {
    TrainerSettings settings = _coachOn,
    bool entitled = true,
  }) async {
    SharedPreferences.setMockInitialValues({'weight_unit': 'kg'});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        workoutRepositoryProvider
            .overrideWithValue(InMemoryWorkoutRepository()),
        exerciseRepositoryProvider
            .overrideWithValue(InMemoryExerciseRepository()),
        personalRecordRepositoryProvider
            .overrideWithValue(InMemoryPersonalRecordRepository()),
        workoutTemplateRepositoryProvider
            .overrideWithValue(InMemoryWorkoutTemplateRepository()),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => HealthSyncSettingsNotifier()),
        syncSettingsProvider.overrideWith(() => SyncSettingsNotifier()),
        entitlementServiceProvider.overrideWithValue(_Entitlements(entitled)),
        trainerSettingsProvider.overrideWith(() => _Settings(settings)),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ActiveWorkoutScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    spoken = [];
    ProviderScope.containerOf(tester.element(find.byType(ActiveWorkoutScreen)))
        .read(trainerEventBusProvider)
        .events
        .listen((e) {
      if (e is RepTempo) spoken.add(e);
    });
    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    await tester
        .state<ActiveWorkoutScreenState>(find.byType(ActiveWorkoutScreen))
        .handleAddExercise(
          Exercise(
            id: 'bb',
            name: 'Bench Press',
            category: ExerciseCategory.strength,
            muscleGroup: MuscleGroup.chest,
            equipmentType: EquipmentType.barbell,
            updatedAt: DateTime(2025),
          ),
        );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> setReps(WidgetTester tester, String reps) async {
    await tester.enterText(find.byType(TextFormField).at(1), reps);
    await tester.pumpAndSettle();
  }

  Future<void> tapAction(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pump();
  }

  String repsField(WidgetTester tester) => tester
      .widget<EditableText>(find.byType(EditableText).at(1))
      .controller
      .text;

  testWidgets('is not offered while the coach is off', (tester) async {
    await startWithBench(
      tester,
      settings: const TrainerSettings(disclaimerAccepted: true),
    );

    expect(find.text('LOG SET'), findsOneWidget);
    expect(find.text('COUNT REPS'), findsNothing);
  });

  testWidgets('is not offered before the safety notice is accepted',
      (tester) async {
    await startWithBench(
      tester,
      settings: const TrainerSettings(enabled: true),
    );

    expect(find.text('COUNT REPS'), findsNothing);
  });

  testWidgets('is not offered without the trainer entitlement', (tester) async {
    await startWithBench(tester, entitled: false);

    expect(find.text('COUNT REPS'), findsNothing);
  });

  testWidgets('logging the set stops the count', (tester) async {
    await startWithBench(tester);
    await tester.enterText(find.byType(TextFormField).first, '100');
    await setReps(tester, '8');

    await tapAction(tester, 'COUNT REPS');
    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(find.text('LOG SET'));
    await tester.tap(find.text('LOG SET'));
    await tester.pump(const Duration(seconds: 30));

    expect(spoken, hasLength(1));
  });

  testWidgets('counts the reps in the field at the set pace, then says done',
      (tester) async {
    await startWithBench(tester);
    await setReps(tester, '3');

    await tapAction(tester, 'COUNT REPS');
    expect(find.text('STOP COUNT'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(spoken.map((e) => (e.cue, e.value)), [(TempoCueKind.count, 1)]);
    await tester.pump(const Duration(seconds: 6));

    expect(spoken.map((e) => (e.cue, e.value)), [
      (TempoCueKind.count, 1),
      (TempoCueKind.count, 2),
      (TempoCueKind.done, 3),
    ]);
    expect(repsField(tester), '3');
    expect(find.text('COUNT REPS'), findsOneWidget);
  });

  testWidgets('stopping early fills in the reps actually done', (tester) async {
    await startWithBench(tester);
    await setReps(tester, '8');

    await tapAction(tester, 'COUNT REPS');
    await tester.pump(const Duration(seconds: 7));
    await tapAction(tester, 'STOP COUNT');
    await tester.pump(const Duration(seconds: 30));

    expect(repsField(tester), '2');
    expect(spoken, hasLength(2));
    expect(find.text('COUNT REPS'), findsOneWidget);
  });

  testWidgets('follows the pace, direction and pauses from settings',
      (tester) async {
    await startWithBench(
      tester,
      settings: const TrainerSettings(
        enabled: true,
        disclaimerAccepted: true,
        tempoSecondsPerRep: 2,
        tempoCountDown: true,
        tempoClusterSize: 1,
        tempoClusterPauseSeconds: 5,
      ),
    );
    await setReps(tester, '3');

    await tapAction(tester, 'COUNT REPS');
    await tester.pump(const Duration(seconds: 2));
    expect(spoken.single.cue, TempoCueKind.rest);
    expect(spoken.single.value, 5);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));

    expect(spoken.map((e) => (e.cue, e.value, e.countingDown)), [
      (TempoCueKind.rest, 5, true),
      (TempoCueKind.resume, 0, true),
      (TempoCueKind.rest, 5, true),
    ]);
    await tapAction(tester, 'STOP COUNT');
  });
}
