import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/presentation/widgets/trainer_disclaimer_sheet.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp() {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showTrainerDisclaimer(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'accept and decline stay reachable via scrolling on a very short '
      'viewport, with no overflow', (tester) async {
    // Regression: a bare Column with a ~340-character body could push the
    // accept/decline buttons off-screen on a short viewport. The body alone
    // must now scroll rather than overflow.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(360, 320);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(() {
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('I understand'),
      find.byType(SingleChildScrollView),
      const Offset(0, -60),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    expect(find.text('Before your coach speaks'), findsNothing);
  });

  testWidgets('declining resolves false and closes the sheet', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Before your coach speaks'), findsNothing);
  });
}
