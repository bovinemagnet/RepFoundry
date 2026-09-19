import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';

void main() {
  group('healthPermissionsFor', () {
    test(
        'on Android a workout write also asks for the calorie and distance '
        'records the plugin inserts alongside the session', () {
      final request = healthPermissionsFor(
        writeWorkouts: true,
        writeWeight: false,
        writeHeartRate: false,
        readWeight: false,
        isAndroid: true,
      );

      final byType = Map.fromIterables(request.types, request.permissions);
      expect(byType[HealthDataType.WORKOUT], HealthDataAccess.WRITE);
      expect(
          byType[HealthDataType.TOTAL_CALORIES_BURNED], HealthDataAccess.WRITE);
      expect(byType[HealthDataType.DISTANCE_DELTA], HealthDataAccess.WRITE);
    });

    test('on iOS the workout permission alone covers the session', () {
      final request = healthPermissionsFor(
        writeWorkouts: true,
        writeWeight: false,
        writeHeartRate: false,
        readWeight: false,
        isAndroid: false,
      );

      expect(request.types, [HealthDataType.WORKOUT]);
    });

    test('types and permissions stay paired', () {
      final request = healthPermissionsFor(
        writeWorkouts: true,
        writeWeight: true,
        writeHeartRate: true,
        readWeight: true,
        isAndroid: true,
      );

      expect(request.types.length, request.permissions.length);
    });
  });
}
