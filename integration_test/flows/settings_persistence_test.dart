import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings persistence', () {
    testWidgets('settings screen renders and allows navigation',
        (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to Settings tab.
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      // Settings screen should be visible.
      expect(find.text('Settings'), findsWidgets);

      // Navigate to About screen if available.
      final aboutTile = find.text('About');
      if (tester.any(aboutTile)) {
        await tester.ensureVisible(aboutTile);
        await tester.tap(aboutTile);
        await tester.pumpAndSettle();

        // Should show the About screen.
        expect(find.text('RepFoundry'), findsWidgets);

        // Navigate back.
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }

      // Navigate away and back to verify screen survives navigation.
      await tester.tap(find.text('WORKOUT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);

      await testApp.database.close();
    });
  });
}
