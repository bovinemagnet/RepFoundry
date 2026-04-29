import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/settings/presentation/screens/about_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // PackageInfo.fromPlatform() bottoms out on a platform channel; the test
  // binding needs a stub that returns valid data so the FutureBuilder
  // resolves with non-null values rather than the in-screen fallback.
  setUp(() {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'RepFoundry',
          'packageName': 'com.repfoundry.app',
          'version': '1.2.3',
          'buildNumber': '42',
          'buildSignature': '',
          'installerStore': null,
        };
      }
      return null;
    });
  });

  tearDown(() {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget buildScreen() {
    return const MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: AboutScreen(),
    );
  }

  // Make the test surface tall enough that the lazy ListView builds all
  // tiles in one frame so we don't need to scroll for each assertion.
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

  group('AboutScreen', () {
    testWidgets('renders the app name and version banner', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('RepFoundry'), findsAtLeastNWidgets(1));
      // Version is rendered via aboutVersion(versionDisplay) which interpolates
      // "1.2.3+42".
      expect(find.textContaining('1.2.3+42'), findsOneWidget);
    });

    testWidgets('renders all six feature tile labels', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Offline-first'),
        findsOneWidget,
      );
      expect(
        find.text('Bluetooth heart rate monitor support'),
        findsOneWidget,
      );
      expect(
        find.text('Workout templates for quick session setup'),
        findsOneWidget,
      );
      expect(
        find.text('Progress tracking with personal records'),
        findsOneWidget,
      );
      expect(
        find.text('Export your data as JSON or CSV'),
        findsOneWidget,
      );
      expect(find.text('GPS-tracked cardio sessions'), findsOneWidget);
    });

    testWidgets('shows the GitHub URL', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('https://github.com/bovinemagnet/RepFoundry'),
        findsOneWidget,
      );
    });

    testWidgets('shows the author and licences rows', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Paul Snow'), findsOneWidget);
      expect(find.text('Open-source licences'), findsOneWidget);
      expect(find.text('Built with Flutter'), findsOneWidget);
    });
  });
}
