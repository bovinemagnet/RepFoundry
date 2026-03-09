import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/providers.dart';
import '../../../health_sync/data/health_sync_service.dart';
import '../../../health_sync/presentation/providers/health_sync_settings_provider.dart';
import '../../application/save_cardio_session_use_case.dart';
import '../../data/heart_rate_service.dart';
import '../../data/location_service.dart';
import '../../domain/repositories/cardio_session_repository.dart';
import 'cardio_tracking_state.dart';

class CardioTrackingController extends StateNotifier<CardioTrackingState> {
  final CardioSessionRepository _cardioRepository;
  final SaveCardioSessionUseCase _saveUseCase;
  final LocationService _locationService;
  final HeartRateService _heartRateService;
  final HealthSyncService _healthSyncService;
  final HealthSyncSettings _healthSyncSettings;
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  StreamSubscription<int>? _hrSub;
  StreamSubscription<HrConnectionState>? _hrConnectionSub;

  CardioTrackingController({
    required CardioSessionRepository cardioRepository,
    required SaveCardioSessionUseCase saveUseCase,
    required LocationService locationService,
    required HeartRateService heartRateService,
    required HealthSyncService healthSyncService,
    required HealthSyncSettings healthSyncSettings,
  })  : _cardioRepository = cardioRepository,
        _saveUseCase = saveUseCase,
        _locationService = locationService,
        _heartRateService = heartRateService,
        _healthSyncService = healthSyncService,
        _healthSyncSettings = healthSyncSettings,
        super(const CardioTrackingState());

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, savedSuccessfully: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
    if (state.gpsEnabled) {
      _startGpsTracking();
    }
  }

  void pause() {
    _timer?.cancel();
    _positionSub?.pause();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    _stopGpsTracking();
    state = CardioTrackingState(
      selectedExerciseId: state.selectedExerciseId,
      selectedExerciseName: state.selectedExerciseName,
      lastSession: state.lastSession,
      gpsEnabled: state.gpsEnabled,
      hrConnected: state.hrConnected,
      hrDeviceName: state.hrDeviceName,
    );
  }

  Future<void> toggleGps() async {
    if (state.gpsEnabled) {
      _stopGpsTracking();
      state = state.copyWith(
        gpsEnabled: false,
        gpsDistanceMeters: 0,
        gpsAcquiring: false,
      );
      return;
    }

    final granted = await _locationService.checkAndRequestPermission();
    if (!granted) {
      state = state.copyWith(
        error: 'Location permission denied. Enable it in settings.',
      );
      return;
    }

    state = state.copyWith(gpsEnabled: true, gpsDistanceMeters: 0);

    if (state.isRunning) {
      _startGpsTracking();
    }
  }

  void _startGpsTracking() {
    _lastPosition = null;
    state = state.copyWith(gpsAcquiring: true);
    _positionSub?.cancel();
    _positionSub = _locationService.getPositionStream().listen(
      (position) {
        if (state.gpsAcquiring) {
          state = state.copyWith(gpsAcquiring: false);
        }
        if (_lastPosition != null) {
          final delta = _locationService.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          state = state.copyWith(
            gpsDistanceMeters: state.gpsDistanceMeters + delta,
          );
        }
        _lastPosition = position;
      },
      onError: (_) {
        state = state.copyWith(
          gpsAcquiring: false,
          error: 'GPS signal lost',
        );
      },
    );
  }

  void _stopGpsTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _lastPosition = null;
  }

  Future<void> connectHeartRate(String deviceId, String deviceName) async {
    state = state.copyWith(hrConnecting: true, clearError: true);

    try {
      await _heartRateService.connectToDevice(deviceId);
      _hrSub?.cancel();
      _hrSub = _heartRateService.heartRateStream.listen(
        (bpm) {
          state = state.copyWith(
            currentHeartRate: bpm,
            heartRateReadings: [...state.heartRateReadings, bpm],
          );
        },
        onError: (_) {
          state = state.copyWith(
            hrConnected: false,
            hrConnecting: false,
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

      state = state.copyWith(
        hrConnected: true,
        hrConnecting: false,
        hrDeviceName: deviceName,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        hrConnecting: false,
        error: 'Failed to connect: $e',
      );
    }
  }

  Future<void> disconnectHeartRate() async {
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
      heartRateReadings: const [],
    );
  }

  Future<void> selectExercise(String id, String name) async {
    state = state.copyWith(
      selectedExerciseId: id,
      selectedExerciseName: name,
      clearLastSession: true,
    );

    final lastSession = await _cardioRepository.getLastSessionForExercise(id);
    state = state.copyWith(lastSession: lastSession, clearLastSession: false);
  }

  Future<void> save({
    double? distanceMeters,
    double? incline,
    int? avgHeartRate,
  }) async {
    if (state.selectedExerciseId == null || state.elapsedSeconds <= 0) return;

    // Use GPS distance if GPS is enabled and has data.
    final effectiveDistance = state.gpsEnabled && state.gpsDistanceMeters > 0
        ? state.gpsDistanceMeters
        : distanceMeters;

    // Use HR monitor average if readings were collected, otherwise manual.
    final effectiveHeartRate = state.heartRateReadings.isNotEmpty
        ? (state.heartRateReadings.reduce((a, b) => a + b) /
                state.heartRateReadings.length)
            .round()
        : avgHeartRate;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final result = await _saveUseCase.execute(
        SaveCardioSessionInput(
          exerciseId: state.selectedExerciseId!,
          exerciseName: state.selectedExerciseName ?? 'session',
          durationSeconds: state.elapsedSeconds,
          distanceMeters: effectiveDistance,
          incline: incline,
          avgHeartRate: effectiveHeartRate,
        ),
      );

      // Sync to health store if enabled
      try {
        if (_healthSyncSettings.enabled &&
            _healthSyncSettings.writeWorkouts) {
          // Rough calorie estimate: ~8 kcal/min for moderate cardio
          final calories = (state.elapsedSeconds / 60.0 * 8).round();
          await _healthSyncService.writeWorkout(
            startTime: result.workout.startedAt,
            endTime: result.workout.completedAt!,
            totalCalories: calories,
            isCardio: true,
            distanceMeters: effectiveDistance,
          );
        }
      } catch (_) {
        // Health sync is best-effort — don't fail the save
      }

      _timer?.cancel();
      _stopGpsTracking();
      state = const CardioTrackingState(savedSuccessfully: true);
    } on SaveCardioSessionException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopGpsTracking();
    _hrSub?.cancel();
    _hrConnectionSub?.cancel();
    super.dispose();
  }
}

/// NON-autoDispose so the timer survives tab switches.
final cardioTrackingProvider =
    StateNotifierProvider<CardioTrackingController, CardioTrackingState>(
  (ref) => CardioTrackingController(
    cardioRepository: ref.watch(cardioSessionRepositoryProvider),
    saveUseCase: ref.watch(saveCardioSessionUseCaseProvider),
    locationService: ref.watch(locationServiceProvider),
    heartRateService: ref.watch(heartRateServiceProvider),
    healthSyncService: ref.watch(healthSyncServiceProvider),
    healthSyncSettings: ref.watch(healthSyncSettingsProvider),
  ),
);
