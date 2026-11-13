import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/mcp/domain/mcp_server_status.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_server_controller.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_settings_provider.dart';
import 'package:rep_foundry/features/settings/presentation/screens/settings_screen.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/data/noop_cloud_sync_service.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reports a fixed status and never binds a socket.
class _FixedStatusController extends McpServerController {
  _FixedStatusController(this.status);
  final McpServerStatus status;

  @override
  McpServerStatus build() => status;
}

const _enableTitle = 'Allow assistants to read my data';
const _enableSwitch = Key('mcp-enable-switch');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const packageInfoChannel =
      MethodChannel('dev.fluttercommunity.plus/package_info');
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(900, 2600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      packageInfoChannel,
      (call) async => call.method == 'getAll'
          ? <String, dynamic>{
              'appName': 'RepFoundry',
              'packageName': 'com.repfoundry.app',
              'version': '0.1.0',
              'buildNumber': '1',
              'buildSignature': '',
              'installerStore': null,
            }
          : null,
    );
  });

  tearDown(() async {
    await db.close();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget screen({
    bool supported = true,
    McpServerStatus status = const McpStopped(),
  }) {
    return ProviderScope(
      overrides: [
        syncOrchestratorProvider.overrideWithValue(SyncOrchestrator(
          database: db,
          cloudService: const NoopCloudSyncService(),
          deviceId: 'test-device',
        )),
        mcpHostSupportedProvider.overrideWithValue(supported),
        mcpServerControllerProvider
            .overrideWith(() => _FixedStatusController(status)),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: SettingsScreen(),
      ),
    );
  }

  Finder enableSwitch() => find.descendant(
        of: find.byKey(_enableSwitch, skipOffstage: false),
        matching: find.byType(Switch, skipOffstage: false),
      );

  Future<void> tapEnable(WidgetTester tester) async {
    await tester.ensureVisible(enableSwitch());
    await tester.pumpAndSettle();
    await tester.tap(enableSwitch());
    await tester.pumpAndSettle();
  }

  testWidgets('the card is absent where the platform cannot host a server',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(screen(supported: false));
    await tester.pumpAndSettle();
    expect(find.text(_enableTitle, skipOffstage: false), findsNothing);
  });

  testWidgets('control: the card is present on desktop', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text(_enableTitle, skipOffstage: false), findsOneWidget);
  });

  testWidgets('the first switch-on asks first, and Cancel leaves it off',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tapEnable(tester);

    expect(find.text('Before you turn this on'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mcp_enabled'), isNot(isTrue));
    expect(tester.widget<Switch>(enableSwitch()).value, isFalse);
  });

  testWidgets('accepting turns it on, and later toggles do not ask again',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tapEnable(tester);
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mcp_enabled'), isTrue);
    expect(prefs.getBool('mcp_disclosure_accepted'), isTrue);

    await tapEnable(tester); // off
    await tapEnable(tester); // on again
    expect(find.text('Before you turn this on'), findsNothing);
    expect(prefs.getBool('mcp_enabled'), isTrue);
  });

  testWidgets('shows the running address, endpoint and a masked token',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'mcp_enabled': true,
      'mcp_token': 'abcdefghijklmnop',
      'mcp_disclosure_accepted': true,
    });
    await tester.pumpWidget(screen(status: const McpRunning(47600)));
    await tester.pumpAndSettle();
    expect(find.text('Running on 127.0.0.1:47600', skipOffstage: false),
        findsOneWidget);
    expect(find.text('http://127.0.0.1:47600/mcp', skipOffstage: false),
        findsOneWidget);
    expect(find.text('abcdefghijklmnop', skipOffstage: false), findsNothing);
  });

  testWidgets('shows why the server could not start', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 't'});
    await tester.pumpWidget(screen(status: const McpFailed('port in use')));
    await tester.pumpAndSettle();
    expect(find.text('Could not start: port in use', skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('the port dialog rejects a port below 1024', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    final portRow = find.text('Port', skipOffstage: false);
    await tester.ensureVisible(portRow);
    await tester.pumpAndSettle();
    await tester.tap(portRow);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '80');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a port between 1024 and 65535'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '50000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('mcp_port'), 50000);
  });
}
