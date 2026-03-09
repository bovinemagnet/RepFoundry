import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/templates/data/drift_workout_template_repository.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:uuid/uuid.dart';

void main() {
  late db.AppDatabase database;
  late DriftWorkoutTemplateRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftWorkoutTemplateRepository(database);
  });

  tearDown(() => database.close());

  WorkoutTemplate newTemplate({
    String name = 'Push Day',
    List<TemplateExercise>? exercises,
  }) {
    final template = WorkoutTemplate.create(name: name);
    if (exercises != null) {
      return template.copyWith(exercises: exercises);
    }
    return template;
  }

  TemplateExercise newTemplateExercise({
    required String templateId,
    String exerciseId = '1', // Barbell Bench Press (seeded)
    String exerciseName = 'Barbell Bench Press',
    int targetSets = 3,
    int targetReps = 10,
    int orderIndex = 0,
  }) {
    return TemplateExercise(
      id: const Uuid().v4(),
      templateId: templateId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      targetSets: targetSets,
      targetReps: targetReps,
      orderIndex: orderIndex,
      updatedAt: DateTime.utc(2024),
    );
  }

  group('DriftWorkoutTemplateRepository', () {
    group('createTemplate & getTemplate', () {
      test('persists and retrieves a template without exercises', () async {
        final template = newTemplate();
        await repo.createTemplate(template);

        final fetched = await repo.getTemplate(template.id);
        expect(fetched, isNotNull);
        expect(fetched!.id, template.id);
        expect(fetched.name, 'Push Day');
        expect(fetched.exercises, isEmpty);
      });

      test('persists and retrieves a template with exercises', () async {
        final template = newTemplate();
        final withExercises = template.copyWith(
          exercises: [
            newTemplateExercise(
              templateId: template.id,
              exerciseId: '1',
              exerciseName: 'Barbell Bench Press',
              orderIndex: 0,
            ),
            newTemplateExercise(
              templateId: template.id,
              exerciseId: '5',
              exerciseName: 'Overhead Press',
              orderIndex: 1,
            ),
          ],
        );
        await repo.createTemplate(withExercises);

        final fetched = await repo.getTemplate(template.id);
        expect(fetched, isNotNull);
        expect(fetched!.exercises, hasLength(2));
        expect(fetched.exercises.first.orderIndex, 0);
        expect(fetched.exercises.last.orderIndex, 1);
      });

      test('returns null for non-existent id', () async {
        final fetched = await repo.getTemplate('non-existent');
        expect(fetched, isNull);
      });
    });

    group('getAllTemplates', () {
      test('returns all templates newest first', () async {
        await repo.createTemplate(newTemplate(name: 'Push Day'));
        await repo.createTemplate(newTemplate(name: 'Pull Day'));

        final all = await repo.getAllTemplates();
        expect(all, hasLength(2));
        // Newest first (by createdAt desc).
        expect(
          all.first.createdAt.isAfter(all.last.createdAt) ||
              all.first.createdAt.isAtSameMomentAs(all.last.createdAt),
          isTrue,
        );
      });
    });

    group('updateTemplate', () {
      test('updates name and replaces exercises', () async {
        final template = newTemplate();
        final withExercise = template.copyWith(
          exercises: [
            newTemplateExercise(
              templateId: template.id,
              exerciseId: '1',
              exerciseName: 'Barbell Bench Press',
            ),
          ],
        );
        await repo.createTemplate(withExercise);

        final updated = template.copyWith(
          name: 'Updated Push Day',
          updatedAt: DateTime.now().toUtc(),
          exercises: [
            newTemplateExercise(
              templateId: template.id,
              exerciseId: '5',
              exerciseName: 'Overhead Press',
              orderIndex: 0,
            ),
            newTemplateExercise(
              templateId: template.id,
              exerciseId: '9',
              exerciseName: 'Incline Dumbbell Press',
              orderIndex: 1,
            ),
          ],
        );
        await repo.updateTemplate(updated);

        final fetched = await repo.getTemplate(template.id);
        expect(fetched!.name, 'Updated Push Day');
        expect(fetched.exercises, hasLength(2));
        expect(fetched.exercises.first.exerciseName, 'Overhead Press');
      });
    });

    group('deleteTemplate', () {
      test('hard-deletes template and its exercises', () async {
        final template = newTemplate();
        final withExercise = template.copyWith(
          exercises: [
            newTemplateExercise(
              templateId: template.id,
              exerciseId: '1',
              exerciseName: 'Barbell Bench Press',
            ),
          ],
        );
        await repo.createTemplate(withExercise);
        await repo.deleteTemplate(template.id);

        final fetched = await repo.getTemplate(template.id);
        expect(fetched, isNull);
      });
    });

    group('watchAllTemplates', () {
      test('emits when templates change', () async {
        final emissions = <List<WorkoutTemplate>>[];
        final sub = repo.watchAllTemplates().listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        expect(emissions, hasLength(1));
        expect(emissions.first, isEmpty);

        await repo.createTemplate(newTemplate());
        await pumpEventQueue();

        expect(emissions.last, hasLength(1));
      });
    });
  });
}
