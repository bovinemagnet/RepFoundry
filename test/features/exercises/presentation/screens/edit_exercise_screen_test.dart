import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/presentation/screens/edit_exercise_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

// A fixed exercise used as the pre-existing value across all tests.
final _testExercise = Exercise(
  id: 'test-1',
  name: 'Bench Press',
  category: ExerciseCategory.strength,
  muscleGroup: MuscleGroup.chest,
  equipmentType: EquipmentType.barbell,
  isCustom: true,
  updatedAt: DateTime.utc(2025),
);

void main() {
  late InMemoryExerciseRepository fakeRepo;

  setUp(() {
    fakeRepo = InMemoryExerciseRepository();
    // Seed the repo with the exercise so updateExercise can locate it by id.
    fakeRepo.createExercise(_testExercise);
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: EditExerciseScreen(exercise: _testExercise),
      ),
    );
  }

  /// Builds a two-route app so the Navigator.pop result can be captured.
  Widget buildScreenWithNavigator(
      {required void Function(Exercise?) onPopped}) {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<Exercise>(
                  MaterialPageRoute(
                    builder: (_) => EditExerciseScreen(exercise: _testExercise),
                  ),
                );
                onPopped(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('EditExerciseScreen', () {
    testWidgets(
        'renders_withPrePopulatedFields_showsExerciseValuesAndFormLabels',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      // AppBar title and action button
      expect(find.text('Edit Exercise'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Form field labels
      expect(find.text('Exercise Name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Muscle Group'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);

      // Pre-populated values from _testExercise
      expect(find.widgetWithText(TextFormField, 'Bench Press'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Barbell'), findsOneWidget);
    });

    testWidgets('validateEmptyName_tapSave_showsValidationMessage',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      // Clear the pre-populated name field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bench Press'),
        '',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an exercise name'), findsOneWidget);
    });

    testWidgets('savesAndPops_withUpdatedName_preservesOriginalId',
        (tester) async {
      Exercise? poppedExercise;

      await tester.pumpWidget(
        buildScreenWithNavigator(onPopped: (e) => poppedExercise = e),
      );

      // Open the edit screen via the Navigator
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Replace the name with a new value
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bench Press'),
        'Incline Press',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(poppedExercise, isNotNull);
      expect(poppedExercise!.id, _testExercise.id);
      expect(poppedExercise!.name, 'Incline Press');
      // Unchanged fields should be preserved
      expect(poppedExercise!.category, ExerciseCategory.strength);
      expect(poppedExercise!.muscleGroup, MuscleGroup.chest);
      expect(poppedExercise!.equipmentType, EquipmentType.barbell);
      expect(poppedExercise!.isCustom, isTrue);
    });

    testWidgets(
        'respectsDropdownChange_muscleGroupToBack_popsWithUpdatedMuscleGroup',
        (tester) async {
      Exercise? poppedExercise;

      await tester.pumpWidget(
        buildScreenWithNavigator(onPopped: (e) => poppedExercise = e),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Change muscle group from Chest to Back
      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(poppedExercise, isNotNull);
      expect(poppedExercise!.id, _testExercise.id);
      expect(poppedExercise!.muscleGroup, MuscleGroup.back);
      // Other fields unchanged
      expect(poppedExercise!.name, 'Bench Press');
      expect(poppedExercise!.category, ExerciseCategory.strength);
      expect(poppedExercise!.equipmentType, EquipmentType.barbell);
    });
  });
}
