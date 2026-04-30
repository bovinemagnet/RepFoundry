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

  /// When the user pressed "Start programme". Null until they start.
  /// Used to compute [currentWeek] so multi-week programmes advance.
  final DateTime? startedAt;
  final DateTime? deletedAt;
  final List<ProgrammeDay> days;
  final List<ProgressionRule> rules;

  const Programme({
    required this.id,
    required this.name,
    required this.durationWeeks,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.deletedAt,
    this.days = const [],
    this.rules = const [],
  });

  bool get isDeleted => deletedAt != null;

  /// 1-based current week of the programme, clamped to [1, durationWeeks].
  /// Returns 1 if the programme has not been started yet.
  int currentWeek({DateTime? now}) {
    if (startedAt == null) return 1;
    final reference = (now ?? DateTime.now().toUtc());
    final daysSinceStart = reference.difference(startedAt!).inDays;
    final week = (daysSinceStart ~/ 7) + 1;
    if (week < 1) return 1;
    if (week > durationWeeks) return durationWeeks;
    return week;
  }

  bool get isStarted => startedAt != null;

  static Programme create({required String name, required int durationWeeks}) {
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
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? deletedAt,
    List<ProgrammeDay>? days,
    List<ProgressionRule>? rules,
  }) {
    return Programme(
      id: id,
      name: name ?? this.name,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      deletedAt: deletedAt ?? this.deletedAt,
      days: days ?? this.days,
      rules: rules ?? this.rules,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Programme && runtimeType == other.runtimeType && id == other.id;

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
  final DateTime? deletedAt;

  const ProgrammeDay({
    required this.id,
    required this.programmeId,
    required this.weekNumber,
    required this.dayOfWeek,
    required this.templateId,
    required this.templateName,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

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
    DateTime? deletedAt,
  }) {
    return ProgrammeDay(
      id: id,
      programmeId: programmeId,
      weekNumber: weekNumber ?? this.weekNumber,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
  final DateTime? deletedAt;

  const ProgressionRule({
    required this.id,
    required this.programmeId,
    required this.exerciseId,
    required this.type,
    required this.value,
    this.frequencyWeeks = 1,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

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
