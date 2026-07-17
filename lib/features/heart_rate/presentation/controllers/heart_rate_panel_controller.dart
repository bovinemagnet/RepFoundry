import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../cardio/data/heart_rate_service.dart';
import 'heart_rate_panel_state.dart';

class HeartRatePanelController extends Notifier<HeartRatePanelState> {
  Timer? _timer;
  StreamSubscription<int>? _hrSub;
  StreamSubscription<HrConnectionState>? _hrConnectionSub;
  // Elapsed time is derived from the wall clock rather than counted ticks,
  // so time spent suspended by the OS is still accounted for after resume.
  DateTime? _monitoringSince;
  Duration _accumulated = Duration.zero;

  int get _wallClockElapsedSeconds {
    final monitoringSince = _monitoringSince;
    final live = monitoringSince == null
        ? Duration.zero
        : clock.now().difference(monitoringSince);
    return (_accumulated + live).inSeconds;
  }

  HeartRateService get _heartRateService => ref.read(heartRateServiceProvider);

  @override
  HeartRatePanelState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _hrSub?.cancel();
      _hrConnectionSub?.cancel();
    });
    return const HeartRatePanelState();
  }

  Future<void> connectAndStart(String deviceId, String deviceName) async {
    state = state.copyWith(hrConnecting: true, clearError: true);

    try {
      // Only connect if the service isn't already connected (e.g. from cardio).
      if (!_heartRateService.isConnected) {
        await _heartRateService.connectToDevice(deviceId);
      }
      _subscribeToStreams();
      state = state.copyWith(
        hrConnected: true,
        hrConnecting: false,
        hrDeviceName: deviceName,
      );
      startMonitoring();
    } on Exception catch (e) {
      state = state.copyWith(
        hrConnecting: false,
        error: 'Failed to connect: $e',
      );
    }
  }

  /// Start monitoring when HR is already connected (e.g. from cardio screen).
  void startMonitoring() {
    if (state.isMonitoring) return;

    if (_heartRateService.isConnected && _hrSub == null) {
      _subscribeToStreams();
      state = state.copyWith(
        hrConnected: true,
        hrDeviceName: state.hrDeviceName,
      );
    }

    state = state.copyWith(isMonitoring: true);
    _monitoringSince = clock.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: _wallClockElapsedSeconds);
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    final monitoringSince = _monitoringSince;
    if (monitoringSince != null) {
      _accumulated += clock.now().difference(monitoringSince);
      _monitoringSince = null;
    }
    state = state.copyWith(
      isMonitoring: false,
      elapsedSeconds: _wallClockElapsedSeconds,
    );
  }

  void resetReadings() {
    _accumulated = Duration.zero;
    // Restart the anchor if monitoring is still active so elapsed
    // continues counting from zero, matching the previous behaviour.
    _monitoringSince = _timer == null ? null : clock.now();
    state = state.copyWith(
      readings: const [],
      elapsedSeconds: 0,
    );
  }

  Future<void> disconnectHeartRate() async {
    stopMonitoring();
    _monitoringSince = null;
    _accumulated = Duration.zero;
    _hrSub?.cancel();
    _hrSub = null;
    _hrConnectionSub?.cancel();
    _hrConnectionSub = null;
    await _heartRateService.disconnect();
    state = state.copyWith(
      hrConnected: false,
      hrConnecting: false,
      hrReconnecting: false,
      clearCurrentHeartRate: true,
      clearHrDeviceName: true,
      readings: const [],
      elapsedSeconds: 0,
    );
  }

  /// Sync connection state from cardio — call when navigating to the HR panel.
  void syncFromService() {
    if (_heartRateService.isConnected && !state.hrConnected) {
      _subscribeToStreams();
      state = state.copyWith(hrConnected: true);
    }
  }

  void _subscribeToStreams() {
    _hrSub?.cancel();
    _hrSub = _heartRateService.heartRateStream.listen(
      (bpm) {
        // Straps report 0 BPM while they have no skin contact; recording it
        // would poison the session minimum and average.
        if (bpm <= 0) return;
        final reading = HrReading(
          bpm: bpm,
          elapsed: Duration(seconds: state.elapsedSeconds),
        );
        state = state.copyWith(
          currentHeartRate: bpm,
          readings: [...state.readings, reading],
        );
      },
      onError: (_) {
        state = state.copyWith(
          hrConnected: false,
          hrReconnecting: false,
          clearCurrentHeartRate: true,
          error: 'Heart rate monitor disconnected',
        );
      },
    );

    _hrConnectionSub?.cancel();
    _hrConnectionSub =
        _heartRateService.connectionStateStream.listen((connState) {
      switch (connState) {
        case HrConnectionState.reconnecting:
          _pauseClock();
          state = state.copyWith(hrReconnecting: true);
        case HrConnectionState.connected:
          _resumeClock();
          state = state.copyWith(
            hrConnected: true,
            hrReconnecting: false,
          );
        case HrConnectionState.disconnected:
          _pauseClock();
          state = state.copyWith(
            hrConnected: false,
            hrReconnecting: false,
            clearCurrentHeartRate: true,
            error: 'Heart rate monitor disconnected',
          );
      }
    });
  }

  /// Freezes elapsed-time accumulation while no data can arrive, so gaps
  /// spent disconnected don't inflate the session duration.
  void _pauseClock() {
    final monitoringSince = _monitoringSince;
    if (monitoringSince != null) {
      _accumulated += clock.now().difference(monitoringSince);
      _monitoringSince = null;
    }
  }

  void _resumeClock() {
    if (state.isMonitoring && _monitoringSince == null) {
      _monitoringSince = clock.now();
    }
  }
}

/// NON-autoDispose so monitoring survives tab switches.
final heartRatePanelProvider =
    NotifierProvider<HeartRatePanelController, HeartRatePanelState>(
  HeartRatePanelController.new,
);
