import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';

void main() {
  // Helper that constructs a minimal TemplateExercise for use across tests.
  TemplateExercise makeExercise({
    String id = 'ex-id-1',
    String templateId = 'tmpl-id-1',
  }) {
    return TemplateExercise(
      id: id,
      templateId: templateId,
      exerciseId: 'exercise-uuid-1',
      exerciseName: 'Bench Press',
      targetSets: 3,
      targetReps: 8,
      orderIndex: 0,
      updatedAt: DateTime.utc(2024, 1, 1),
    );
  }

  group('WorkoutTemplate', () {
    test('create() sets a non-empty UUID id and UTC timestamps', () {
      final before = DateTime.now().toUtc();
      final template = WorkoutTemplate.create(name: 'Push Day');
      final after = DateTime.now().toUtc();

      expect(template.id, isNotEmpty);
      // UUIDs are 36 characters in canonical form (8-4-4-4-12 + 4 hyphens).
      expect(template.id.length, 36);
      expect(template.name, 'Push Day');

      // Both timestamps must be UTC and fall within the bracketing window.
      expect(template.createdAt.isUtc, isTrue);
      expect(template.updatedAt.isUtc, isTrue);
      expect(
        template.createdAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        template.createdAt.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
      expect(template.updatedAt, template.createdAt);
    });

    test('create() with exercises list preserves the supplied exercises', () {
      final exercise = makeExercise();
      final template = WorkoutTemplate.create(
        name: 'Leg Day',
        exercises: [exercise],
      );

      expect(template.exercises, hasLength(1));
      expect(template.exercises.first, same(exercise));
    });

    test('create() without exercises defaults to an empty list', () {
      final template = WorkoutTemplate.create(name: 'Rest Day');

      expect(template.exercises, isEmpty);
    });

    test('copyWith changes name while preserving id and exercises', () {
      final exercise = makeExercise();
      final original = WorkoutTemplate.create(
        name: 'Original Name',
        exercises: [exercise],
      );

      final copy = original.copyWith(name: 'Updated Name');

      expect(copy.id, original.id);
      expect(copy.name, 'Updated Name');
      expect(copy.exercises, original.exercises);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith replaces the exercises list when supplied', () {
      final first = makeExercise(id: 'ex-1', templateId: 'tmpl-1');
      final second = makeExercise(id: 'ex-2', templateId: 'tmpl-1');
      final original = WorkoutTemplate.create(
        name: 'Push Day',
        exercises: [first],
      );

      final copy = original.copyWith(exercises: [first, second]);

      expect(copy.exercises, hasLength(2));
      expect(copy.exercises.last, same(second));
      // Original is unaffected.
      expect(original.exercises, hasLength(1));
    });

    test('equality — same id yields equal instances, different id does not',
        () {
      const fixedTime = Duration(hours: 0);
      final now = DateTime.utc(2024, 6, 1);

      final a = WorkoutTemplate(
        id: 'same-id',
        name: 'Template A',
        createdAt: now,
        updatedAt: now.add(fixedTime),
      );
      final b = WorkoutTemplate(
        id: 'same-id',
        name: 'Template B', // name differs intentionally
        createdAt: now,
        updatedAt: now,
      );
      final c = WorkoutTemplate(
        id: 'different-id',
        name: 'Template A',
        createdAt: now,
        updatedAt: now,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('two create() calls produce different ids', () {
      final first = WorkoutTemplate.create(name: 'Template 1');
      final second = WorkoutTemplate.create(name: 'Template 2');

      expect(first.id, isNot(second.id));
    });
  });

  group('TemplateExercise', () {
    test('constructor exposes all supplied fields correctly', () {
      final updatedAt = DateTime.utc(2024, 3, 15, 10, 0);
      final exercise = TemplateExercise(
        id: 'te-uuid-1',
        templateId: 'tmpl-uuid-1',
        exerciseId: 'ex-uuid-99',
        exerciseName: 'Squat',
        targetSets: 4,
        targetReps: 6,
        orderIndex: 2,
        updatedAt: updatedAt,
      );

      expect(exercise.id, 'te-uuid-1');
      expect(exercise.templateId, 'tmpl-uuid-1');
      expect(exercise.exerciseId, 'ex-uuid-99');
      expect(exercise.exerciseName, 'Squat');
      expect(exercise.targetSets, 4);
      expect(exercise.targetReps, 6);
      expect(exercise.orderIndex, 2);
      expect(exercise.updatedAt, updatedAt);
    });
  });
}
