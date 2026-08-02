import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_zones/hr_zones.dart';

import '../../../../core/providers.dart';
import '../../../heart_rate/presentation/providers/zone_configuration_provider.dart';
import '../../domain/hr_zone_lookup.dart';
import '../../domain/trainer_event.dart';
import 'trainer_event_bus.dart';

/// Turns the live BLE heart rate stream into the trainer events the coach
/// reacts to.
///
/// Two behaviours here exist to protect the safety path, not to make the
/// coach chattier:
///
/// - **Cap-boundary hysteresis** (`capHysteresisMargin`, `capHysteresisDwell`):
///   the engine (see `CoachingEngine`) resets its own 30 second warning
///   window the instant a `HeartRateBackBelowCap` arrives, so a genuine
///   second crossing is heard immediately — but that means this source is
///   now the *only* thing standing between BPM noise at the cap boundary and
///   the warning/reassurance pair alternating every couple of seconds. A
///   reading only counts as "back below" once it has stayed at least
///   [capHysteresisMargin] bpm under the cap for [capHysteresisDwell];
///   anything less resets the dwell rather than merely pausing it, so a
///   reading that pops back near the cap before the dwell completes must
///   start over.
/// - **Signal loss** (`signalLossTimeout`): the production `HeartRateService`
///   (`FlutterBlueHeartRateService`) never closes or errors its
///   `heartRateStream` on a BLE dropout — it simply stops emitting. If that
///   happens while the user is above cap, nothing would ever clear
///   `_aboveCap` in the engine, silencing all encouragement for the rest of
///   the session with no explanation. A quiet period of [signalLossTimeout]
///   is therefore treated the same as an explicit "back below cap": it is
///   the only signal this source can rely on for the real hardware. Stream
///   closure and stream errors are also handled the same way, both because a
///   test double may use them and because they cost nothing to cover.
class HrEventSource {
  HrEventSource(
    this._ref, {
    Duration zoneDwell = const Duration(seconds: 10),
    Duration capRepeat = const Duration(seconds: 30),
    this.capHysteresisMargin = 5,
    Duration capHysteresisDwell = const Duration(seconds: 5),
    Duration signalLossTimeout = const Duration(seconds: 8),
  })  : _zoneDwell = zoneDwell,
        _capRepeat = capRepeat,
        _capHysteresisDwell = capHysteresisDwell,
        _signalLossTimeout = signalLossTimeout {
    _subscription = _ref.read(heartRateServiceProvider).heartRateStream.listen(
          _onReading,
          onDone: _onSignalLoss,
          onError: (Object _, StackTrace __) => _onSignalLoss(),
        );
  }

  final Ref _ref;
  final Duration _zoneDwell;
  final Duration _capRepeat;

  /// How far below the cap, in bpm, a reading must sit before it counts as
  /// "meaningfully below" rather than noise. Five beats comfortably clears
  /// the couple of beats of jitter a BLE reading can carry from one sample
  /// to the next, without delaying a genuine recovery by much.
  final int capHysteresisMargin;
  final Duration _capHysteresisDwell;
  final Duration _signalLossTimeout;

  late final StreamSubscription<int> _subscription;
  Timer? _signalLossTimer;

  int? _currentZone;
  int? _candidateZone;
  DateTime? _candidateZoneSince;

  bool _aboveCap = false;
  DateTime? _lastCapWarningAt;
  DateTime? _belowCapSince;

  void _onReading(int bpm) {
    _resetSignalLossTimer();

    final config = _ref.read(zoneConfigurationProvider);
    if (config == null) return;

    _handleCap(bpm, config.maxHr);
    _handleZone(bpm, config);
  }

  void _handleZone(int bpm, ZoneConfiguration config) {
    final zoneNumber = zoneNumberFor(config, bpm);
    if (zoneNumber == null) return;

    if (zoneNumber == _currentZone) {
      _candidateZone = null;
      _candidateZoneSince = null;
      return;
    }

    final now = clock.now();
    if (_candidateZone != zoneNumber) {
      _candidateZone = zoneNumber;
      _candidateZoneSince = now;
      return;
    }

    final since = _candidateZoneSince;
    if (since == null || now.difference(since) < _zoneDwell) return;

    _currentZone = zoneNumber;
    _candidateZone = null;
    _candidateZoneSince = null;

    final zone = config.zones.firstWhere((z) => z.zoneNumber == zoneNumber);
    _emit(HeartRateZoneChanged(
      zoneNumber: zoneNumber,
      effortLabel: zone.effortLabel,
      descriptiveLabel: zone.descriptiveLabel,
    ));
  }

  void _handleCap(int bpm, int cap) {
    final now = clock.now();

    if (bpm > cap) {
      _belowCapSince = null;
      if (!_aboveCap) {
        _aboveCap = true;
        _lastCapWarningAt = now;
        _emit(HeartRateAboveCap(bpm: bpm, cap: cap));
        return;
      }
      final last = _lastCapWarningAt;
      if (last == null || now.difference(last) >= _capRepeat) {
        _lastCapWarningAt = now;
        _emit(HeartRateAboveCap(bpm: bpm, cap: cap));
      }
      return;
    }

    if (!_aboveCap) return;

    if (bpm > cap - capHysteresisMargin) {
      // Below the cap but still within the noise band — not a genuine
      // recovery. Reset rather than pause the dwell: a reading that dips
      // here after some dwell has already accrued must not be able to
      // "top up" from where it left off.
      _belowCapSince = null;
      return;
    }

    final since = _belowCapSince;
    if (since == null) {
      _belowCapSince = now;
      return;
    }
    if (now.difference(since) < _capHysteresisDwell) return;

    _aboveCap = false;
    _lastCapWarningAt = null;
    _belowCapSince = null;
    _emit(const HeartRateBackBelowCap());
  }

  void _resetSignalLossTimer() {
    _signalLossTimer?.cancel();
    _signalLossTimer = Timer(_signalLossTimeout, _onSignalLoss);
  }

  /// Fired when the stream goes quiet for [_signalLossTimeout], closes, or
  /// errors. Only ever has anything to do while above cap — otherwise there
  /// is no stuck suppression to clear.
  void _onSignalLoss() {
    if (!_aboveCap) return;
    _aboveCap = false;
    _lastCapWarningAt = null;
    _belowCapSince = null;
    _emit(const HeartRateBackBelowCap());
  }

  void _emit(TrainerEvent event) {
    _ref.read(trainerEventBusProvider).emit(event);
  }

  void dispose() {
    unawaited(_subscription.cancel());
    _signalLossTimer?.cancel();
  }
}

final hrEventSourceProvider = Provider<HrEventSource>((ref) {
  final source = HrEventSource(ref);
  ref.onDispose(source.dispose);
  return source;
});
