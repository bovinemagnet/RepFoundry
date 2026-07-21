import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/clients/presentation/widgets/client_switcher.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('switcher shows the active client and switches on selection',
      (tester) async {
    // activeClientProvider reads SharedPreferences; the in-memory mock keeps
    // getInstance() off the platform channel.
    SharedPreferences.setMockInitialValues({});
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    // The container is owned by the test rather than by ProviderScope: a
    // scope-owned container is disposed during widget teardown, and cancelling
    // Drift's watch stream there leaves a pending timer that trips the test
    // framework's timer invariant.
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final alex = Client.create(name: 'Alex', colour: 0xFF4C6EF5);
    await container.read(clientRepositoryProvider).createClient(alex);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: ClientSwitcher()),
      ),
    ));

    // Let pumpAndSettle drive the clock rather than awaiting provider futures:
    // activeClientProvider's SharedPreferences read and the Drift watch stream
    // only resolve while frames are being pumped, so awaiting either future
    // without pumping deadlocks the test.
    await tester.pumpAndSettle();

    // Defaults to the self client, which the chip labels "You".
    expect(find.text('You'), findsOneWidget);

    // Open the picker and switch to Alex.
    await tester.tap(find.byType(ClientSwitcher));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    expect(container.read(activeClientProvider).value?.name, 'Alex');
    expect(find.text('Alex'), findsOneWidget);
  });
}
