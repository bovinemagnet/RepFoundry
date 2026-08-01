import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _NeverEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => false;
}

void main() {
  test('delivers emitted events to listeners when entitled', () async {
    final container = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
    ]);
    addTearDown(container.dispose);

    final bus = container.read(trainerEventBusProvider);
    final received = <TrainerEvent>[];
    final sub = bus.events.listen(received.add);
    addTearDown(sub.cancel);

    bus.emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single, isA<WorkoutStarted>());
  });

  test('emits nothing when the trainer is not entitled', () async {
    final container = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(_NeverEntitled()),
    ]);
    addTearDown(container.dispose);

    final bus = container.read(trainerEventBusProvider);
    final received = <TrainerEvent>[];
    final sub = bus.events.listen(received.add);
    addTearDown(sub.cancel);

    bus.emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });
}
