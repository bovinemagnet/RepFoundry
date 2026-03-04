import 'package:uuid/uuid.dart';

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  core,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  fullBody,
  cardio,
}

enum EquipmentType {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  resistanceBand,
  cardioMachine,
  other,
}

enum ExerciseCategory {
  strength,
  cardio,
  flexibility,
  custom,
}

class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final MuscleGroup muscleGroup;
  final EquipmentType equipmentType;
  final bool isCustom;
  final DateTime? deletedAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipmentType,
    this.isCustom = false,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    MuscleGroup? muscleGroup,
    EquipmentType? equipmentType,
    bool? isCustom,
    DateTime? deletedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipmentType: equipmentType ?? this.equipmentType,
      isCustom: isCustom ?? this.isCustom,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static Exercise create({
    required String name,
    required ExerciseCategory category,
    required MuscleGroup muscleGroup,
    required EquipmentType equipmentType,
    bool isCustom = false,
  }) {
    return Exercise(
      id: const Uuid().v4(),
      name: name,
      category: category,
      muscleGroup: muscleGroup,
      equipmentType: equipmentType,
      isCustom: isCustom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Exercise(id: $id, name: $name, category: $category)';
}
