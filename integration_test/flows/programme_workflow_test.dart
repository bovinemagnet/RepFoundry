import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Programme workflow', () {
    testWidgets('navigate to programmes screen and see empty state',
        (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to Settings tab.
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      // Scroll to and tap Programmes.
      final programmesTile = find.text('Programmes');
      await tester.ensureVisible(programmesTile);
      await tester.tap(programmesTile);
      await tester.pumpAndSettle();

      // Programmes screen should show empty state.
      expect(find.text('No programmes yet'), findsOneWidget);

      await testApp.database.close();
    });

    testWidgets('create a programme and verify it appears', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to Settings → Programmes.
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      final programmesTile = find.text('Programmes');
      await tester.ensureVisible(programmesTile);
      await tester.tap(programmesTile);
      await tester.pumpAndSettle();

      // Tap New Programme FAB.
      await tester.tap(find.text('New Programme'));
      await tester.pumpAndSettle();

      // Fill in programme name.
      final nameField = find.widgetWithText(TextField, 'Programme Name');
      await tester.enterText(nameField, 'Test Programme');

      // Fill in duration weeks.
      final weeksField = find.widgetWithText(TextField, 'Duration (weeks)');
      await tester.enterText(weeksField, '4');

      // Tap Create.
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Programme should have been created — we land on the edit screen.
      // Navigate back to the list to verify it appears.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.text('Test Programme'));
      expect(find.text('Test Programme'), findsOneWidget);

      await testApp.database.close();
    });
  });
}
