import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics screen', () {
    testWidgets('navigates to analytics and shows empty state', (tester) async {
      final testApp = await createTestApp();
      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to History tab.
      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();

      // Switch to Progress tab.
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Tap View Advanced Analytics.
      final analyticsLink = find.text('View Advanced Analytics');
      await pumpUntilFound(tester, analyticsLink);
      await tester.tap(analyticsLink);
      await tester.pumpAndSettle();

      // Analytics screen should show the empty state.
      expect(find.text('Not enough data yet'), findsOneWidget);

      await testApp.database.close();
    });
  });
}
