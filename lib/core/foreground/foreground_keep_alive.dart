import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cardio/data/foreground_session_service.dart';
import '../providers.dart';

/// Arbitrates the single platform foreground service between the two
/// screens that need the process kept alive while backgrounded: a running
/// cardio session and the Heart Rate panel monitoring a connected strap.
/// Each reports its own needs; the service sees their union, so neither
/// can stop the other's keep-alive.
class ForegroundKeepAlive {
  ForegroundKeepAlive(this._service);

  final ForegroundSessionService _service;

  bool _cardioRunning = false;
  bool _cardioGps = false;
  bool _cardioHr = false;
  bool _panelMonitoring = false;
  bool _panelHr = false;

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

  Future<void> _reconcile() {
    final panelActive = _panelMonitoring && _panelHr;
    return _service.update(
      sessionRunning: _cardioRunning || panelActive,
      gpsEnabled: _cardioGps,
      hrConnected: _cardioHr || panelActive,
    );
  }
}

final foregroundKeepAliveProvider = Provider<ForegroundKeepAlive>(
  (ref) => ForegroundKeepAlive(ref.watch(foregroundSessionServiceProvider)),
);
