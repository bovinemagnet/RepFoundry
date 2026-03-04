import 'dart:async';
import '../domain/models/exercise.dart';
import '../domain/repositories/exercise_repository.dart';

class InMemoryExerciseRepository implements ExerciseRepository {
  final List<Exercise> _exercises = _buildDefaultExercises();
  final _controller = StreamController<List<Exercise>>.broadcast();

  static List<Exercise> _buildDefaultExercises() {
    return [
      const Exercise(
        id: '1',
        name: 'Barbell Bench Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
      ),
      const Exercise(
        id: '2',
        name: 'Barbell Squat',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.quadriceps,
        equipmentType: EquipmentType.barbell,
      ),
      const Exercise(
        id: '3',
        name: 'Deadlift',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.back,
        equipmentType: EquipmentType.barbell,
      ),
      const Exercise(
        id: '4',
        name: 'Pull-up',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.back,
        equipmentType: EquipmentType.bodyweight,
      ),
      const Exercise(
        id: '5',
        name: 'Overhead Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.shoulders,
        equipmentType: EquipmentType.barbell,
      ),
      const Exercise(
        id: '6',
        name: 'Barbell Row',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.back,
        equipmentType: EquipmentType.barbell,
      ),
      const Exercise(
        id: '7',
        name: 'Dumbbell Curl',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.biceps,
        equipmentType: EquipmentType.dumbbell,
      ),
      const Exercise(
        id: '8',
        name: 'Tricep Pushdown',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.triceps,
        equipmentType: EquipmentType.cable,
      ),
      const Exercise(
        id: '9',
        name: 'Incline Dumbbell Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.dumbbell,
      ),
      const Exercise(
        id: '10',
        name: 'Leg Press',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.quadriceps,
        equipmentType: EquipmentType.machine,
      ),
      const Exercise(
        id: '11',
        name: 'Romanian Deadlift',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.hamstrings,
        equipmentType: EquipmentType.barbell,
      ),
      const Exercise(
        id: '12',
        name: 'Hip Thrust',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.glutes,
        equipmentType: EquipmentType.barbell,
      ),
      const Exercise(
        id: '13',
        name: 'Lat Pulldown',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.back,
        equipmentType: EquipmentType.cable,
      ),
      const Exercise(
        id: '14',
        name: 'Cable Fly',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.cable,
      ),
      const Exercise(
        id: '15',
        name: 'Plank',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.core,
        equipmentType: EquipmentType.bodyweight,
      ),
      const Exercise(
        id: '16',
        name: 'Treadmill',
        category: ExerciseCategory.cardio,
        muscleGroup: MuscleGroup.cardio,
        equipmentType: EquipmentType.cardioMachine,
      ),
      const Exercise(
        id: '17',
        name: 'Stationary Bike',
        category: ExerciseCategory.cardio,
        muscleGroup: MuscleGroup.cardio,
        equipmentType: EquipmentType.cardioMachine,
      ),
      const Exercise(
        id: '18',
        name: 'Rowing Machine',
        category: ExerciseCategory.cardio,
        muscleGroup: MuscleGroup.fullBody,
        equipmentType: EquipmentType.cardioMachine,
      ),
    ];
  }

  @override
  Future<List<Exercise>> getAllExercises() async {
    return _exercises.where((e) => !e.isDeleted).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    final lower = query.toLowerCase();
    return _exercises
        .where(
          (e) => !e.isDeleted && e.name.toLowerCase().contains(lower),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(
    MuscleGroup muscleGroup,
  ) async {
    return _exercises
        .where((e) => !e.isDeleted && e.muscleGroup == muscleGroup)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Exercise?> getExercise(String id) async {
    try {
      return _exercises.firstWhere((e) => e.id == id && !e.isDeleted);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Exercise> createExercise(Exercise exercise) async {
    _exercises.add(exercise);
    _notify();
    return exercise;
  }

  @override
  Future<Exercise> updateExercise(Exercise exercise) async {
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _exercises[index] = exercise;
      _notify();
    }
    return exercise;
  }

  @override
  Future<void> deleteExercise(String id) async {
    final index = _exercises.indexWhere((e) => e.id == id);
    if (index != -1) {
      _exercises[index] =
          _exercises[index].copyWith(deletedAt: DateTime.now().toUtc());
      _notify();
    }
  }

  @override
  Stream<List<Exercise>> watchAllExercises() => _controller.stream;

  void _notify() {
    _controller.add(_exercises.where((e) => !e.isDeleted).toList()
      ..sort((a, b) => a.name.compareTo(b.name)));
  }
}
