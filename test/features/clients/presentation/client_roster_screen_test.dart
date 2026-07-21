import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/presentation/screens/client_roster_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('roster lists clients including Me', (tester) async {
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

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ClientRosterScreen(),
      ),
    ));

    // clientsProvider is a StreamProvider over Drift's watchClients(). The
    // watch query keeps its stream open indefinitely, so pumpAndSettle's
    // "no pending timers/frames" check never succeeds and it spins forever
    // waiting for the loading spinner's animation to stop. Await the
    // provider's first emission directly (a genuine Future await, not tied
    // to the widget test's fake clock), then pump once to rebuild with data.
    await container.read(clientsProvider.future);
    await tester.pump();

    expect(find.text('Me'), findsOneWidget);
  });
}
