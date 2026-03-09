import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/providers.dart';
import '../../../cardio/data/heart_rate_service.dart';
import 'heart_rate_panel_state.dart';

class HeartRatePanelController extends StateNotifier<HeartRatePanelState> {
  final HeartRateService _heartRateService;
  Timer? _timer;
  StreamSubscription<int>? _hrSub;
  StreamSubscription<HrConnectionState>? _hrConnectionSub;

  HeartRatePanelController({
    required HeartRateService heartRateService,
  })  : _heartRateService = heartRateService,
        super(const HeartRatePanelState());

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
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isMonitoring: false);
  }

  void resetReadings() {
    state = state.copyWith(
      readings: const [],
      elapsedSeconds: 0,
    );
  }

  Future<void> disconnectHeartRate() async {
    stopMonitoring();
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
          state = state.copyWith(hrReconnecting: true);
        case HrConnectionState.connected:
          state = state.copyWith(
            hrConnected: true,
            hrReconnecting: false,
          );
        case HrConnectionState.disconnected:
          state = state.copyWith(
            hrConnected: false,
            hrReconnecting: false,
            clearCurrentHeartRate: true,
            error: 'Heart rate monitor disconnected',
          );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hrSub?.cancel();
    _hrConnectionSub?.cancel();
    super.dispose();
  }
}

/// NON-autoDispose so monitoring survives tab switches.
final heartRatePanelProvider =
    StateNotifierProvider<HeartRatePanelController, HeartRatePanelState>(
  (ref) => HeartRatePanelController(
    heartRateService: ref.watch(heartRateServiceProvider),
  ),
);
