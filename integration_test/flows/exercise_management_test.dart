import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise management', () {
    testWidgets('search exercises by name', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Start workout to access exercise picker.
      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Should see exercise picker.
      expect(find.text('Choose Exercise'), findsOneWidget);

      // Wait for exercises to load.
      await pumpUntilFound(tester, find.text('Barbell Bench Press'));

      // Type "bench" in the search field.
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'bench');
      await tester.pumpAndSettle();

      // Should find bench press in filtered results.
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // Clear search.
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // All exercises should return — verify a different exercise is visible.
      await pumpUntilFound(tester, find.text('Barbell Squat'));
      expect(find.text('Barbell Squat'), findsOneWidget);

      await testApp.database.close();
    });

    testWidgets('filter exercises by muscle group', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to exercise picker.
      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Wait for exercises to load.
      await pumpUntilFound(tester, find.text('Barbell Bench Press'));

      // Tap the "chest" filter chip.
      final chestChip = find.text('chest');
      await tester.ensureVisible(chestChip);
      await tester.tap(chestChip);
      await tester.pumpAndSettle();

      // Should only show chest exercises — bench press should be visible.
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // Reset filter by tapping "All".
      final allChip = find.text('All');
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      // Non-chest exercises should be visible again.
      await pumpUntilFound(tester, find.text('Barbell Squat'));
      expect(find.text('Barbell Squat'), findsOneWidget);

      await testApp.database.close();
    });
  });
}
