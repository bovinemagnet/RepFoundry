import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_track_point.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/mcp/application/mcp_scope.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:uuid/uuid.dart';

import 'fake_client_repository.dart';

const otherClientId = 'client-alice';

/// In-memory repositories plus seeding helpers for MCP tool tests.
class McpFixture {
  final workouts = InMemoryWorkoutRepository();
  final exercises = InMemoryExerciseRepository();
  final cardio = InMemoryCardioSessionRepository();
  final stretching = InMemoryStretchingSessionRepository();
  final records = InMemoryPersonalRecordRepository();
  McpFixture({List<Client> extraClients = const []})
      : clients = FakeClientRepository(
            [testClient(otherClientId, name: 'Alice'), ...extraClients]);

  final FakeClientRepository clients;

  McpScope scope({bool includeClients = false}) =>
      McpScope(includeClients: includeClients, clients: clients);

  Future<Exercise> exercise(String name, MuscleGroup group,
      {ExerciseCategory category = ExerciseCategory.strength}) {
    return exercises.createExercise(Exercise.create(
      name: name,
      category: category,
      muscleGroup: group,
      equipmentType: EquipmentType.barbell,
    ));
  }

  Future<Workout> workout(
    DateTime startedAt, {
    Duration? length = const Duration(hours: 1),
    String clientId = kSelfClientId,
    String? notes,
  }) {
    return workouts.createWorkout(Workout(
      id: const Uuid().v4(),
      startedAt: startedAt.toUtc(),
      completedAt: length == null ? null : startedAt.add(length).toUtc(),
      notes: notes,
      clientId: clientId,
      updatedAt: startedAt.toUtc(),
    ));
  }

  Future<WorkoutSet> set(
    Workout w,
    Exercise e, {
    required double weight,
    required int reps,
    int order = 1,
    double? rpe,
    bool warmUp = false,
    int? avgHr,
    int? peakHr,
  }) {
    return workouts.addSet(WorkoutSet(
      id: const Uuid().v4(),
      workoutId: w.id,
      exerciseId: e.id,
      setOrder: order,
      weight: weight,
      reps: reps,
      rpe: rpe,
      timestamp: w.startedAt.add(Duration(minutes: order)),
      isWarmUp: warmUp,
      avgHeartRate: avgHr,
      peakHeartRate: peakHr,
      updatedAt: w.startedAt,
    ));
  }

  /// A cardio session in [w] with a recorded GPS track.
  Future<CardioSession> cardioWithTrack(Workout w, Exercise e,
      {int seconds = 1800, double? meters = 5000, int? avgHr = 150}) async {
    final session = await cardio.createSession(CardioSession(
      id: const Uuid().v4(),
      workoutId: w.id,
      exerciseId: e.id,
      durationSeconds: seconds,
      distanceMeters: meters,
      avgHeartRate: avgHr,
      clientId: w.clientId,
      updatedAt: w.startedAt,
    ));
    await cardio.saveTrackPoints(session.id, [
      CardioTrackPoint(
          timestamp: w.startedAt, latitude: -37.81, longitude: 144.96),
    ]);
    return session;
  }
}

/// Every map key anywhere inside [value].
Set<String> allKeys(Object? value) {
  final keys = <String>{};
  void walk(Object? v) {
    if (v is Map) {
      for (final e in v.entries) {
        keys.add(e.key.toString());
        walk(e.value);
      }
    } else if (v is List) {
      v.forEach(walk);
    }
  }

  walk(value);
  return keys;
}

/// Keys that would carry a location.
const gpsKeys = {'latitude', 'longitude', 'lat', 'lng', 'lon', 'track_points'};
