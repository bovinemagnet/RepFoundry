import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/presentation/widgets/hr_setup_guide_dialog.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget buildHost() {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showHrSetupGuide(context),
            child: const Text('Open guide'),
          ),
        ),
      ),
    );
  }

  group('showHrSetupGuide', () {
    testWidgets('shows the title and three device sections', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('Open guide'));
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate Setup Guide'), findsOneWidget);
      expect(find.text('Apple Watch'), findsOneWidget);
      expect(find.text('Samsung Galaxy Watch'), findsOneWidget);
      expect(find.text('Chest Straps & Arm Bands'), findsOneWidget);
    });

    testWidgets('renders numbered steps inside each device section',
        (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('Open guide'));
      await tester.pumpAndSettle();

      // Each device card shows steps starting at "1.".
      expect(find.text('1.'), findsAtLeastNWidgets(3));
      expect(find.text('2.'), findsAtLeastNWidgets(3));
      expect(find.text('3.'), findsAtLeastNWidgets(3));
    });
  });
}
