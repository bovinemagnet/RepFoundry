import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalEntitlementService', () {
    test('reports an unlocked entitlement as held', () {
      final service =
          const LocalEntitlementService({Entitlement.virtualTrainer});

      expect(service.has(Entitlement.virtualTrainer), isTrue);
    });

    test('reports a locked entitlement as not held', () {
      const service = LocalEntitlementService({});

      expect(service.has(Entitlement.virtualTrainer), isFalse);
    });
  });

  group('UnlockedEntitlementsNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts with nothing unlocked', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(unlockedEntitlementsProvider), isEmpty);
      expect(
        container
            .read(entitlementServiceProvider)
            .has(Entitlement.virtualTrainer),
        isFalse,
      );
    });

    test('toggle unlocks, persists, and reloads', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(unlockedEntitlementsProvider.notifier)
          .toggle(Entitlement.virtualTrainer);

      expect(
        container
            .read(entitlementServiceProvider)
            .has(Entitlement.virtualTrainer),
        isTrue,
      );

      final reloaded = ProviderContainer();
      addTearDown(reloaded.dispose);
      await reloaded.read(unlockedEntitlementsProvider.notifier).reload();

      expect(reloaded.read(unlockedEntitlementsProvider),
          contains(Entitlement.virtualTrainer));
    });
  });
}
