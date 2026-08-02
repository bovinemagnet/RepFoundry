import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_zones/hr_zones.dart';

import '../../../../core/providers.dart';
import '../../../heart_rate/presentation/controllers/heart_rate_panel_controller.dart';
import '../../../heart_rate/presentation/providers/heart_rate_panel_visibility_provider.dart';
import '../../../heart_rate/presentation/providers/max_hr_alert_provider.dart';
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
///
///   [signalLossTimeout] must stay longer than the service's own reconnect
///   schedule (`ReconnectStrategy.defaultDelays`: 2s, 4s, 8s, …) plus the
///   connect/discover/subscribe work after each delay, or a routine,
///   recoverable dropout announces a false "back under your maximum" — a
///   safety-relevant false negative — followed by a second "above your
///   maximum" moments later once the strap reconnects and the reading
///   arrives. Too long costs only extra silence (encouragement stays
///   suppressed a little longer); too short speaks the false all-clear. See
///   the constructor's default for the reasoning behind the chosen value.
class HrEventSource {
  HrEventSource(
    this._ref, {
    Duration zoneDwell = const Duration(seconds: 10),
    Duration capRepeat = const Duration(seconds: 30),
    int capHysteresisMargin = 5,
    Duration capHysteresisDwell = const Duration(seconds: 5),
    // Android routinely fails the first reconnect attempt with GATT 133
    // (see FlutterBlueHeartRateService's doc comment and
    // ReconnectStrategy), so the common case is recovery on the *second*
    // attempt: cumulative delay 2s + 4s = 6s, plus connect/discoverServices/
    // setNotifyValue overhead, lands around 8-12s. A third attempt starts at
    // a cumulative 14s and can land close to 20s. 25s clears all three with
    // a margin, while remaining well short of the fourth attempt's 30s
    // cumulative delay — by that point the outage is genuinely extended and
    // the asymmetry favours erring toward silence over a false all-clear.
    Duration signalLossTimeout = const Duration(seconds: 25),
    // The panel's own chime (see heart_rate_panel_screen.dart's
    // _checkMaxHrAlert) is the attention-getter and must be heard first — a
    // chime cuts through instantly where a spoken line takes ~2s to land.
    // Only the very first HeartRateAboveCap of a crossing is delayed; the
    // capRepeat-driven re-warnings below have no accompanying chime moment
    // to sequence after.
    Duration aboveCapAnnounceDelay = const Duration(milliseconds: 1500),
  })  : _zoneDwell = zoneDwell,
        _capRepeat = capRepeat,
        _capHysteresisMargin = capHysteresisMargin,
        _capHysteresisDwell = capHysteresisDwell,
        _signalLossTimeout = signalLossTimeout,
        _aboveCapAnnounceDelay = aboveCapAnnounceDelay {
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
  final int _capHysteresisMargin;
  final Duration _capHysteresisDwell;
  final Duration _signalLossTimeout;
  final Duration _aboveCapAnnounceDelay;

  late final StreamSubscription<int> _subscription;
  Timer? _signalLossTimer;
  Timer? _pendingAboveCapAnnouncement;

  int? _currentZone;
  int? _candidateZone;
  DateTime? _candidateZoneSince;

  bool _aboveCap = false;
  DateTime? _lastCapWarningAt;
  DateTime? _belowCapSince;

  void _onReading(int bpm) {
    _resetSignalLossTimer();

    final config = _ref.read(zoneConfigurationProvider);
    if (config == null) {
      // The profile can go from usable to unusable mid-session (e.g. the
      // user clears their age or health flags and calculateZones can no
      // longer resolve a method). Readings keep arriving either way, so
      // without this the signal-loss timer above keeps getting reset and
      // never fires, and _aboveCap would stay stuck exactly as it would on
      // a real BLE dropout. Route it through the same recovery path.
      _onSignalLoss();
      return;
    }

    // Cap before zone is load-bearing, not incidental: the engine swallows
    // the zone callout entirely while above cap, so if a single reading is
    // both a new zone and above the cap, the safety cue must be the one
    // that reaches the engine first. Do not reorder these two lines.
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
        _announceAboveCap(bpm, cap);
        return;
      }
      // _lastCapWarningAt is always non-null here: it is set in the same
      // statement as _aboveCap = true above and only ever cleared alongside
      // _aboveCap = false, so reaching this branch (_aboveCap already true)
      // guarantees it was set on some earlier reading.
      final last = _lastCapWarningAt!;
      if (now.difference(last) >= _capRepeat) {
        _lastCapWarningAt = now;
        _emit(HeartRateAboveCap(bpm: bpm, cap: cap));
      }
      return;
    }

