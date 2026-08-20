import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/reminder_settings_provider.dart';

class ReminderDaysPicker extends ConsumerWidget {
  const ReminderDaysPicker({super.key, this.onBeforeToggle});

  final Future<bool> Function()? onBeforeToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final settings = ref.watch(reminderSettingsProvider);
    final dayLabels = <int, String>{
      DateTime.monday: s.mondayShort,
      DateTime.tuesday: s.tuesdayShort,
      DateTime.wednesday: s.wednesdayShort,
      DateTime.thursday: s.thursdayShort,
      DateTime.friday: s.fridayShort,
      DateTime.saturday: s.saturdayShort,
      DateTime.sunday: s.sundayShort,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Wrap, not Row: seven chips do not fit across a phone. A Row
      // overflowed by 39px on a 402dp screen and by more on narrower ones.
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: dayLabels.entries.map((entry) {
          final selected = settings.enabledDays.contains(entry.key);
          return FilterChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) async {
              final shouldProceed =
                  onBeforeToggle == null ? true : await onBeforeToggle!();
              if (!shouldProceed) return;
              await ref
                  .read(reminderSettingsProvider.notifier)
                  .toggleDay(entry.key);
            },
          );
        }).toList(),
      ),
    );
  }
}
