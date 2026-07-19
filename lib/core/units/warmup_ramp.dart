import '../../features/exercises/domain/models/exercise.dart';
import 'weight_unit.dart';

/// Standard Olympic barbell weights.
const double barWeightKg = 20.0;
const double barWeightLbs = 45.0;

/// Smallest weight change loadable with a common plate pair, per unit.
const double plateIncrementKg = 2.5;
const double plateIncrementLbs = 5.0;

/// Equipment whose load can be ramped up with plates/selectable weight.
const Set<EquipmentType> _loadableEquipment = {
  EquipmentType.barbell,
  EquipmentType.dumbbell,
  EquipmentType.kettlebell,
  EquipmentType.cable,
  EquipmentType.machine,
};

/// Whether [equipment] can be warmed up with a ramp (loadable resistance).
bool isWarmupRampable(EquipmentType equipment) =>
    _loadableEquipment.contains(equipment);

/// One warm-up set: a rounded, loadable weight (kg) and its rep count.
class WarmupStep {
  final double weightKg;
  final int reps;

  /// True for the empty-bar step (barbell only).
  final bool isBarOnly;

  const WarmupStep({
    required this.weightKg,
    required this.reps,
    this.isBarOnly = false,
  });
}

/// Percentage-of-working-weight steps and their reps, heaviest last.
const List<(double pct, int reps)> _rampScheme = [
  (0.40, 5),
  (0.60, 3),
  (0.80, 1),
];

/// Generates a warm-up ramp for [workingKg] on [equipment], with weights
/// rounded to a loadable increment in the user's [unit].
///
/// Barbell ramps open with an empty-bar set (20 kg / 45 lb). Other loadable
/// equipment starts at the first percentage step. Steps at or below the bar
/// (or below one increment for non-barbell), and consecutive duplicate
/// weights, collapse out. Returns an empty list for non-loadable equipment
/// or a non-positive working weight.
List<WarmupStep> warmupRamp({
  required double workingKg,
  required EquipmentType equipment,
  required WeightUnit unit,
}) {
  if (workingKg <= 0 || !_loadableEquipment.contains(equipment)) {
    return const [];
  }

  final increment =
      unit == WeightUnit.kg ? plateIncrementKg : plateIncrementLbs;
  final barKg = equipment == EquipmentType.barbell
      ? (unit == WeightUnit.kg ? barWeightKg : barWeightLbs / lbsPerKg)
      : 0.0;
  // Non-barbell steps must clear at least one increment to be loadable.
  final floorKg = equipment == EquipmentType.barbell
      ? barKg
      : (unit == WeightUnit.kg ? increment : increment / lbsPerKg);

  /// Rounds a kg weight to the nearest loadable increment in the display unit.
  double roundToIncrement(double kg) {
    final display = unit.fromKg(kg);
    final rounded = (display / increment).round() * increment;
    return unit.toKg(rounded);
  }

  final steps = <WarmupStep>[];

  if (equipment == EquipmentType.barbell) {
    steps.add(WarmupStep(weightKg: barKg, reps: 10, isBarOnly: true));
  }

  for (final (pct, reps) in _rampScheme) {
    final weight = roundToIncrement(workingKg * pct);
    // Drop steps that don't clear the floor.
    if (equipment == EquipmentType.barbell) {
      if (weight <= floorKg) continue;
    } else if (weight < floorKg) {
      continue;
    }
    // Drop a step equal to the previous one.
    if (steps.isNotEmpty && (steps.last.weightKg - weight).abs() < 0.0001) {
      continue;
    }
    steps.add(WarmupStep(weightKg: weight, reps: reps));
  }

  return steps;
}
