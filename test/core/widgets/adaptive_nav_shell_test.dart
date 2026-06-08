import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/responsive/layout_mode.dart';
import 'package:rep_foundry/core/widgets/desktop_nav_rail.dart';
import 'package:rep_foundry/core/widgets/scaffold_with_nav_bar.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Verifies the navigation shell adapts between a bottom nav on mobile and a
/// persistent side-rail on desktop, per the desktop power-layout pattern.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> useViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
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
            GoRoute(
                path: '/workout', builder: (_, __) => label('Workout screen')),
            GoRoute(
                path: '/history', builder: (_, __) => label('History screen')),
            GoRoute(
                path: '/cardio', builder: (_, __) => label('Cardio screen')),
            GoRoute(
                path: '/heart-rate', builder: (_, __) => label('Heart screen')),
            GoRoute(
                path: '/analytics',
                builder: (_, __) => label('Analytics screen')),
            GoRoute(
                path: '/templates',
                builder: (_, __) => label('Templates screen')),
            GoRoute(
                path: '/programmes',
                builder: (_, __) => label('Programmes screen')),
            GoRoute(
                path: '/settings',
                builder: (_, __) => label('Settings screen')),
          ],
        ),
      ],
    );
  }

  Widget buildApp(GoRouter router, {LayoutMode mode = LayoutMode.auto}) =>
      MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: router,
        builder: (context, child) => LayoutModeScope(mode: mode, child: child!),
      );

  group('adaptive navigation shell', () {
    testWidgets('mobile width (390) shows bottom nav, not the rail',
        (tester) async {
      await useViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildApp(buildRouter()));
      await tester.pumpAndSettle();

      // No desktop rail.
      expect(find.byType(DesktopNavRail), findsNothing);
      // Bottom nav renders uppercase mono labels.
      expect(find.text('WORKOUT'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('desktop width (1280) shows the side-rail, not the bottom nav',
        (tester) async {
      await useViewport(tester, const Size(1280, 900));
      await tester.pumpWidget(buildApp(buildRouter()));
      await tester.pumpAndSettle();

      // Rail present.
      expect(find.byType(DesktopNavRail), findsOneWidget);
      // Rail labels are title-case (not the uppercase bottom-nav labels).
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Programmes'), findsOneWidget);
      // The uppercase bottom-nav label is absent at this width.
      expect(find.text('WORKOUT'), findsNothing);
    });

    testWidgets('desktop rail navigates to grouped destinations',
        (tester) async {
      await useViewport(tester, const Size(1280, 900));
      final router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/analytics',
      );
      expect(find.text('Analytics screen'), findsOneWidget);
    });
  });

  group('layout override (tablet-and-up only)', () {
    testWidgets('forcing Desktop on a tablet width shows the side-rail',
        (tester) async {
      await useViewport(tester, const Size(800, 1000));
      await tester
          .pumpWidget(buildApp(buildRouter(), mode: LayoutMode.desktop));
      await tester.pumpAndSettle();

      // 800px would normally be tablet-only chrome; forcing Desktop shows the
      // rail (and would also enable two-pane layouts via context.isWide).
      expect(find.byType(DesktopNavRail), findsOneWidget);
      expect(find.text('WORKOUT'), findsNothing);
    });

    testWidgets('forcing Mobile on a desktop width shows the bottom nav',
        (tester) async {
      await useViewport(tester, const Size(1280, 900));
      await tester.pumpWidget(buildApp(buildRouter(), mode: LayoutMode.mobile));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopNavRail), findsNothing);
      expect(find.text('WORKOUT'), findsOneWidget);
    });

    testWidgets('phone width ignores a Desktop override (mobile wins)',
        (tester) async {
      await useViewport(tester, const Size(390, 844));
      await tester
          .pumpWidget(buildApp(buildRouter(), mode: LayoutMode.desktop));
      await tester.pumpAndSettle();

      // The override never applies below the tablet breakpoint.
      expect(find.byType(DesktopNavRail), findsNothing);
      expect(find.text('WORKOUT'), findsOneWidget);
    });
  });
}
