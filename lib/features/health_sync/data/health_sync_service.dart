import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// A body-weight reading from the platform health store.
typedef WeightSample = ({double weightKg, DateTime date});

/// The data types and matching access levels to request for a set of
/// sync settings.
typedef HealthPermissionRequest = ({
  List<HealthDataType> types,
  List<HealthDataAccess> permissions,
});

/// Pure selection of what to ask the platform for, so the pairing can be
/// tested without a device.
///
/// On Android the plugin writes a workout as an exercise session *plus* a
/// `TotalCaloriesBurnedRecord` and, when a distance is given, a
/// `DistanceRecord`; Health Connect rejects the whole insert unless those
/// record types are granted too. HealthKit carries both as attributes of
/// the workout itself, so iOS needs only the workout permission.
HealthPermissionRequest healthPermissionsFor({
  required bool writeWorkouts,
  required bool writeWeight,
  required bool writeHeartRate,
  required bool readWeight,
  required bool isAndroid,
}) {
  final types = <HealthDataType>[];
  final permissions = <HealthDataAccess>[];

  if (writeWorkouts) {
    types.add(HealthDataType.WORKOUT);
    permissions.add(HealthDataAccess.WRITE);
    if (isAndroid) {
      types.addAll([
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.DISTANCE_DELTA,
      ]);
      permissions.addAll([HealthDataAccess.WRITE, HealthDataAccess.WRITE]);
    }
  }
  if (writeWeight) {
    types.addAll([HealthDataType.WEIGHT, HealthDataType.BODY_FAT_PERCENTAGE]);
    permissions.addAll([HealthDataAccess.READ_WRITE, HealthDataAccess.WRITE]);
  }
  if (writeHeartRate) {
    types.add(HealthDataType.HEART_RATE);
    permissions.add(HealthDataAccess.WRITE);
  }
  if (readWeight && !writeWeight) {
    types.add(HealthDataType.WEIGHT);
    permissions.add(HealthDataAccess.READ);
  }
  return (types: types, permissions: permissions);
}

class HealthSyncService {
  final Health _health = Health();
  bool _isAuthorised = false;

  /// Request permissions for the given health data types.
  Future<bool> requestAuthorisation({
    bool writeWorkouts = true,
    bool writeWeight = true,
    bool writeHeartRate = true,
    bool readWeight = true,
  }) async {
    final request = healthPermissionsFor(
      writeWorkouts: writeWorkouts,
      writeWeight: writeWeight,
      writeHeartRate: writeHeartRate,
      readWeight: readWeight,
      isAndroid: defaultTargetPlatform == TargetPlatform.android,
    );

    if (request.types.isEmpty) return true;

    _isAuthorised = await _health.requestAuthorization(
      request.types,
      permissions: request.permissions,
    );
    return _isAuthorised;
  }

  /// Write a strength or cardio workout session.
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required int totalCalories,
    bool isCardio = false,
    double? distanceMeters,
  }) async {
    return _health.writeWorkoutData(
      activityType: isCardio
          ? HealthWorkoutActivityType.RUNNING
          : HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING,
      start: startTime,
      end: endTime,
      totalEnergyBurned: totalCalories,
      totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      totalDistance: distanceMeters?.toInt(),
      totalDistanceUnit: HealthDataUnit.METER,
    );
  }

  /// Write body weight in kg.
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime dateTime,
  }) async {
    return _health.writeHealthData(
      value: weightKg,
      type: HealthDataType.WEIGHT,
      startTime: dateTime,
      endTime: dateTime,
      recordingMethod: RecordingMethod.manual,
    );
  }

  /// Write body fat percentage.
  Future<bool> writeBodyFat({
    required double percent,
    required DateTime dateTime,
  }) async {
    return _health.writeHealthData(
      value: percent,
      type: HealthDataType.BODY_FAT_PERCENTAGE,
      startTime: dateTime,
      endTime: dateTime,
      recordingMethod: RecordingMethod.manual,
    );
  }

  /// Write a single heart rate sample.
  Future<bool> writeHeartRate({
    required int bpm,
    required DateTime dateTime,
  }) async {
    return _health.writeHealthData(
      value: bpm.toDouble(),
      type: HealthDataType.HEART_RATE,
      startTime: dateTime,
      endTime: dateTime,
      recordingMethod: RecordingMethod.automatic,
    );
  }

  /// Read latest body weight from health store (last 30 days).
  Future<WeightSample?> readLatestWeight() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.WEIGHT],
      startTime: thirtyDaysAgo,
      endTime: now,
    );

    if (data.isEmpty) return null;

    data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
    final latest = data.first;
    if (latest.value is NumericHealthValue) {
      return (
        weightKg: (latest.value as NumericHealthValue).numericValue.toDouble(),
        date: latest.dateFrom.toUtc(),
      );
    }
    return null;
  }

  bool get isAuthorised => _isAuthorised;
}