    if (!_aboveCap) return;

    if (bpm > cap - _capHysteresisMargin) {
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
    _pendingAboveCapAnnouncement?.cancel();
    _pendingAboveCapAnnouncement = null;
    _emit(const HeartRateBackBelowCap());
  }

  /// Emits the very first [HeartRateAboveCap] of a crossing — see decision 1
  /// in the phase 2a HR coaching spec. Delayed by [_aboveCapAnnounceDelay]
  /// only when the panel's own chime is actually expected to sound:
  /// its sound toggle is on, the panel is mounted, *and* it is actively
  /// monitoring — `_checkMaxHrAlert` in `heart_rate_panel_screen.dart`
  /// returns immediately if `!panelState.isMonitoring`, before it ever gets
  /// to the sound toggle, so a panel that is merely open (e.g. connected but
  /// paused) has no chime coming and must not defer the safety line either.
  ///
  /// Two further conditions gate the chime and are **not** mirrored here,
  /// deliberately: `_checkMaxHrAlert`'s own `currentHr == null` guard is
  /// moot in this context (a fresh [bpm] reading is exactly what got us
  /// here), and its 15s alert cooldown (`_lastMaxHrAlert`) is private
  /// `State` on `_HeartRatePanelScreenState` with no provider exposing it —
  /// mirroring it would mean promoting that cooldown into shared state
  /// purely so a second, unrelated consumer could read it, which is a
  /// bigger change than this file's job. The residual gap: a second
  /// crossing landing inside the chime's own cooldown window still defers
  /// the coach's line by 1.5s for a chime that won't actually sound.
  /// Recorded here rather than silently accepted — no worse than speaking
  /// slightly late, never a missed or wrong warning.
  void _announceAboveCap(int bpm, int cap) {
    final shouldDelay = _ref.read(maxHrAlertProvider).soundEnabled &&
        _ref.read(heartRatePanelVisibleProvider) &&
        _ref.read(heartRatePanelProvider).isMonitoring;
    if (!shouldDelay) {
      _emit(HeartRateAboveCap(bpm: bpm, cap: cap));
      return;
    }

    _pendingAboveCapAnnouncement?.cancel();
    _pendingAboveCapAnnouncement = Timer(_aboveCapAnnounceDelay, () {
      _pendingAboveCapAnnouncement = null;
      // Guards against a recovery that happened during the delay window —
      // _handleCap's back-below branch already cancels this timer on that
      // path, but the check is cheap insurance against emitting a stale
      // warning if that ever changes.
      if (!_aboveCap) return;
      _emit(HeartRateAboveCap(bpm: bpm, cap: cap));
    });
  }

  void _resetSignalLossTimer() {
    _signalLossTimer?.cancel();
    _signalLossTimer = Timer(_signalLossTimeout, _onSignalLoss);
  }

  /// Fired when the stream goes quiet for [_signalLossTimeout], closes,
  /// errors, or the zone configuration becomes unusable mid-session.
  ///
  /// Always clears any pending zone candidate: a candidate zone recorded
  /// just before a gap must not be promoted on the first reading afterwards
  /// with credit for time it was never actually, continuously observed in.
  /// Only clears the cap state and emits [HeartRateBackBelowCap] while
  /// actually above cap — otherwise there is no stuck suppression to clear.
  void _onSignalLoss() {
    _candidateZone = null;
    _candidateZoneSince = null;

    if (!_aboveCap) return;
    _aboveCap = false;
    _lastCapWarningAt = null;
    _belowCapSince = null;
    _pendingAboveCapAnnouncement?.cancel();
    _pendingAboveCapAnnouncement = null;
    _emit(const HeartRateBackBelowCap());
  }

  void _emit(TrainerEvent event) {
    _ref.read(trainerEventBusProvider).emit(event);
  }

  void dispose() {
    unawaited(_subscription.cancel());
    _signalLossTimer?.cancel();
    _pendingAboveCapAnnouncement?.cancel();
  }
}

final hrEventSourceProvider = Provider<HrEventSource>((ref) {
  final source = HrEventSource(ref);
  ref.onDispose(source.dispose);
  return source;
});
