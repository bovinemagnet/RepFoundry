import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete workout flow', () {
    testWidgets('start workout, add exercise, log sets, finish, verify history',
        (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // 1. Tap "Start Workout".
      final startButton = find.text('Start Workout');
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // 2. Should see empty workout with "Add Exercise" FAB.
      expect(find.text('Add Exercise'), findsOneWidget);

      // 3. Tap "Add Exercise" to open exercise picker.
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // 4. Should see the exercise picker with seeded exercises.
      expect(find.text('Choose Exercise'), findsOneWidget);

      // 5. Select "Barbell Bench Press".
      final benchPress = find.text('Barbell Bench Press');
      await pumpUntilFound(tester, benchPress);
      await tester.tap(benchPress);
      await tester.pumpAndSettle();

      // 6. Should return to workout with the exercise section visible.
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // 7. The weight field should be pre-filled with 0, enter 100.
      final weightField = find.widgetWithText(TextFormField, 'Weight (kg)');
      expect(weightField, findsOneWidget);
      await tester.tap(weightField);
      await tester.enterText(weightField, '100');

      // 8. Enter reps.
      final repsField = find.widgetWithText(TextFormField, 'Reps');
      await tester.tap(repsField);
      await tester.enterText(repsField, '5');

      // 9. Tap "Log Set".
      await tester.tap(find.text('Log Set'));
      await tester.pumpAndSettle();

      // 10. A set card should appear showing the weight.
      expect(find.text('100.0kg'), findsOneWidget);
      expect(find.text('x 5'), findsOneWidget);

      // 11. Log a second set.
      final weightField2 = find.widgetWithText(TextFormField, 'Weight (kg)');
      await tester.tap(weightField2);
      await tester.enterText(weightField2, '100');
      final repsField2 = find.widgetWithText(TextFormField, 'Reps');
      await tester.tap(repsField2);
      await tester.enterText(repsField2, '5');
      await tester.tap(find.text('Log Set'));
      await tester.pumpAndSettle();

      // 12. Two set cards should exist.
      expect(find.text('100.0kg'), findsNWidgets(2));

      // 13. Tap "Finish" in the app bar.
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      // 14. Confirmation dialog should appear.
      expect(find.text('Finish Workout?'), findsOneWidget);

      // 15. Confirm finish.
      final finishButtons = find.text('Finish');
      // The dialog has a "Finish" button — tap the last one (dialog button).
      await tester.tap(finishButtons.last);
      await tester.pumpAndSettle();

      // 16. Should return to no-workout state.
      expect(find.text('Start Workout'), findsOneWidget);

      // 17. Navigate to History tab.
      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();

      // 18. The completed workout should appear in the list.
      // Look for exercise name in the history tile.
      await pumpUntilFound(tester, find.text('Barbell Bench Press'));
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      await testApp.database.close();
    });
  });
}
