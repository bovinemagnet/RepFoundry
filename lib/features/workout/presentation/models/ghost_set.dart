/// A lightweight representation of a set from a previous session,
/// used as a pre-fill suggestion for the current workout.
class GhostSet {
  final double weight;
  final int reps;
  final double? rpe;
  final int setOrder;

  const GhostSet({
    required this.weight,
    required this.reps,
    this.rpe,
    required this.setOrder,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GhostSet &&
          runtimeType == other.runtimeType &&
          weight == other.weight &&
          reps == other.reps &&
          rpe == other.rpe &&
          setOrder == other.setOrder;

  @override
  int get hashCode => Object.hash(weight, reps, rpe, setOrder);

  @override
  String toString() =>
      'GhostSet(weight: $weight, reps: $reps, rpe: $rpe, setOrder: $setOrder)';
}
