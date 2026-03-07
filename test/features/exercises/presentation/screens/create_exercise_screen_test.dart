import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/presentation/screens/create_exercise_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  late InMemoryExerciseRepository fakeRepo;

  setUp(() {
    fakeRepo = InMemoryExerciseRepository();
  });

  Widget buildScreen({NavigatorObserver? observer}) {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const CreateExerciseScreen(),
        navigatorObservers: observer != null ? [observer] : [],
      ),
    );
  }

  group('CreateExerciseScreen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Exercise Name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Muscle Group'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('validates empty name', (tester) async {
      await tester.pumpWidget(buildScreen());

      // Tap Create without entering a name
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an exercise name'), findsOneWidget);
    });

    testWidgets('creates exercise and pops on valid submit', (tester) async {
      Exercise? poppedExercise;

      await tester.pumpWidget(
        ProviderScope(
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
                        builder: (_) => const CreateExerciseScreen(),
                      ),
                    );
                    poppedExercise = result;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to the create screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter a name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name'),
        'Bulgarian Split Squat',
      );

      // Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should have popped back with the created exercise
      expect(poppedExercise, isNotNull);
      expect(poppedExercise!.name, 'Bulgarian Split Squat');
      expect(poppedExercise!.isCustom, isTrue);
      expect(poppedExercise!.category, ExerciseCategory.strength);
      expect(poppedExercise!.muscleGroup, MuscleGroup.chest);
      expect(poppedExercise!.equipmentType, EquipmentType.barbell);
    });

    testWidgets('respects dropdown selections', (tester) async {
      Exercise? poppedExercise;

      await tester.pumpWidget(
        ProviderScope(
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
                        builder: (_) => const CreateExerciseScreen(),
                      ),
                    );
                    poppedExercise = result;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name'),
        'Pull Up',
      );

      // Change category to Flexibility (unique label, no conflicts)
      await tester.tap(find.text('Strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flexibility').last);
      await tester.pumpAndSettle();

      // Change muscle group to Back
      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back').last);
      await tester.pumpAndSettle();

      // Change equipment to Bodyweight
      await tester.tap(find.text('Barbell'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bodyweight').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(poppedExercise, isNotNull);
      expect(poppedExercise!.name, 'Pull Up');
      expect(poppedExercise!.category, ExerciseCategory.flexibility);
      expect(poppedExercise!.muscleGroup, MuscleGroup.back);
      expect(poppedExercise!.equipmentType, EquipmentType.bodyweight);
    });
  });
}
