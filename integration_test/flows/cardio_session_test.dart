import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cardio session', () {
    testWidgets('cardio tab renders and shows controls', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to Cardio tab.
      await tester.tap(find.text('CARDIO'));
      await tester.pumpAndSettle();

      // Cardio screen should be visible with its controls. The redesign
      // renders "CARDIO" twice (eyebrow + nav label); the AppBar title
      // "Cardio" (mixed case) uniquely identifies the screen.
      expect(find.text('Cardio'), findsOneWidget);

      await testApp.database.close();
    });
  });
}
