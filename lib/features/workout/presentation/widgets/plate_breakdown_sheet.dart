import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../../core/units/plate_calculator.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/units/weight_unit_provider.dart';
import '../../../settings/presentation/providers/plate_settings_provider.dart';

/// Bottom-sheet body showing which plates to load on each side of the bar for
/// [workingKg], using the bar and plate sizes set for the active weight unit.
class PlateBreakdownSheet extends ConsumerWidget {
  const PlateBreakdownSheet({super.key, required this.workingKg});

  final double workingKg;

  static Future<void> show(BuildContext context, double workingKg) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => PlateBreakdownSheet(workingKg: workingKg),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final unit = ref.watch(weightUnitProvider);
    final setup = ref.watch(plateSettingsProvider).forUnit(unit);
    // Plate maths runs on the weight as displayed (1 dp), so a pound value
    // stored as kg does not come back a fraction light.
    final target = double.parse(unit.formatFromKg(workingKg));
    final result = platesForWeight(
      target: target,
      bar: setup.bar,
      plates: setup.plates,
    );
    String weight(double value) =>
        '${formatPlateWeight(value)}${unit.label(s)}';

    final bodyStyle = KineticText.mono(size: 15, color: cs.onSurface);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.plateCalculatorTitle,
              style: KineticText.display(size: 18, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              s.plateTargetAndBar(weight(target), weight(setup.bar)),
              style: KineticText.mono(size: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (result.isBelowBar)
              Text(s.plateBelowBar(weight(setup.bar)), style: bodyStyle)
            else if (result.perSide.isEmpty && result.isExact)
              Text(s.plateJustTheBar, style: bodyStyle)
            else ...[
              Text(
                s.platesPerSide.toUpperCase(),
                style: KineticText.mono(
                  size: 12,
                  letterSpacing: 0.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              for (final p in result.perSide)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child:
                      Text('${weight(p.plate)} × ${p.count}', style: bodyStyle),
                ),
            ],
            if (result.shortfall > 0) ...[
              const SizedBox(height: 12),
              Text(
                s.plateClosest(
                  weight(result.loaded),
                  weight(result.shortfall),
                ),
                style: KineticText.mono(size: 13, color: cs.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
