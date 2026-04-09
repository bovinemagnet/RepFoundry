import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';

/// A no-op fake for integration tests that avoids platform channel calls.
class FakeHealthSyncService extends HealthSyncService {
  @override
  Future<bool> requestAuthorisation({
    bool writeWorkouts = true,
    bool writeWeight = true,
    bool writeHeartRate = true,
    bool readWeight = true,
  }) async {
    return true;
  }

  @override
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required int totalCalories,
    bool isCardio = false,
    double? distanceMeters,
  }) async {
    return true;
  }

  @override
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime dateTime,
  }) async {
    return true;
  }

  @override
  Future<bool> writeBodyFat({
    required double percent,
    required DateTime dateTime,
  }) async {
    return true;
  }

  @override
  Future<bool> writeHeartRate({
    required int bpm,
    required DateTime dateTime,
  }) async {
    return true;
  }

  @override
  Future<double?> readLatestWeight() async {
    return null;
  }
}
