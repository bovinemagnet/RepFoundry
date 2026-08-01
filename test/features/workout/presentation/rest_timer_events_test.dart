import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/rest_timer_widget.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

void main() {
  test('emits countdown events for the final three seconds', () {
    fakeAsync((async) {
      final container = ProviderContainer(overrides: [
        entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
      ]);
      addTearDown(container.dispose);

      final received = <TrainerEvent>[];
      container.read(trainerEventBusProvider).events.listen(received.add);

      container.read(restTimerProvider.notifier).start(5);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();

      final countdowns = received.whereType<RestCountdown>().toList();
      expect(countdowns.map((c) => c.secondsLeft), [3, 2, 1]);
      expect(received.whereType<RestStarted>(), hasLength(1));
      expect(received.whereType<RestFinished>(), hasLength(1));
    });
  });
}
