import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/presentation/widgets/exercise_list_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildHost({
    required Exercise exercise,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ExerciseListTile(
            exercise: exercise,
            onTap: onTap,
            trailing: trailing,
          ),
        ),
      ),
    );
  }

  group('ExerciseListTile', () {
    testWidgets('renders the exercise name in the title', (tester) async {
      final exercise = Exercise.create(
        name: 'Back Squat',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.quadriceps,
        equipmentType: EquipmentType.barbell,
      );
      await tester.pumpWidget(buildHost(exercise: exercise));
      await tester.pumpAndSettle();

      expect(find.text('Back Squat'), findsOneWidget);
    });

    testWidgets('uses the strength icon when category is strength',
        (tester) async {
      final exercise = Exercise.create(
        name: 'Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.shoulders,
        equipmentType: EquipmentType.barbell,
      );
      await tester.pumpWidget(buildHost(exercise: exercise));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('uses the cardio icon when category is cardio', (tester) async {
      final exercise = Exercise.create(
        name: 'Treadmill',
        category: ExerciseCategory.cardio,
        muscleGroup: MuscleGroup.cardio,
        equipmentType: EquipmentType.bodyweight,
      );
      await tester.pumpWidget(buildHost(exercise: exercise));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.directions_run), findsOneWidget);
    });

    testWidgets('uses the flexibility icon for the flexibility category',
        (tester) async {
      final exercise = Exercise.create(
        name: 'Forward Fold',
        category: ExerciseCategory.flexibility,
        muscleGroup: MuscleGroup.quadriceps,
        equipmentType: EquipmentType.bodyweight,
      );
      await tester.pumpWidget(buildHost(exercise: exercise));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    });

    testWidgets('forwards onTap to the underlying ListTile', (tester) async {
      var taps = 0;
      final exercise = Exercise.create(
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
      );
      await tester.pumpWidget(buildHost(
        exercise: exercise,
        onTap: () => taps++,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('renders the trailing widget when supplied', (tester) async {
      final exercise = Exercise.create(
        name: 'Row',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.back,
        equipmentType: EquipmentType.barbell,
      );
      await tester.pumpWidget(buildHost(
        exercise: exercise,
        trailing: const Icon(Icons.chevron_right),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}
