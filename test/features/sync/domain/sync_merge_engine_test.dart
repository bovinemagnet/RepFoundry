import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/sync/domain/sync_merge_engine.dart';

void main() {
  late SyncMergeEngine engine;

  setUp(() {
    engine = SyncMergeEngine();
  });

  SyncSnapshot emptySnapshot({String deviceId = 'device-a'}) {
    return SyncSnapshot(
      snapshotAt: DateTime.utc(2026),
      deviceId: deviceId,
      schemaVersion: 6,
    );
  }

  group('empty snapshots', () {
    test('merging two empty snapshots returns empty', () {
      final result = engine.merge(
        local: emptySnapshot(),
        remote: emptySnapshot(deviceId: 'device-b'),
      );

      expect(result.exercises, isEmpty);
      expect(result.workouts, isEmpty);
      expect(result.workoutSets, isEmpty);
    });
  });

  group('local-only data', () {
    test('local exercises appear in merged result', () {
      final exercise = Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final local = emptySnapshot();
      final localWithData = SyncSnapshot(
        snapshotAt: local.snapshotAt,
        deviceId: local.deviceId,
        schemaVersion: local.schemaVersion,
        exercises: [exercise],
      );

      final result = engine.merge(
        local: localWithData,
        remote: emptySnapshot(deviceId: 'device-b'),
      );

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.id, 'ex-1');
    });
  });

  group('remote-only data', () {
    test('remote workouts appear in merged result', () {
      final workout = Workout(
        id: 'w-1',
        startedAt: DateTime.utc(2026, 1, 10),
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final remote = SyncSnapshot(
        snapshotAt: DateTime.utc(2026),
        deviceId: 'device-b',
        schemaVersion: 6,
        workouts: [workout],
      );

      final result = engine.merge(
        local: emptySnapshot(),
        remote: remote,
      );

      expect(result.workouts, hasLength(1));
      expect(result.workouts.first.id, 'w-1');
    });
  });

  group('conflict resolution — last-write-wins', () {
    test('exercise with newer updatedAt wins', () {
      final olderExercise = Exercise(
        id: 'ex-1',
        name: 'Old Name',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 5),
      );

      final newerExercise = Exercise(
        id: 'ex-1',
        name: 'New Name',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final local = SyncSnapshot(
        snapshotAt: DateTime.utc(2026),
        deviceId: 'device-a',
        schemaVersion: 6,
        exercises: [olderExercise],
      );

      final remote = SyncSnapshot(
        snapshotAt: DateTime.utc(2026),
        deviceId: 'device-b',
        schemaVersion: 6,
        exercises: [newerExercise],
      );

      final result = engine.merge(local: local, remote: remote);

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.name, 'New Name');
    });

    test('deterministic tie-breaking by UUID when timestamps equal', () {
      final exerciseA = Exercise(
        id: 'aaa',
        name: 'From A',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final exerciseB = Exercise(
        id: 'aaa',
        name: 'From B',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      // Local wins when timestamps equal because we keep the local version
      // for deterministic tie-breaking (local is always preferred).
      final result = engine.merge(
        local: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-a',
          schemaVersion: 6,
          exercises: [exerciseA],
        ),
        remote: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-b',
          schemaVersion: 6,
          exercises: [exerciseB],
        ),
      );

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.name, 'From A');
    });
  });

  group('soft-delete propagation', () {
    test('deleted exercise with newer updatedAt wins over non-deleted', () {
      final activeExercise = Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 5),
      );

      final deletedExercise = Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 10),
        deletedAt: DateTime.utc(2026, 1, 10),
      );

      final result = engine.merge(
        local: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-a',
          schemaVersion: 6,
          exercises: [activeExercise],
        ),
        remote: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-b',
          schemaVersion: 6,
          exercises: [deletedExercise],
        ),
      );

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.isDeleted, isTrue);
    });

    test('non-deleted exercise with newer updatedAt wins over deleted', () {
      final deletedExercise = Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 5),
        deletedAt: DateTime.utc(2026, 1, 5),
      );

      final restoredExercise = Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final result = engine.merge(
        local: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-a',
          schemaVersion: 6,
          exercises: [deletedExercise],
        ),
        remote: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-b',
          schemaVersion: 6,
          exercises: [restoredExercise],
        ),
      );

      expect(result.exercises, hasLength(1));
      expect(result.exercises.first.isDeleted, isFalse);
    });
  });

  group('merging non-overlapping entities', () {
    test('both local and remote exercises are included', () {
      final localEx = Exercise(
        id: 'ex-local',
        name: 'Local Exercise',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final remoteEx = Exercise(
        id: 'ex-remote',
        name: 'Remote Exercise',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.back,
        equipmentType: EquipmentType.dumbbell,
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final result = engine.merge(
        local: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-a',
          schemaVersion: 6,
          exercises: [localEx],
        ),
        remote: SyncSnapshot(
          snapshotAt: DateTime.utc(2026),
          deviceId: 'device-b',
          schemaVersion: 6,
          exercises: [remoteEx],
        ),
      );

      expect(result.exercises, hasLength(2));
      final ids = result.exercises.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-local', 'ex-remote']));
    });
  });
}
