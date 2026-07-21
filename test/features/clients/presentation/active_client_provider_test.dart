import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to the self client', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final client = await container.read(activeClientProvider.future);
    expect(client.id, kSelfClientId);
  });

  test('setActive persists and updates the active client', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await container.read(activeClientProvider.future);
    final sarah = Client.create(name: 'Sarah', colour: 0xFF000000);
    await container.read(clientRepositoryProvider).createClient(sarah);
    await container.read(activeClientProvider.notifier).setActive(sarah);

    expect(container.read(activeClientProvider).value?.id, sarah.id);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_client_id'), sarah.id);
  });
}
