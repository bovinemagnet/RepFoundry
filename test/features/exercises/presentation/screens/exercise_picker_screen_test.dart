import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/presentation/screens/exercise_picker_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  late InMemoryExerciseRepository fakeRepo;

  setUp(() {
    fakeRepo = InMemoryExerciseRepository();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ExercisePickerScreen(),
      ),
    );
  }

  group('ExercisePickerScreen', () {
    testWidgets('renders_exerciseList_showsTitleAndDefaultExercise',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // AppBar title is present
      expect(find.text('Choose Exercise'), findsOneWidget);

      // At least one default exercise from the in-memory repo is visible.
      // 'Barbell Bench Press' is alphabetically first among the defaults.
      expect(find.text('Barbell Bench Press'), findsOneWidget);
    });

    testWidgets('showsFilterChips_allChipIsPresentAndSelected', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The "All" FilterChip must always be present and be selected by default.
      expect(
        find.widgetWithText(FilterChip, 'All'),
        findsOneWidget,
      );

      final allChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'All'),
      );
      expect(allChip.selected, isTrue);
    });

    testWidgets('showsFilterChips_muscleGroupChipsArePresent', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // At least one MuscleGroup chip should be visible in the filter bar.
      // 'chest' is the .name of MuscleGroup.chest.
      expect(
        find.widgetWithText(FilterChip, 'chest'),
        findsOneWidget,
      );
    });

    testWidgets('searchFiltersResults_showsMatchingAndHidesNonMatching',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter a search query that matches only squat-related exercises.
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Squat');
      await tester.pumpAndSettle();

      // 'Barbell Squat' is in the default list and matches the query.
      expect(find.text('Barbell Squat'), findsOneWidget);

      // 'Barbell Bench Press' does not contain 'Squat' and must not be shown.
      expect(find.text('Barbell Bench Press'), findsNothing);

      // 'Deadlift' also does not match.
      expect(find.text('Deadlift'), findsNothing);
    });

    testWidgets('searchFiltersResults_noMatchShowsEmptyState', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'xyznonexistentexercise');
      await tester.pumpAndSettle();

      expect(find.text('No exercises found'), findsOneWidget);
    });

    testWidgets('tappingExercise_popsWithThatExercise', (tester) async {
      Exercise? poppedExercise;

      // Use the Builder/Navigator pattern so we can capture the popped value.
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
                        builder: (_) => const ExercisePickerScreen(),
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

      // Navigate to the picker screen.
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the first default exercise that is rendered.
      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();

      // The screen must have popped and returned the tapped exercise.
      expect(poppedExercise, isNotNull);
      expect(poppedExercise!.name, 'Barbell Bench Press');
    });

    testWidgets('fab_showsCustomLabel', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The FAB must display "Custom" as its label.
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('muscleGroupFilter_selectingChipFiltersListToMatchingExercises',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The filter bar scrolls horizontally; ensure the 'chest' chip is
      // visible before tapping it.
      await tester.ensureVisible(
        find.widgetWithText(FilterChip, 'chest'),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'chest'));
      await tester.pumpAndSettle();

      // Chest exercises should be visible.
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Cable Fly'), findsOneWidget);

      // Exercises belonging to other muscle groups must not be shown.
      expect(find.text('Deadlift'), findsNothing);
      expect(find.text('Pull-up'), findsNothing);
    });

    testWidgets('editIcon_isNotShownForDefaultNonCustomExercises',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Default exercises have isCustom == false; they should show a
      // chevron_right icon, not an edit icon.
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('editIcon_isShownForCustomExercise', (tester) async {
      // Name starting with 'A' so the custom exercise appears at the top of
      // the alphabetically sorted list — no scrolling required.
      final customExercise = Exercise(
        id: 'custom-1',
        name: 'AAA Custom Exercise',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.bodyweight,
        isCustom: true,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      await fakeRepo.createExercise(customExercise);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The custom exercise is at the top of the list without scrolling.
      expect(find.text('AAA Custom Exercise'), findsOneWidget);

      // An edit icon must be present for this custom exercise.
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}
