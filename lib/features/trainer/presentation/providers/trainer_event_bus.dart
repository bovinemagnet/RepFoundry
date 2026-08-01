import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import '../../domain/trainer_event.dart';

/// Carries workout moments to the coach.
///
/// The entitlement check lives here rather than at each call site, so emitting
/// stays a single unconditional line everywhere in the workout code.
class TrainerEventBus {
  TrainerEventBus(this._isEntitled);

  final bool Function() _isEntitled;

  final StreamController<TrainerEvent> _controller =
      StreamController<TrainerEvent>.broadcast();

  Stream<TrainerEvent> get events => _controller.stream;

  void emit(TrainerEvent event) {
    if (_controller.isClosed) return;
    if (!_isEntitled()) return;
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

final trainerEventBusProvider = Provider<TrainerEventBus>((ref) {
  final bus = TrainerEventBus(
    () => ref.read(entitlementServiceProvider).has(Entitlement.virtualTrainer),
  );
  ref.onDispose(bus.dispose);
  return bus;
});
