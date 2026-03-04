import 'package:uuid/uuid.dart';

class CardioSession {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int durationSeconds;
  final double? distanceMeters;
  final double? incline;
  final int? avgHeartRate;

  const CardioSession({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.durationSeconds,
    this.distanceMeters,
    this.incline,
    this.avgHeartRate,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  double? get paceMinutesPerKm {
    if (distanceMeters == null || distanceMeters! <= 0) return null;
    final distanceKm = distanceMeters! / 1000;
    return (durationSeconds / 60) / distanceKm;
  }

  static CardioSession create({
    required String workoutId,
    required String exerciseId,
    required int durationSeconds,
    double? distanceMeters,
    double? incline,
    int? avgHeartRate,
  }) {
    return CardioSession(
      id: const Uuid().v4(),
      workoutId: workoutId,
      exerciseId: exerciseId,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      incline: incline,
      avgHeartRate: avgHeartRate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardioSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
