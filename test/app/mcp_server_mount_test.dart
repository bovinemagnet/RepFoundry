import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/app/app.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';
import 'package:rep_foundry/features/mcp/data/mcp_server_host.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_server_controller.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingHost implements McpHost {
  _RecordingHost(this.starts);
  final List<int> starts;

  @override
  Future<int> start() async {
    starts.add(1);
    return 47600;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('the app starts the assistant server at launch when enabled',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 'launch-token'});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final starts = <int>[];
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      mcpHostSupportedProvider.overrideWithValue(true),
      mcpHostFactoryProvider.overrideWithValue(
        ({
          required int port,
          required String token,
          required List<McpTool> Function() tools,
        }) =>
            _RecordingHost(starts),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const RepFoundryApp(),
    ));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(starts, hasLength(1));
  });
}
