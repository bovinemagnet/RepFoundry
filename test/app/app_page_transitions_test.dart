import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rep_foundry/app/app.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // go_router picks its page type by looking for a MaterialApp above it. One
  // that only recognises the framework's MaterialApp misses material_ui's and
  // falls back to pages with no transitions at all.
  testWidgets('routed screens are Material pages, so they animate',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      mcpHostSupportedProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const RepFoundryApp(),
    ));
    await tester.pump();

    final route = ModalRoute.of(tester.element(find.byType(Scaffold).last));
    expect(route, isA<MaterialRouteTransitionMixin<dynamic>>());
  });
}
