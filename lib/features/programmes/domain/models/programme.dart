import 'package:uuid/uuid.dart';

enum ProgressionType {
  fixedIncrement,
  percentage,
  deload,
}

class Programme {
  final String id;
  final String name;
  final int durationWeeks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProgrammeDay> days;
  final List<ProgressionRule> rules;

  const Programme({
    required this.id,
    required this.name,
    required this.durationWeeks,
    required this.createdAt,
    required this.updatedAt,
    this.days = const [],
    this.rules = const [],
  });

  static Programme create(
      {required String name, required int durationWeeks}) {
    final now = DateTime.now().toUtc();
    return Programme(
      id: const Uuid().v4(),
      name: name,
      durationWeeks: durationWeeks,
      createdAt: now,
      updatedAt: now,
    );
  }

  Programme copyWith({
    String? name,
    int? durationWeeks,
    DateTime? updatedAt,
    List<ProgrammeDay>? days,
    List<ProgressionRule>? rules,
  }) {
    return Programme(
      id: id,
      name: name ?? this.name,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
      rules: rules ?? this.rules,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Programme &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ProgrammeDay {
  final String id;
  final String programmeId;
  final int weekNumber;
  final int dayOfWeek;
  final String templateId;
  final String templateName;
  final DateTime updatedAt;

  const ProgrammeDay({
    required this.id,
    required this.programmeId,
    required this.weekNumber,
    required this.dayOfWeek,
    required this.templateId,
    required this.templateName,
    required this.updatedAt,
  });

  static ProgrammeDay create({
    required String programmeId,
    required int weekNumber,
    required int dayOfWeek,
    required String templateId,
    required String templateName,
  }) {
    return ProgrammeDay(
      id: const Uuid().v4(),
      programmeId: programmeId,
      weekNumber: weekNumber,
      dayOfWeek: dayOfWeek,
      templateId: templateId,
      templateName: templateName,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  ProgrammeDay copyWith({
    int? weekNumber,
    int? dayOfWeek,
    String? templateId,
    String? templateName,
    DateTime? updatedAt,
  }) {
    return ProgrammeDay(
      id: id,
      programmeId: programmeId,
      weekNumber: weekNumber ?? this.weekNumber,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgrammeDay &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ProgressionRule {
  final String id;
  final String programmeId;
  final String exerciseId;
  final ProgressionType type;
  final double value;
  final int frequencyWeeks;
  final DateTime updatedAt;

  const ProgressionRule({
    required this.id,
    required this.programmeId,
    required this.exerciseId,
    required this.type,
    required this.value,
    this.frequencyWeeks = 1,
    required this.updatedAt,
  });

  static ProgressionRule create({
    required String programmeId,
    required String exerciseId,
    required ProgressionType type,
    required double value,
    int frequencyWeeks = 1,
  }) {
    return ProgressionRule(
      id: const Uuid().v4(),
      programmeId: programmeId,
      exerciseId: exerciseId,
      type: type,
      value: value,
      frequencyWeeks: frequencyWeeks,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  double applyProgression(double baseWeight) {
    return switch (type) {
      ProgressionType.fixedIncrement => baseWeight + value,
      ProgressionType.percentage => baseWeight * (1 + value / 100),
      ProgressionType.deload => baseWeight * (1 - value / 100),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressionRule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
