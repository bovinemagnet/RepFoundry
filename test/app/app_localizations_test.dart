import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rep_foundry/app/app.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the real app root with the device set to [locale] and returns the
/// Material strings its widgets would see.
Future<MaterialLocalizations> _materialStringsFor(
    WidgetTester tester, Locale locale) async {
  SharedPreferences.setMockInitialValues({});
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
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

  return MaterialLocalizations.of(tester.element(find.byType(Navigator).first));
}

void main() {
  // Material widgets look these up for their own labels (dialog buttons,
  // tooltips, date pickers). They must follow the app's language.
  testWidgets('Material strings are Japanese on a Japanese device',
      (tester) async {
    final strings = await _materialStringsFor(tester, const Locale('ja'));
    expect(strings.cancelButtonLabel, 'キャンセル');
  });

  testWidgets('Material strings are Korean on a Korean device', (tester) async {
    final strings = await _materialStringsFor(tester, const Locale('ko'));
    expect(strings.cancelButtonLabel, '취소');
  });

  testWidgets('control: Material strings are English on an English device',
      (tester) async {
    final strings = await _materialStringsFor(tester, const Locale('en'));
    expect(strings.cancelButtonLabel, 'Cancel');
  });
}
