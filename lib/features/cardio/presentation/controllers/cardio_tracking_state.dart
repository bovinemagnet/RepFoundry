import '../../domain/models/cardio_session.dart';

class CardioTrackingState {
  final bool isRunning;
  final int elapsedSeconds;
  final String? selectedExerciseId;
  final String? selectedExerciseName;
  final CardioSession? lastSession;
  final bool isSaving;
  final String? error;
  final bool savedSuccessfully;
  final bool gpsEnabled;
  final double gpsDistanceMeters;
  final bool gpsAcquiring;
  final bool hrConnected;
  final bool hrConnecting;
  final bool hrReconnecting;
  final int? currentHeartRate;
  final List<int> heartRateReadings;
  final String? hrDeviceName;

  /// The client this session is being recorded for, fixed when it starts so
  /// switching the roster mid-run cannot move it to someone else.
  final String? sessionClientId;

  /// The workout the last save produced, so the UI can offer to open it in
  /// History straight after saving.
  final String? savedWorkoutId;

  const CardioTrackingState({
    this.isRunning = false,
    this.elapsedSeconds = 0,
    this.selectedExerciseId,
    this.selectedExerciseName,
    this.lastSession,
    this.isSaving = false,
    this.error,
    this.savedSuccessfully = false,
    this.gpsEnabled = false,
    this.gpsDistanceMeters = 0,
    this.gpsAcquiring = false,
    this.hrConnected = false,
    this.hrConnecting = false,
    this.hrReconnecting = false,
    this.currentHeartRate,
    this.heartRateReadings = const [],
    this.hrDeviceName,
    this.sessionClientId,
    this.savedWorkoutId,
  });

  CardioTrackingState copyWith({
    bool? isRunning,
    int? elapsedSeconds,
    String? selectedExerciseId,
    String? selectedExerciseName,
    CardioSession? lastSession,
    bool clearLastSession = false,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool? savedSuccessfully,
    bool? gpsEnabled,
    double? gpsDistanceMeters,
    bool? gpsAcquiring,
    bool? hrConnected,
    bool? hrConnecting,
    bool? hrReconnecting,
    int? currentHeartRate,
    bool clearCurrentHeartRate = false,
    List<int>? heartRateReadings,
    String? hrDeviceName,
    bool clearHrDeviceName = false,
    String? sessionClientId,
    String? savedWorkoutId,
  }) {
    return CardioTrackingState(
      isRunning: isRunning ?? this.isRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      selectedExerciseId: selectedExerciseId ?? this.selectedExerciseId,
      selectedExerciseName: selectedExerciseName ?? this.selectedExerciseName,
      lastSession: clearLastSession ? null : (lastSession ?? this.lastSession),
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      gpsDistanceMeters: gpsDistanceMeters ?? this.gpsDistanceMeters,
      gpsAcquiring: gpsAcquiring ?? this.gpsAcquiring,
      hrConnected: hrConnected ?? this.hrConnected,
      hrConnecting: hrConnecting ?? this.hrConnecting,
      hrReconnecting: hrReconnecting ?? this.hrReconnecting,
      currentHeartRate: clearCurrentHeartRate
          ? null
          : (currentHeartRate ?? this.currentHeartRate),
      heartRateReadings: heartRateReadings ?? this.heartRateReadings,
      hrDeviceName:
          clearHrDeviceName ? null : (hrDeviceName ?? this.hrDeviceName),
      sessionClientId: sessionClientId ?? this.sessionClientId,
      savedWorkoutId: savedWorkoutId ?? this.savedWorkoutId,
    );
  }
}
