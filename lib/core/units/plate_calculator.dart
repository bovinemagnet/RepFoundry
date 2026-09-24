/// How a barbell is loaded to reach [target]. All weights are in one display
/// unit (kg or lbs), never mixed.
class PlateBreakdown {
  final double target;
  final double bar;

  /// Plates for one side of the bar, heaviest first.
  final List<({double plate, int count})> perSide;

  const PlateBreakdown({
    required this.target,
    required this.bar,
    required this.perSide,
  });

  /// Total weight on the bar: the bar plus both sides.
  double get loaded =>
      bar + 2 * perSide.fold<double>(0, (sum, p) => sum + p.plate * p.count);

  /// How far [loaded] falls short of [target]; zero when exact or below bar.
  double get shortfall {
    final gap = target - loaded;
    return gap > 0 ? gap : 0;
  }

  bool get isBelowBar => target < bar;

  bool get isExact => target == loaded;
}

/// Loads [plates] (sizes available, unlimited pairs of each) largest first
/// onto a [bar] to reach [target] without exceeding it.
PlateBreakdown platesForWeight({
  required double target,
  required double bar,
  required Iterable<double> plates,
}) {
  final perSide = <({double plate, int count})>[];
  var remaining = (target - bar) / 2;
  final sizes = plates.toSet().toList()..sort((a, b) => b.compareTo(a));
  for (final plate in sizes) {
    if (plate <= 0) continue;
    final count = (remaining / plate).floor();
    if (count > 0) {
      perSide.add((plate: plate, count: count));
      remaining -= plate * count;
    }
  }
  return PlateBreakdown(target: target, bar: bar, perSide: perSide);
}

/// Formats a plate or bar weight to at most two decimals, dropping trailing
/// zeros (20, 2.5, 1.25).
String formatPlateWeight(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
