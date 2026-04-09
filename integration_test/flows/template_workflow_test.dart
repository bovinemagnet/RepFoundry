import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:rep_foundry/features/exercises/data/drift_exercise_repository.dart';
import 'package:rep_foundry/features/templates/data/drift_workout_template_repository.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Template workflow', () {
    testWidgets('start workout from template with pre-populated exercises',
        (tester) async {
      final testApp = await createTestApp();
      final db = testApp.database;

      // Get seeded exercises.
      final exerciseRepo = DriftExerciseRepository(db);
      final exercises = await exerciseRepo.getAllExercises();
      final exercise1 = exercises[0];
      final exercise2 = exercises[1];

      final now = DateTime.now().toUtc();
      const templateId = 'template-1';

      // Pre-seed a template.
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final template = WorkoutTemplate(
        id: templateId,
        name: 'Push Day',
        exercises: [
          TemplateExercise(
            id: const Uuid().v4(),
            templateId: templateId,
            exerciseId: exercise1.id,
            exerciseName: exercise1.name,
            targetSets: 3,
            targetReps: 10,
            orderIndex: 0,
            updatedAt: now,
          ),
          TemplateExercise(
            id: const Uuid().v4(),
            templateId: templateId,
            exerciseId: exercise2.id,
            exerciseName: exercise2.name,
            targetSets: 3,
            targetReps: 12,
            orderIndex: 1,
            updatedAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await templateRepo.createTemplate(template);

      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Tap "Start from Template".
      await tester.tap(find.text('Start from Template'));
      await tester.pumpAndSettle();

      // Bottom sheet should show the template.
      await pumpUntilFound(tester, find.text('Push Day'));
      expect(find.text('Push Day'), findsOneWidget);

      // Select the template.
      await tester.tap(find.text('Push Day'));
      await tester.pumpAndSettle();

      // Both exercises should be visible in the workout.
      expect(find.text(exercise1.name), findsOneWidget);
      expect(find.text(exercise2.name), findsOneWidget);

      await testApp.database.close();
    });
  });
}
