import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Body metrics flow', () {
    testWidgets('navigate to body metrics screen', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to Settings tab.
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      // Scroll to and tap Body Metrics.
      final bodyMetricsTile = find.text('Body Metrics');
      await tester.ensureVisible(bodyMetricsTile);
      await tester.tap(bodyMetricsTile);
      await tester.pumpAndSettle();

      // Body Metrics screen should be visible.
      expect(find.text('Body Metrics'), findsWidgets);

      // Empty state should be shown.
      expect(find.text('No body metrics yet'), findsOneWidget);

      await testApp.database.close();
    });

    testWidgets('add a body metric and verify it appears', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to Settings → Body Metrics.
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      final bodyMetricsTile = find.text('Body Metrics');
      await tester.ensureVisible(bodyMetricsTile);
      await tester.tap(bodyMetricsTile);
      await tester.pumpAndSettle();

      // Tap FAB to add measurement.
      await tester.tap(find.text('Add Measurement'));
      await tester.pumpAndSettle();

      // Fill in the weight field in the dialog.
      final weightField = find.widgetWithText(TextFormField, 'Body Weight');
      await tester.enterText(weightField, '75.5');

      // Tap Save.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Metric should appear in the list.
      expect(find.textContaining('75.5'), findsWidgets);

      await testApp.database.close();
    });
  });
}
