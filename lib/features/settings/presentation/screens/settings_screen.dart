import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../heart_rate/domain/zone_calculator.dart';
import '../../../heart_rate/presentation/providers/health_profile_provider.dart';
import '../../../heart_rate/presentation/providers/max_hr_alert_provider.dart';
import '../../../heart_rate/presentation/providers/zone_bands_provider.dart';
import '../../../heart_rate/presentation/providers/zone_configuration_provider.dart';
import '../../../heart_rate/presentation/widgets/health_profile_onboarding.dart';
import '../providers/rest_timer_settings_provider.dart';
import '../providers/user_age_provider.dart';

final _themeModeProvider = StateNotifierProvider<_ThemeModeNotifier, ThemeMode>(
  (ref) => _ThemeModeNotifier(),
);

class _ThemeModeNotifier extends StateNotifier<ThemeMode> {
  _ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('theme_mode') ?? 'dark';
    state = _fromString(value);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }
}

final _weightUnitProvider = StateNotifierProvider<_WeightUnitNotifier, String>(
  (ref) => _WeightUnitNotifier(),
);

class _WeightUnitNotifier extends StateNotifier<String> {
  _WeightUnitNotifier() : super('kg') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('weight_unit') ?? 'kg';
  }

  Future<void> set(String unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_unit', unit);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(_themeModeProvider);
    final weightUnit = ref.watch(_weightUnitProvider);
    final userAge = ref.watch(userAgeProvider);
    final profile = ref.watch(healthProfileProvider);
    final zoneConfig = ref.watch(zoneConfigurationProvider);

    final s = S.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: s.sectionHealthProfile),
          ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: Text(s.ageLabel),
            subtitle: userAge != null
                ? Text(s.ageSubtitleSet(userAge, 220 - userAge))
                : Text(s.ageSubtitleEmpty),
            trailing: userAge != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () =>
                        ref.read(userAgeProvider.notifier).setAge(null),
                  )
                : null,
            onTap: () => _showAgeDialog(context, ref, userAge),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart_outlined),
            title: Text(s.restingHeartRate),
            subtitle: profile.restingHeartRate != null
                ? Text(s.restingHrSubtitleSet(profile.restingHeartRate!))
                : Text(s.restingHrSubtitleEmpty),
            trailing: profile.restingHeartRate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref
                        .read(healthProfileProvider.notifier)
                        .updateRestingHeartRate(null),
                  )
                : null,
            onTap: () => _showIntDialog(
              context,
              ref,
              title: s.restingHeartRate,
              label: s.bpmSuffix,
              hint: s.restingHrHint,
              suffix: s.bpmSuffix,
              current: profile.restingHeartRate,
              min: 20,
              max: 220,
              onSave: (v) => ref
                  .read(healthProfileProvider.notifier)
                  .updateRestingHeartRate(v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: Text(s.measuredMaxHeartRate),
            subtitle: profile.measuredMaxHeartRate != null
                ? Text(
                    s.measuredMaxHrSubtitleSet(profile.measuredMaxHeartRate!))
                : Text(s.measuredMaxHrSubtitleEmpty),
            trailing: profile.measuredMaxHeartRate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref
                        .read(healthProfileProvider.notifier)
                        .updateMeasuredMaxHeartRate(null),
                  )
                : null,
            onTap: () => _showIntDialog(
              context,
              ref,
              title: s.measuredMaxHeartRate,
              label: s.bpmSuffix,
              hint: s.measuredMaxHrHint,
              suffix: s.bpmSuffix,
              current: profile.measuredMaxHeartRate,
              min: 60,
              max: 250,
              onSave: (v) => ref
                  .read(healthProfileProvider.notifier)
                  .updateMeasuredMaxHeartRate(v),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.medication_outlined),
            title: Text(s.betaBlockerMedication),
            subtitle: Text(s.betaBlockerSubtitle),
            value: profile.takingBetaBlocker,
            onChanged: (v) => ref
                .read(healthProfileProvider.notifier)
                .setTakingBetaBlocker(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.favorite_outline),
            title: Text(s.heartConditionLabel),
            subtitle: Text(s.heartConditionSubtitle),
            value: profile.hasHeartCondition,
            onChanged: (v) => ref
                .read(healthProfileProvider.notifier)
                .setHasHeartCondition(v),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: Text(s.clinicianMaxHeartRate),
            subtitle: profile.clinicianMaxHr != null
                ? Text(s.clinicianMaxHrSubtitleSet(profile.clinicianMaxHr!))
                : Text(s.clinicianMaxHrSubtitleEmpty),
            trailing: profile.clinicianMaxHr != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref
                        .read(healthProfileProvider.notifier)
                        .setClinicianMaxHr(null),
                  )
                : null,
            onTap: () => _showIntDialog(
              context,
              ref,
              title: s.clinicianMaxHeartRate,
              label: s.bpmSuffix,
              hint: s.clinicianMaxHrHint,
              suffix: s.bpmSuffix,
              current: profile.clinicianMaxHr,
              min: 60,
              max: 250,
              onSave: (v) =>
                  ref.read(healthProfileProvider.notifier).setClinicianMaxHr(v),
            ),
          ),
          if (zoneConfig != null)
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: Text(s.zoneMethod),
              subtitle: Text(
                '${_methodLabel(zoneConfig.activeMethod, s)} · '
                '${_reliabilityLabel(zoneConfig.reliability, s)} confidence',
              ),
            ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: Text(s.setUpHeartRateZones),
            subtitle: Text(s.stepByStepGuidedSetup),
            onTap: () => showHealthProfileOnboarding(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: Text(s.zoneColourBands),
            subtitle: Text(
              s.zoneColourBandsSubtitle,
            ),
            value: ref.watch(zoneBandsProvider),
            onChanged: (_) => ref.read(zoneBandsProvider.notifier).toggle(),
          ),
          _SectionHeader(title: s.sectionMaxHrAlert),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(s.maxHrAlertVibration),
            subtitle: Text(s.maxHrAlertVibrationSubtitle),
            value: ref.watch(maxHrAlertProvider).vibrationEnabled,
            onChanged: (_) =>
                ref.read(maxHrAlertProvider.notifier).toggleVibration(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(s.maxHrAlertSound),
            subtitle: Text(s.maxHrAlertSoundSubtitle),
            value: ref.watch(maxHrAlertProvider).soundEnabled,
            onChanged: (_) =>
                ref.read(maxHrAlertProvider.notifier).toggleSound(),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(s.maxHrAlertCooldown),
            subtitle: Text(s.maxHrAlertCooldownSubtitle),
            trailing: DropdownButton<int>(
              value: ref.watch(maxHrAlertProvider).cooldownSeconds,
              underline: const SizedBox.shrink(),
              items: const [10, 15, 30, 60]
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text('${v}s'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(maxHrAlertProvider.notifier).setCooldown(v);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.disclaimerLabel),
            subtitle: Text(s.warningGeneralDisclaimer),
          ),
          _SectionHeader(title: s.sectionAppearance),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(s.themeLabel),
            trailing: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode),
                  label: Text(s.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode),
                  label: Text(s.themeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto),
                  label: Text(s.themeAuto),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (modes) {
                ref.read(_themeModeProvider.notifier).set(modes.first);
              },
            ),
          ),
          _SectionHeader(title: s.sectionUnits),
          ListTile(
            leading: const Icon(Icons.scale_outlined),
            title: Text(s.weightUnitLabel),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'kg',
                  label: Text(s.kgUnit),
                ),
                ButtonSegment(
                  value: 'lbs',
                  label: Text(s.lbsUnit),
                ),
              ],
              selected: {weightUnit},
              onSelectionChanged: (units) {
                ref.read(_weightUnitProvider.notifier).set(units.first);
              },
            ),
          ),
          _SectionHeader(title: s.sectionRestTimer),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(s.vibrationAlert),
            subtitle: Text(s.vibrationAlertSubtitle),
            value: ref.watch(restTimerSettingsProvider).vibrationEnabled,
            onChanged: (_) {
              ref.read(restTimerSettingsProvider.notifier).toggleVibration();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(s.soundAlert),
            subtitle: Text(s.soundAlertSubtitle),
            value: ref.watch(restTimerSettingsProvider).soundEnabled,
            onChanged: (_) {
              ref.read(restTimerSettingsProvider.notifier).toggleSound();
            },
          ),
          _SectionHeader(title: s.sectionData),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: Text(s.clearAllData),
            subtitle: Text(
              s.clearAllDataSubtitle,
            ),
            textColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
            onTap: () => _confirmClearData(context),
          ),
          _SectionHeader(title: s.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.aboutAppName),
            subtitle: Text(s.aboutVersion),
          ),
        ],
      ),
    );
  }

  Future<void> _showAgeDialog(
    BuildContext context,
    WidgetRef ref,
    int? currentAge,
  ) async {
    final s = S.of(context)!;
    final controller = TextEditingController(
      text: currentAge?.toString() ?? '',
    );
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.setYourAge),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s.ageLabel,
            hintText: s.ageHint,
            border: const OutlineInputBorder(),
            suffixText: s.yearsSuffix,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final age = int.tryParse(controller.text);
              if (age != null && age > 0 && age <= 120) {
                Navigator.pop(ctx, age);
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null) {
      ref.read(userAgeProvider.notifier).setAge(result);
    }
  }

  Future<void> _showIntDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String label,
    required String hint,
    required String suffix,
    required int? current,
    required int min,
    required int max,
    required void Function(int) onSave,
  }) async {
    final s = S.of(context)!;
    final controller = TextEditingController(
      text: current?.toString() ?? '',
    );
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            suffixText: suffix,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                Navigator.pop(ctx, value);
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null) {
      onSave(result);
    }
  }

  String _methodLabel(ZoneMethod method, S s) {
    return switch (method) {
      ZoneMethod.custom => s.zoneMethodCustom,
      ZoneMethod.clinicianCap => s.zoneMethodClinicianCap,
      ZoneMethod.hrr => s.zoneMethodHrr,
      ZoneMethod.percentOfMeasuredMax => s.zoneMethodMeasuredMax,
      ZoneMethod.percentOfEstimatedMax => s.zoneMethodEstimatedMax,
    };
  }

  String _reliabilityLabel(ZoneReliability reliability, S s) {
    return switch (reliability) {
      ZoneReliability.high => s.reliabilityHigh,
      ZoneReliability.medium => s.reliabilityMedium,
      ZoneReliability.low => s.reliabilityLow,
    };
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearAllDataConfirmTitle),
        content: Text(
          s.clearAllDataConfirmContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.allDataCleared)),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
