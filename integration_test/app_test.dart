import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke tests', () {
    testWidgets('app launches and shows workout tab', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // The workout tab should be visible and selected.
      expect(find.text('WORKOUT'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('CARDIO'), findsOneWidget);
      expect(find.text('HEART RATE'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);

      await testApp.database.close();
    });

    testWidgets('can navigate between tabs', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to History tab.
      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsWidgets);

      // Navigate to Settings tab.
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);

      // Navigate back to Workout tab.
      await tester.tap(find.text('WORKOUT'));
      await tester.pumpAndSettle();
      expect(find.text('Workout'), findsWidgets);

      await testApp.database.close();
    });
  });
}
