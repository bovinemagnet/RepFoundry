import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/widgets/scaffold_with_nav_bar.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter buildRouter() {
    Widget label(String text) => Scaffold(body: Text(text));

    return GoRouter(
      initialLocation: '/workout',
      routes: [
        ShellRoute(
          builder: (_, __, child) => ScaffoldWithNavBar(child: child),
          routes: [
            GoRoute(path: '/workout', builder: (_, __) => label('Workout tab')),
            GoRoute(path: '/history', builder: (_, __) => label('History tab')),
            GoRoute(path: '/cardio', builder: (_, __) => label('Cardio tab')),
            GoRoute(
              path: '/heart-rate',
              builder: (_, __) => label('Heart Rate tab'),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => label('Settings tab'),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildApp(GoRouter router) {
    return MaterialApp.router(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      routerConfig: router,
    );
  }

  group('ScaffoldWithNavBar', () {
    testWidgets('renders all five nav labels in uppercase', (tester) async {
      await tester.pumpWidget(buildApp(buildRouter()));
      await tester.pumpAndSettle();

      // Labels are rendered uppercased by the nav bar.
      expect(find.text('WORKOUT'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('CARDIO'), findsOneWidget);
      expect(find.text('HEART RATE'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('renders all five nav icons', (tester) async {
      await tester.pumpWidget(buildApp(buildRouter()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.directions_run), findsOneWidget);
      expect(find.byIcon(Icons.monitor_heart), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('initial location /workout shows the workout child',
        (tester) async {
      await tester.pumpWidget(buildApp(buildRouter()));
      await tester.pumpAndSettle();

      expect(find.text('Workout tab'), findsOneWidget);
    });

    testWidgets('tapping HISTORY navigates to /history', (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/history');
      expect(find.text('History tab'), findsOneWidget);
    });

    testWidgets('tapping CARDIO navigates to /cardio', (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CARDIO'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/cardio');
    });

    testWidgets('tapping HEART RATE navigates to /heart-rate', (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('HEART RATE'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/heart-rate',
      );
    });

    testWidgets('tapping SETTINGS navigates to /settings', (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
    });
  });
}
