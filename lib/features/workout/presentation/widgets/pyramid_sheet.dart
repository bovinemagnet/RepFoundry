import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/units/plate_calculator.dart';
import '../../../../core/units/pyramid.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/units/weight_unit_provider.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../settings/presentation/providers/plate_settings_provider.dart';
import '../controllers/active_workout_controller.dart';

/// Previews an ascending pyramid (#84) climbing to [workingKg] and, on
/// confirmation, makes it [exercise]'s suggested sets. Nothing is logged.
Future<void> showPyramidSheet(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise,
  double workingKg,
) async {
  final unit = ref.read(weightUnitProvider);
  // Read once below, so the saved bar and plates must be in place first.
  await ref.read(plateSettingsProvider.notifier).ensureLoaded();
  if (!context.mounted) return;
  // Worked in the displayed unit, where the loadable steps are whole numbers.
  final top = unit.fromKg(workingKg);
  final increment = unit == WeightUnit.kg ? 2.5 : 5.0;
  final sets = switch (exercise.equipmentType) {
    // A barbell loads in pairs of the smallest plate on the bar in use.
    EquipmentType.barbell => () {
        final setup = ref.read(plateSettingsProvider).forUnit(unit);
        final step =
            setup.plates.isEmpty ? increment : 2 * setup.plates.reduce(min);
        return pyramidSets(
          top: top,
          base: setup.bar,
          step: step,
          minimum: setup.bar,
        );
      }(),
    _ => pyramidSets(
        top: top,
        base: 0,
        step: increment,
        minimum: increment,
      ),
  };
  if (sets.isEmpty) return;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final s = S.of(ctx)!;
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.pyramidTitle,
                style: KineticText.display(size: 18, color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.name,
                style: KineticText.mono(size: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              for (final set in sets)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${formatPlateWeight(set.weight)}${unit.label(s)}'
                    ' × ${set.reps}',
                    style: KineticText.mono(size: 15, color: cs.onSurface),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: KineticCta(
                  label: s.usePyramid,
                  icon: Icons.check,
                  onPressed: () => Navigator.pop(ctx, true),
                  height: 46,
                  borderRadius: 13,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmed != true) return;
  ref.read(activeWorkoutControllerProvider.notifier).applyPyramid(
    exercise.id,
    [
      for (final set in sets) (weightKg: unit.toKg(set.weight), reps: set.reps),
    ],
  );
}
