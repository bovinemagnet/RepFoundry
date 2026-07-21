import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/health_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('healthProfileProvider reflects the active client', () async {
    // Mark the legacy migration as already done — this test seeds each
    // client's profile directly via the repository and isn't exercising the
    // migration path.
    SharedPreferences.setMockInitialValues({
      'health_profile_migrated_v1': true,
    });

    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final sarah = Client.create(name: 'Sarah', colour: 0xFF000000);
    await container.read(clientRepositoryProvider).createClient(sarah);

    final repo = container.read(healthProfileRepositoryProvider);
    await repo.saveForClient(kSelfClientId, const HealthProfile(age: 40));
    await repo.saveForClient(sarah.id, const HealthProfile(age: 22));

    final meProfile = await container.read(healthProfileProvider.future);
    expect(meProfile.age, 40);

    await container.read(activeClientProvider.notifier).setActive(sarah);

    final sarahProfile = await container.read(healthProfileProvider.future);
    expect(sarahProfile.age, 22);
  });
}
