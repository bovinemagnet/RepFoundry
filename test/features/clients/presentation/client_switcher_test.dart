import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/clients/presentation/widgets/client_switcher.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Test double for [ActiveClientNotifier] that holds its client in memory,
/// so the widget test never touches SharedPreferences or the database — both
/// of which do real async I/O that a widget test's fake clock cannot drive.
class _FakeActiveClientNotifier extends ActiveClientNotifier {
  _FakeActiveClientNotifier(this._initial);

  final Client _initial;

  @override
  Future<Client> build() async => _initial;

  @override
  Future<void> setActive(Client client) async {
    state = AsyncData(client);
  }
}

Client _client({
  required String id,
  required String name,
  required bool isSelf,
}) {
  final t = DateTime.utc(2024, 1, 1);
  return Client(
    id: id,
    name: name,
    colour: 0xFF4C6EF5,
    notes: null,
    isSelf: isSelf,
    createdAt: t,
    updatedAt: t,
    deletedAt: null,
  );
}

void main() {
  testWidgets('switcher shows the active client and switches on selection',
      (tester) async {
    final me = _client(id: kSelfClientId, name: 'Me', isSelf: true);
    final alex = _client(id: 'alex', name: 'Alex', isSelf: false);

    // Override the providers with in-memory doubles: no Drift watch stream and
    // no SharedPreferences, so the tree settles under pumpAndSettle.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeClientProvider.overrideWith(() => _FakeActiveClientNotifier(me)),
        clientsProvider.overrideWith((ref) => Stream.value([me, alex])),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: ClientSwitcher()),
      ),
    ));
    await tester.pumpAndSettle();

    // Defaults to the self client, which the chip labels "You".
    expect(find.text('You'), findsOneWidget);

    // Open the picker sheet and switch to Alex.
    await tester.tap(find.byType(ClientSwitcher));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    // The chip now reflects the newly active client.
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('You'), findsNothing);
  });
}
