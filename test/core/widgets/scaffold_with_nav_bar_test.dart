import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/widgets/scaffold_with_nav_bar.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The glass bottom navigation is mobile-only; pin a phone-sized viewport so
  // these tests exercise it rather than the desktop side-rail.
  Future<void> useMobileViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

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

  group('ScaffoldWithNavBar system navigation inset (#143)', () {
    // A phone with on-screen system navigation (Android three-button or
    // gesture bar) reports a bottom inset; the glass bar grows by that inset,
    // so tab content and sheets must end above the bar's real top edge.
    const systemInset = 48.0;

    Future<void> useMobileViewportWithInset(WidgetTester tester) async {
      await useMobileViewport(tester);
      tester.view.padding = const FakeViewPadding(bottom: systemInset);
      tester.view.viewPadding = const FakeViewPadding(bottom: systemInset);
      addTearDown(() {
        tester.view.resetPadding();
        tester.view.resetViewPadding();
      });
    }

    double navBarTop(WidgetTester tester) => tester
        .getRect(find
            .ancestor(
              of: find.text('HEART RATE'),
              matching: find.byType(BackdropFilter),
            )
            .first)
        .top;

    GoRouter buildSheetRouter({required bool sheetUsesSafeArea}) {
      Widget sheet(BuildContext context) {
        // Mirrors the health-profile onboarding sheet, which lifts itself
        // clear of the keyboard by the view inset it sees.
        final content = Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Done')),
            ],
          ),
        );
        return sheetUsesSafeArea ? SafeArea(child: content) : content;
      }

      return GoRouter(
        initialLocation: '/heart-rate',
        routes: [
          ShellRoute(
            builder: (_, __, child) => ScaffoldWithNavBar(child: child),
            routes: [
              GoRoute(
                path: '/heart-rate',
                builder: (_, __) => Scaffold(
                  body: Column(
                    children: [
                      Builder(
                        builder: (context) => TextButton(
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: sheet,
                          ),
                          child: const Text('Open sheet'),
                        ),
                      ),
                      const Spacer(),
                      const Text('Tab bottom'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    testWidgets('tab content ends above the nav bar', (tester) async {
      await useMobileViewportWithInset(tester);
      await tester.pumpWidget(
        buildApp(buildSheetRouter(sheetUsesSafeArea: false)),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('Tab bottom')).bottom,
        lessThanOrEqualTo(navBarTop(tester)),
      );
    });

    testWidgets('a bottom sheet without SafeArea is not covered by the nav bar',
        (tester) async {
      await useMobileViewportWithInset(tester);
      await tester.pumpWidget(
        buildApp(buildSheetRouter(sheetUsesSafeArea: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('Done')).bottom,
        lessThanOrEqualTo(navBarTop(tester)),
      );
    });

    testWidgets(
        'with the keyboard open, a sheet sits directly above the nav bar '
        'without overflowing', (tester) async {
      await useMobileViewportWithInset(tester);
      // The keyboard covers the system navigation inset, so the platform
      // reports no bottom padding while it is open.
      tester.view.padding = FakeViewPadding.zero;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        buildApp(buildSheetRouter(sheetUsesSafeArea: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The shell's Scaffold already lifts its body (nav bar included) above
      // the keyboard, so the sheet must not pad for the keyboard again.
      expect(
        tester.getRect(find.byType(FilledButton)).bottom,
        navBarTop(tester) - 24,
      );
    });

    testWidgets('a bottom sheet with SafeArea is not lifted a second time',
        (tester) async {
      await useMobileViewportWithInset(tester);
      await tester.pumpWidget(
        buildApp(buildSheetRouter(sheetUsesSafeArea: true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      // The sheet's 24 px padding is the only gap between the button and
      // the bar — the system inset is already spent by the bar itself.
      final buttonBottom = tester.getRect(find.byType(FilledButton)).bottom;
      expect(buttonBottom, navBarTop(tester) - 24);
    });
  });

  group('ScaffoldWithNavBar (mobile bottom nav)', () {
    testWidgets('renders all five nav labels in uppercase', (tester) async {
      await useMobileViewport(tester);
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
      await useMobileViewport(tester);
      await tester.pumpWidget(buildApp(buildRouter()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.directions_run), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('initial location /workout shows the workout child',
        (tester) async {
      await useMobileViewport(tester);
      await tester.pumpWidget(buildApp(buildRouter()));
      await tester.pumpAndSettle();

      expect(find.text('Workout tab'), findsOneWidget);
    });

    testWidgets('tapping HISTORY navigates to /history', (tester) async {
      await useMobileViewport(tester);
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/history');
      expect(find.text('History tab'), findsOneWidget);
    });

    testWidgets('tapping CARDIO navigates to /cardio', (tester) async {
      await useMobileViewport(tester);
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CARDIO'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/cardio');
    });

    testWidgets('tapping HEART RATE navigates to /heart-rate', (tester) async {
      await useMobileViewport(tester);
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
      await useMobileViewport(tester);
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
    });
  });
}
