import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cardio/data/foreground_session_service.dart';
import '../providers.dart';

/// Arbitrates the single platform foreground service between everything that
/// needs the process kept alive while backgrounded: a running cardio session,
/// the Heart Rate panel monitoring a connected strap, and the coach speaking
/// through a strength workout. Each reports its own needs; the service sees
/// their union, so none can stop another's keep-alive.
class ForegroundKeepAlive {
  ForegroundKeepAlive(this._service);

  final ForegroundSessionService _service;

  bool _cardioRunning = false;
  bool _cardioGps = false;
  bool _cardioHr = false;
  bool _panelMonitoring = false;
  bool _panelHr = false;
  bool _coachActive = false;

  Future<void> setCardio({
    required bool sessionRunning,
    required bool gpsEnabled,
    required bool hrConnected,
  }) {
    _cardioRunning = sessionRunning;
    _cardioGps = gpsEnabled;
    _cardioHr = hrConnected;
    return _reconcile();
  }

  Future<void> setHeartRatePanel({
    required bool monitoring,
    required bool hrConnected,
  }) {
    _panelMonitoring = monitoring;
    _panelHr = hrConnected;
    return _reconcile();
  }

  /// [active] while the coach should keep talking through a workout with the
  /// screen off.
  Future<void> setCoach({required bool active}) {
    _coachActive = active;
    return _reconcile();
  }

  /// The notification's "Turn coach off" button being tapped.
  Stream<void> get coachStopRequests => _service.coachStopRequests;

  Future<void> _reconcile() {
    final panelActive = _panelMonitoring && _panelHr;
    return _service.update(
      sessionRunning: _cardioRunning || panelActive || _coachActive,
      gpsEnabled: _cardioGps,
      hrConnected: _cardioHr || panelActive,
      coachActive: _coachActive,
    );
  }
}

final foregroundKeepAliveProvider = Provider<ForegroundKeepAlive>(
  (ref) => ForegroundKeepAlive(ref.watch(foregroundSessionServiceProvider)),
);
