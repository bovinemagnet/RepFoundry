import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/sync/domain/sync_merge_engine.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';

void main() {
  late SyncMergeEngine engine;

  final baseTime = DateTime.utc(2026, 3, 1, 12, 0);
  final earlier = baseTime.subtract(const Duration(hours: 1));
  final later = baseTime.add(const Duration(hours: 1));

  SyncSnapshot makeSnapshot({
    String deviceId = 'device-local',
    List<Exercise> exercises = const [],
    List<Workout> workouts = const [],
  }) =>
      SyncSnapshot(
        snapshotAt: baseTime,
        deviceId: deviceId,
        schemaVersion: 1,
        exercises: exercises,
        workouts: workouts,
      );

  Exercise makeExercise({
    required String id,
    required String name,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) =>
      Exercise(
        id: id,
        name: name,
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  Workout makeWorkout({
    required String id,
    required DateTime updatedAt,
    String? notes,
    DateTime? deletedAt,
  }) =>
      Workout(
        id: id,
        startedAt: baseTime,
        updatedAt: updatedAt,
        notes: notes,
        deletedAt: deletedAt,
      );

  setUp(() {
    engine = SyncMergeEngine();
  });

  group('SyncMergeEngine', () {
    test('disjoint sets merge — local A + remote B → merged has both', () {
      final exerciseA = makeExercise(
        id: 'ex-a',
        name: 'Bench Press',
        updatedAt: baseTime,
      );
      final exerciseB = makeExercise(
        id: 'ex-b',
        name: 'Squat',
        updatedAt: baseTime,
      );

      final local = makeSnapshot(exercises: [exerciseA]);
      final remote = makeSnapshot(
        deviceId: 'device-remote',
        exercises: [exerciseB],
      );

      final result = engine.merge(local: local, remote: remote);

      expect(result.exercises, hasLength(2));
      final ids = result.exercises.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-a', 'ex-b']));
    });

    test('same entity, remote newer — remote wins', () {
      final localExercise = makeExercise(
        id: 'ex-1',
        name: 'Local Name',
        updatedAt: earlier,
      );
      final remoteExercise = makeExercise(
        id: 'ex-1',
        name: 'Remote Name',
        updatedAt: later,
      );

      final local = makeSnapshot(exercises: [localExercise]);
      final remote = makeSnapshot(
        deviceId: 'device-remote',
        exercises: [remoteExercise],
      );

      final result = engine.merge(local: local, remote: remote);

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.name, equals('Remote Name'));
    });

    test('same entity, local newer — local wins', () {
      final localExercise = makeExercise(
        id: 'ex-1',
        name: 'Local Name',
        updatedAt: later,
      );
      final remoteExercise = makeExercise(
        id: 'ex-1',
        name: 'Remote Name',
        updatedAt: earlier,
      );

      final local = makeSnapshot(exercises: [localExercise]);
      final remote = makeSnapshot(
        deviceId: 'device-remote',
        exercises: [remoteExercise],
      );

      final result = engine.merge(local: local, remote: remote);

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.name, equals('Local Name'));
    });

    test('same entity, equal timestamps — local wins (tie-breaking)', () {
      final localExercise = makeExercise(
        id: 'ex-1',
        name: 'Local Name',
        updatedAt: baseTime,
      );
      final remoteExercise = makeExercise(
        id: 'ex-1',
        name: 'Remote Name',
        updatedAt: baseTime,
      );

      final local = makeSnapshot(exercises: [localExercise]);
      final remote = makeSnapshot(
        deviceId: 'device-remote',
        exercises: [remoteExercise],
      );

      final result = engine.merge(local: local, remote: remote);

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.name, equals('Local Name'));
    });

    test('empty remote — merged equals local', () {
      final exerciseA = makeExercise(
        id: 'ex-a',
        name: 'Bench Press',
        updatedAt: baseTime,
      );
      final exerciseB = makeExercise(
        id: 'ex-b',
        name: 'Squat',
        updatedAt: baseTime,
      );

      final local = makeSnapshot(exercises: [exerciseA, exerciseB]);
      final remote = makeSnapshot(deviceId: 'device-remote');

      final result = engine.merge(local: local, remote: remote);

      expect(result.exercises, hasLength(2));
      final ids = result.exercises.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-a', 'ex-b']));
    });

    test('empty local — merged equals remote', () {
      final exerciseA = makeExercise(
        id: 'ex-a',
        name: 'Bench Press',
        updatedAt: baseTime,
      );
      final exerciseB = makeExercise(
        id: 'ex-b',
        name: 'Squat',
        updatedAt: baseTime,
      );

      final local = makeSnapshot();
      final remote = makeSnapshot(
        deviceId: 'device-remote',
        exercises: [exerciseA, exerciseB],
      );

      final result = engine.merge(local: local, remote: remote);

      expect(result.exercises, hasLength(2));
      final ids = result.exercises.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-a', 'ex-b']));
    });

    test('multiple entity types — exercises + workouts merged correctly', () {
      final localExercise = makeExercise(
        id: 'ex-1',
        name: 'Local Exercise',
        updatedAt: earlier,
      );
      final remoteExercise = makeExercise(
        id: 'ex-1',
        name: 'Remote Exercise',
        updatedAt: later,
      );
      final localOnlyExercise = makeExercise(
        id: 'ex-2',
        name: 'Only Local',
        updatedAt: baseTime,
      );

      final localWorkout = makeWorkout(
        id: 'wo-1',
        updatedAt: later,
        notes: 'Local workout',
      );
      final remoteWorkout = makeWorkout(
        id: 'wo-1',
        updatedAt: earlier,
        notes: 'Remote workout',
      );
      final remoteOnlyWorkout = makeWorkout(
        id: 'wo-2',
        updatedAt: baseTime,
        notes: 'Only Remote',
      );

      final local = makeSnapshot(
        exercises: [localExercise, localOnlyExercise],
        workouts: [localWorkout],
      );
      final remote = makeSnapshot(
        deviceId: 'device-remote',
        exercises: [remoteExercise],
        workouts: [remoteWorkout, remoteOnlyWorkout],
      );

      final result = engine.merge(local: local, remote: remote);

      // Exercise ex-1: remote newer → remote wins
      expect(result.exercises, hasLength(2));
      final mergedEx1 = result.exercises.firstWhere((e) => e.id == 'ex-1');
      expect(mergedEx1.name, equals('Remote Exercise'));

      // Exercise ex-2: local only → kept
      final mergedEx2 = result.exercises.firstWhere((e) => e.id == 'ex-2');
      expect(mergedEx2.name, equals('Only Local'));

      // Workout wo-1: local newer → local wins
      expect(result.workouts, hasLength(2));
      final mergedWo1 = result.workouts.firstWhere((w) => w.id == 'wo-1');
      expect(mergedWo1.notes, equals('Local workout'));

      // Workout wo-2: remote only → kept
      final mergedWo2 = result.workouts.firstWhere((w) => w.id == 'wo-2');
      expect(mergedWo2.notes, equals('Only Remote'));
    });

    group('tombstones', () {
      test('tombstone beats live, regardless of updatedAt order', () {
        // Local has live row updated *after* the remote tombstone — but
        // the tombstone must still win, otherwise deletes resurrect.
        final liveLocal = makeExercise(
          id: 'ex-1',
          name: 'Resurrected',
          updatedAt: later,
        );
        final tombstonedRemote = makeExercise(
          id: 'ex-1',
          name: 'Deleted',
          updatedAt: earlier,
          deletedAt: earlier,
        );

        final local = makeSnapshot(exercises: [liveLocal]);
        final remote = makeSnapshot(
          deviceId: 'device-remote',
          exercises: [tombstonedRemote],
        );

        final result = engine.merge(local: local, remote: remote);

        expect(result.exercises, hasLength(1));
        expect(result.exercises.first.deletedAt, isNotNull);
        expect(result.exercises.first.name, equals('Deleted'));
      });

      test('live remote vs tombstoned local — local tombstone wins', () {
        final tombstonedLocal = makeExercise(
          id: 'ex-1',
          name: 'Deleted Locally',
          updatedAt: earlier,
          deletedAt: earlier,
        );
        final liveRemote = makeExercise(
          id: 'ex-1',
          name: 'Live Remote',
          updatedAt: later,
        );

        final local = makeSnapshot(exercises: [tombstonedLocal]);
        final remote = makeSnapshot(
          deviceId: 'device-remote',
          exercises: [liveRemote],
        );

        final result = engine.merge(local: local, remote: remote);

        expect(result.exercises, hasLength(1));
        expect(result.exercises.first.deletedAt, isNotNull);
      });

      test('both tombstoned — larger deletedAt wins', () {
        final earlyTombstoneLocal = makeExercise(
          id: 'ex-1',
          name: 'Early',
          updatedAt: baseTime,
          deletedAt: earlier,
        );
        final lateTombstoneRemote = makeExercise(
          id: 'ex-1',
          name: 'Late',
          updatedAt: baseTime,
          deletedAt: later,
        );

        final local = makeSnapshot(exercises: [earlyTombstoneLocal]);
        final remote = makeSnapshot(
          deviceId: 'device-remote',
          exercises: [lateTombstoneRemote],
        );

        final result = engine.merge(local: local, remote: remote);

        expect(result.exercises, hasLength(1));
        expect(result.exercises.first.name, equals('Late'));
        expect(result.exercises.first.deletedAt, equals(later));
      });

      test('both live — falls through to updatedAt comparison', () {
        // Sanity: deletedAt awareness must not regress the existing
        // live/live behaviour.
        final localLive = makeExercise(
          id: 'ex-1',
          name: 'Old',
          updatedAt: earlier,
        );
        final remoteLive = makeExercise(
          id: 'ex-1',
          name: 'New',
          updatedAt: later,
        );

        final local = makeSnapshot(exercises: [localLive]);
        final remote = makeSnapshot(
          deviceId: 'device-remote',
          exercises: [remoteLive],
        );

        final result = engine.merge(local: local, remote: remote);

        expect(result.exercises.first.name, equals('New'));
        expect(result.exercises.first.deletedAt, isNull);
      });

      test('delete-then-edit-on-other-device — tombstone propagates', () {
        // Device A deletes a workout (tombstone). Device B edits the
        // same workout before syncing. After merge: tombstone wins,
        // edits are discarded.
        final tombstonedFromA = makeWorkout(
          id: 'wo-1',
          updatedAt: earlier,
          deletedAt: earlier,
          notes: 'before delete',
        );
        final editedOnB = makeWorkout(
          id: 'wo-1',
          updatedAt: later,
          notes: 'edits made on B',
        );

        // Local is B (edited), remote is A (deleted).
        final local = makeSnapshot(workouts: [editedOnB]);
        final remote = makeSnapshot(
          deviceId: 'device-a',
          workouts: [tombstonedFromA],
        );

        final result = engine.merge(local: local, remote: remote);

        expect(result.workouts, hasLength(1));
        expect(result.workouts.first.deletedAt, isNotNull);
      });
    });
  });
}
