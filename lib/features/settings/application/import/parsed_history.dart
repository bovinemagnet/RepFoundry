/// Neutral output of a CSV format adapter: workout history parsed from a
/// foreign export, before exercise matching or persistence.
class ParsedSet {
  final String exerciseName;

  /// Always kg — adapters convert from the file's unit.
  final double weightKg;
  final int reps;
  final double? rpe;
  final bool isWarmUp;
  final DateTime timestamp;

  const ParsedSet({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    this.rpe,
    this.isWarmUp = false,
    required this.timestamp,
  });
}

class ParsedWorkout {
  /// Stable identifier for this workout within the source file (used for
  /// deterministic import IDs).
  final String sourceKey;
  final String? name;
  final DateTime startedAt;

  /// Never null: imported history is always complete, otherwise it would
  /// appear as an active workout.
  final DateTime completedAt;
  final List<ParsedSet> sets;

  const ParsedWorkout({
    required this.sourceKey,
    this.name,
    required this.startedAt,
    required this.completedAt,
    required this.sets,
  });
}

class ParsedHistory {
  /// Source format tag ('strong', 'hevy', 'repfoundry') — namespaces the
  /// deterministic IDs so identical rows from different apps stay distinct.
  final String source;
  final List<ParsedWorkout> workouts;

  /// Rows the adapter could not import (cardio-shaped, zero reps,
  /// unparseable) — surfaced in the import summary.
  final int rowsSkipped;

  const ParsedHistory({
    required this.source,
    required this.workouts,
    this.rowsSkipped = 0,
  });
}
