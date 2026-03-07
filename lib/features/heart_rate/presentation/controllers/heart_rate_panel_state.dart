/// A timestamped heart rate reading for charting.
class HrReading {
  final int bpm;
  final Duration elapsed;

  const HrReading({required this.bpm, required this.elapsed});
}

class HeartRatePanelState {
  final bool isMonitoring;
  final bool hrConnected;
  final bool hrConnecting;
  final bool hrReconnecting;
  final int? currentHeartRate;
  final List<HrReading> readings;
  final String? hrDeviceName;
  final String? error;
  final int elapsedSeconds;

  const HeartRatePanelState({
    this.isMonitoring = false,
    this.hrConnected = false,
    this.hrConnecting = false,
    this.hrReconnecting = false,
    this.currentHeartRate,
    this.readings = const [],
    this.hrDeviceName,
    this.error,
    this.elapsedSeconds = 0,
  });

  HeartRatePanelState copyWith({
    bool? isMonitoring,
    bool? hrConnected,
    bool? hrConnecting,
    bool? hrReconnecting,
    int? currentHeartRate,
    bool clearCurrentHeartRate = false,
    List<HrReading>? readings,
    String? hrDeviceName,
    bool clearHrDeviceName = false,
    String? error,
    bool clearError = false,
    int? elapsedSeconds,
  }) {
    return HeartRatePanelState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      hrConnected: hrConnected ?? this.hrConnected,
      hrConnecting: hrConnecting ?? this.hrConnecting,
      hrReconnecting: hrReconnecting ?? this.hrReconnecting,
      currentHeartRate: clearCurrentHeartRate
          ? null
          : (currentHeartRate ?? this.currentHeartRate),
      readings: readings ?? this.readings,
      hrDeviceName:
          clearHrDeviceName ? null : (hrDeviceName ?? this.hrDeviceName),
      error: clearError ? null : (error ?? this.error),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}
