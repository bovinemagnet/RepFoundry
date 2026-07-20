import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/widgets/scaffold_with_nav_bar.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('Ctrl+3 navigates to History on the rail layout', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/workout',
      routes: [
        ShellRoute(
          builder: (context, state, child) => ScaffoldWithNavBar(child: child),
          routes: [
            GoRoute(
              path: '/workout',
              builder: (_, __) => const Text('workout page'),
            ),
            GoRoute(
              path: '/history',
              builder: (_, __) => const Text('history page'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
    ));
    await tester.pumpAndSettle();
    expect(find.text('workout page'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('history page'), findsOneWidget);
  });
}
