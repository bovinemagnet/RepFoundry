import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/programmes/domain/repositories/programme_repository.dart';
import 'package:rep_foundry/features/sync/presentation/providers/sync_settings_provider.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProgrammeRepository implements ProgrammeRepository {
  DateTime? markedStartedAt;
  String? markedProgrammeId;

  @override
  Future<void> markProgrammeStarted(
    String programmeId, {
    DateTime? startedAt,
  }) async {
    markedProgrammeId = programmeId;
    markedStartedAt = startedAt ?? DateTime.now().toUtc();
  }

  // Unused stubs
  @override
  Future<Programme> createProgramme(Programme programme) async => programme;
  @override
  Future<Programme?> getProgramme(String id) async => null;
  @override
  Future<List<Programme>> getAllProgrammes() async => [];
  @override
  Future<Programme> updateProgramme(Programme programme) async => programme;
  @override
  Future<void> deleteProgramme(String id) async {}
  @override
  Stream<List<Programme>> watchAllProgrammes() => const Stream.empty();
  @override
  Future<void> addDay(ProgrammeDay day) async {}
  @override
  Future<void> removeDay(String dayId) async {}
  @override
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId) async =>
      [];
  @override
  Future<void> addRule(ProgressionRule rule) async {}
  @override
  Future<void> removeRule(String ruleId) async {}
  @override
  Future<List<ProgressionRule>> getRulesForProgramme(
          String programmeId) async =>
      [];
}

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryPersonalRecordRepository prRepo;
  late InMemoryWorkoutTemplateRepository templateRepo;
  late _FakeProgrammeRepository programmeRepo;
  late ProviderContainer container;
  late WorkoutTemplate week1Template;
  late WorkoutTemplate week2Template;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    workoutRepo = InMemoryWorkoutRepository();
    exerciseRepo = InMemoryExerciseRepository();
    prRepo = InMemoryPersonalRecordRepository();
    templateRepo = InMemoryWorkoutTemplateRepository();
    programmeRepo = _FakeProgrammeRepository();

    week1Template = WorkoutTemplate.create(name: 'Push Week 1');
    week2Template = WorkoutTemplate.create(name: 'Pull Week 2');
    await templateRepo.createTemplate(week1Template);
    await templateRepo.createTemplate(week2Template);

    container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
        exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
        personalRecordRepositoryProvider.overrideWithValue(prRepo),
        workoutTemplateRepositoryProvider.overrideWithValue(templateRepo),
        programmeRepositoryProvider.overrideWithValue(programmeRepo),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => HealthSyncSettingsNotifier()),
        syncSettingsProvider.overrideWith(() => SyncSettingsNotifier()),
      ],
    );
  });

  tearDown(() => container.dispose());

  ActiveWorkoutController readController() {
    return container.read(activeWorkoutControllerProvider.notifier);
  }

  Future<void> waitForInit() async {
    container.read(activeWorkoutControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Programme buildTwoWeekProgramme({DateTime? startedAt}) {
    final today = DateTime.now().weekday;
    return Programme.create(name: 'Two-week split', durationWeeks: 2).copyWith(
      startedAt: startedAt,
      days: [
        ProgrammeDay.create(
          programmeId: 'p',
          weekNumber: 1,
          dayOfWeek: today,
          templateId: week1Template.id,
          templateName: week1Template.name,
        ),
        ProgrammeDay.create(
          programmeId: 'p',
          weekNumber: 2,
          dayOfWeek: today,
          templateId: week2Template.id,
          templateName: week2Template.name,
        ),
      ],
    );
  }

  group('ActiveWorkoutController.startFromProgramme', () {
    test('unstarted programme picks week 1 template and anchors startedAt',
        () async {
      await waitForInit();
      final programme = buildTwoWeekProgramme(startedAt: null);

      final started = await readController().startFromProgramme(programme);

      expect(started, isTrue);
      // Marks the programme as started so subsequent calls advance the week.
      expect(programmeRepo.markedProgrammeId, programme.id);
      expect(programmeRepo.markedStartedAt, isNotNull);
    });

    test('programme started 8 days ago picks week 2 template', () async {
      await waitForInit();
      final eightDaysAgo =
          DateTime.now().toUtc().subtract(const Duration(days: 8));
      final programme = buildTwoWeekProgramme(startedAt: eightDaysAgo);

      final started = await readController().startFromProgramme(programme);

      expect(started, isTrue);
      // Already started — must not re-anchor.
      expect(programmeRepo.markedStartedAt, isNull);
      // Active workout's templateId should be the week-2 template.
      final state = container.read(activeWorkoutControllerProvider);
      expect(state.activeWorkout?.templateId, week2Template.id);
    });

    test('programme started today picks week 1 template', () async {
      await waitForInit();
      final today = DateTime.now().toUtc();
      final programme = buildTwoWeekProgramme(startedAt: today);

      final started = await readController().startFromProgramme(programme);

      expect(started, isTrue);
      final state = container.read(activeWorkoutControllerProvider);
      expect(state.activeWorkout?.templateId, week1Template.id);
    });

    test(
        'programme with no day matching today returns false and does not '
        'anchor startedAt', () async {
      await waitForInit();
      // Build a programme with only days for tomorrow's weekday.
      final tomorrow = (DateTime.now().weekday % 7) + 1;
      final programme =
          Programme.create(name: 'Other days', durationWeeks: 2).copyWith(
        days: [
          ProgrammeDay.create(
            programmeId: 'p',
            weekNumber: 1,
            dayOfWeek: tomorrow,
            templateId: week1Template.id,
            templateName: week1Template.name,
          ),
        ],
      );

      final started = await readController().startFromProgramme(programme);

      expect(started, isFalse);
      // A no-op (unscheduled day) must NOT advance the programme clock —
      // otherwise tapping on the wrong day would burn week 1 silently.
      expect(programmeRepo.markedProgrammeId, isNull);
      expect(programmeRepo.markedStartedAt, isNull);
    });

    test('missing template returns false and does not anchor startedAt',
        () async {
      await waitForInit();
      final today = DateTime.now().weekday;
      final programme =
          Programme.create(name: 'Stale ref', durationWeeks: 2).copyWith(
        days: [
          ProgrammeDay.create(
            programmeId: 'p',
            weekNumber: 1,
            dayOfWeek: today,
            templateId: 'template-that-does-not-exist',
            templateName: 'Ghost',
          ),
        ],
      );

      final started = await readController().startFromProgramme(programme);

      expect(started, isFalse);
      expect(programmeRepo.markedProgrammeId, isNull);
    });
  });

  group('ActiveWorkoutController.startFromProgramme progression gating', () {
    late Exercise exercise;
    late WorkoutTemplate template;

    /// Seeds an exercise with a completed prior session at 100 kg so ghost
    /// sets exist, plus a template containing that exercise.
    Future<void> seedHistoryAndTemplate() async {
      exercise = Exercise.create(
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
      );
      await exerciseRepo.createExercise(exercise);

      final twoDaysAgo = DateTime.now().toUtc().subtract(
            const Duration(days: 2),
          );
      final pastWorkout = Workout.create().copyWith(
        startedAt: twoDaysAgo,
        completedAt: twoDaysAgo,
      );
      await workoutRepo.createWorkout(pastWorkout);
      await workoutRepo.addSet(WorkoutSet.create(
        workoutId: pastWorkout.id,
        exerciseId: exercise.id,
        setOrder: 0,
        weight: 100.0,
        reps: 5,
      ));

      template = WorkoutTemplate.create(name: 'Bench Day');
      template = template.copyWith(exercises: [
        TemplateExercise(
          id: 'te1',
          templateId: template.id,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          targetSets: 3,
          targetReps: 5,
          orderIndex: 0,
          updatedAt: DateTime.now().toUtc(),
        ),
      ]);
      await templateRepo.createTemplate(template);
    }

    Programme buildProgrammeWithRule({
      required DateTime startedAt,
      required int frequencyWeeks,
      int durationWeeks = 3,
    }) {
      final today = DateTime.now().weekday;
      final programme =
          Programme.create(name: 'Prog', durationWeeks: durationWeeks).copyWith(
        startedAt: startedAt,
        days: [
          for (var week = 1; week <= durationWeeks; week++)
            ProgrammeDay.create(
              programmeId: 'p',
              weekNumber: week,
              dayOfWeek: today,
              templateId: template.id,
              templateName: template.name,
            ),
        ],
      );
      return programme.copyWith(rules: [
        ProgressionRule.create(
          programmeId: programme.id,
          exerciseId: exercise.id,
          type: ProgressionType.fixedIncrement,
          value: 2.5,
          frequencyWeeks: frequencyWeeks,
        ),
      ]);
    }

    double ghostWeight() {
      final state = container.read(activeWorkoutControllerProvider);
      return state.ghostSetsByExercise[exercise.id]!.first.weight;
    }

    test('week 1 uses unprogressed ghost weights', () async {
      await waitForInit();
      await seedHistoryAndTemplate();
      final programme = buildProgrammeWithRule(
        startedAt: DateTime.now().toUtc(),
        frequencyWeeks: 2,
      );

      final started = await readController().startFromProgramme(programme);

      expect(started, isTrue);
      expect(ghostWeight(), 100.0);
    });

    test('off week (week 2 of a fortnightly rule) uses unprogressed weights',
        () async {
      await waitForInit();
      await seedHistoryAndTemplate();
      final programme = buildProgrammeWithRule(
        startedAt: DateTime.now().toUtc().subtract(const Duration(days: 8)),
        frequencyWeeks: 2,
      );

      final started = await readController().startFromProgramme(programme);

      expect(started, isTrue);
      expect(ghostWeight(), 100.0);
    });

    test('on week (week 3 of a fortnightly rule) progresses ghost weights',
        () async {
      await waitForInit();
      await seedHistoryAndTemplate();
      final programme = buildProgrammeWithRule(
        startedAt: DateTime.now().toUtc().subtract(const Duration(days: 15)),
        frequencyWeeks: 2,
      );

      final started = await readController().startFromProgramme(programme);

      expect(started, isTrue);
      expect(ghostWeight(), 102.5);
    });
  });
}
