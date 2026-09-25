/// Ascending pyramid (#84): each set heavier and shorter than the last, up to
/// the working weight. Each entry is a %-of-one-rep-max and its reps; the top
/// set (4 reps) sits at 90 %, so the others are scaled from it.
const List<(double oneRepMaxFraction, int reps)> _pyramidScheme = [
  (0.70, 12),
  (0.75, 10),
  (0.80, 8),
  (0.85, 6),
  (0.90, 4),
];

/// Builds the pyramid climbing to [top], in one display unit (kg or lbs).
///
/// Weights below the top set are rounded to the nearest loadable weight:
/// [base] plus a whole number of [step]s (a barbell's bar plus pairs of its
/// smallest plate, or zero plus a dumbbell increment), never under [minimum]
/// nor above [top]. The top set is [top] exactly. Returns an empty list when
/// there is no working weight.
List<({double weight, int reps})> pyramidSets({
  required double top,
  required double base,
  required double step,
  required double minimum,
}) {
  if (top <= 0) return const [];
  final topFraction = _pyramidScheme.last.$1;

  return [
    for (final (fraction, reps) in _pyramidScheme)
      if (fraction == topFraction)
        (weight: top, reps: reps)
      else
        (
          weight:
              _loadable(top * fraction / topFraction, base, step, minimum, top),
          reps: reps
        ),
  ];
}

double _loadable(
  double target,
  double base,
  double step,
  double minimum,
  double top,
) {
  final steps = ((target - base) / step).round();
  final weight = base + steps * step;
  if (weight < minimum) return minimum > top ? top : minimum;
  return weight > top ? top : weight;
}
