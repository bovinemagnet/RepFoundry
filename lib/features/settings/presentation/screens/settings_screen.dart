import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../heart_rate/domain/warning_messages.dart';
import '../../../heart_rate/domain/zone_calculator.dart';
import '../../../heart_rate/presentation/providers/health_profile_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Health Profile'),
          ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: const Text('Age'),
            subtitle: userAge != null
                ? Text('$userAge years (max HR: ${220 - userAge} bpm)')
                : const Text('Set your age for heart rate zones'),
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
            title: const Text('Resting Heart Rate'),
            subtitle: profile.restingHeartRate != null
                ? Text('${profile.restingHeartRate} bpm')
                : const Text('Optional — enables Karvonen zones'),
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
              title: 'Resting Heart Rate',
              label: 'BPM',
              hint: 'e.g. 60',
              suffix: 'bpm',
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
            title: const Text('Measured Max Heart Rate'),
            subtitle: profile.measuredMaxHeartRate != null
                ? Text('${profile.measuredMaxHeartRate} bpm')
                : const Text('Optional — from exercise testing'),
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
              title: 'Measured Max Heart Rate',
              label: 'BPM',
              hint: 'e.g. 185',
              suffix: 'bpm',
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
            title: const Text('Beta Blocker Medication'),
            subtitle: const Text('Affects heart rate zone accuracy'),
            value: profile.takingBetaBlocker,
            onChanged: (v) => ref
                .read(healthProfileProvider.notifier)
                .setTakingBetaBlocker(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.favorite_outline),
            title: const Text('Heart Condition'),
            subtitle: const Text('Enables caution mode for zones'),
            value: profile.hasHeartCondition,
            onChanged: (v) => ref
                .read(healthProfileProvider.notifier)
                .setHasHeartCondition(v),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: const Text('Clinician Max Heart Rate'),
            subtitle: profile.clinicianMaxHr != null
                ? Text('${profile.clinicianMaxHr} bpm — overrides estimates')
                : const Text('Optional — from your doctor'),
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
              title: 'Clinician Max Heart Rate',
              label: 'BPM',
              hint: 'e.g. 150',
              suffix: 'bpm',
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
              title: const Text('Zone Method'),
              subtitle: Text(
                '${_methodLabel(zoneConfig.activeMethod)} · '
                '${_reliabilityLabel(zoneConfig.reliability)} confidence',
              ),
            ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Set Up Heart Rate Zones'),
            subtitle: const Text('Step-by-step guided setup'),
            onTap: () => showHealthProfileOnboarding(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: const Text('Zone Colour Bands'),
            subtitle: const Text(
              'Show coloured zone bands on HR chart',
            ),
            value: ref.watch(zoneBandsProvider),
            onChanged: (_) => ref.read(zoneBandsProvider.notifier).toggle(),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Disclaimer'),
            subtitle: Text(WarningMessages.generalDisclaimer),
          ),
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Auto'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (modes) {
                ref.read(_themeModeProvider.notifier).set(modes.first);
              },
            ),
          ),
          const _SectionHeader(title: 'Units'),
          ListTile(
            leading: const Icon(Icons.scale_outlined),
            title: const Text('Weight Unit'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'kg',
                  label: Text('kg'),
                ),
                ButtonSegment(
                  value: 'lbs',
                  label: Text('lbs'),
                ),
              ],
              selected: {weightUnit},
              onSelectionChanged: (units) {
                ref.read(_weightUnitProvider.notifier).set(units.first);
              },
            ),
          ),
          const _SectionHeader(title: 'Rest Timer'),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibration Alert'),
            subtitle: const Text('Vibrate when rest timer completes'),
            value: ref.watch(restTimerSettingsProvider).vibrationEnabled,
            onChanged: (_) {
              ref.read(restTimerSettingsProvider.notifier).toggleVibration();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Sound Alert'),
            subtitle: const Text('Play a sound when rest timer completes'),
            value: ref.watch(restTimerSettingsProvider).soundEnabled,
            onChanged: (_) {
              ref.read(restTimerSettingsProvider.notifier).toggleSound();
            },
          ),
          const _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Clear All Data'),
            subtitle: const Text(
              'Permanently delete all workouts and settings.',
            ),
            textColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
            onTap: () => _confirmClearData(context),
          ),
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('RepFoundry'),
            subtitle: Text('Version 1.0.0'),
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
    final controller = TextEditingController(
      text: currentAge?.toString() ?? '',
    );
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Your Age'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'e.g. 30',
            border: OutlineInputBorder(),
            suffixText: 'years',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final age = int.tryParse(controller.text);
              if (age != null && age > 0 && age <= 120) {
                Navigator.pop(ctx, age);
              }
            },
            child: const Text('Save'),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null) {
      onSave(result);
    }
  }

  String _methodLabel(ZoneMethod method) {
    return switch (method) {
      ZoneMethod.custom => 'Custom zones',
      ZoneMethod.clinicianCap => 'Clinician cap',
      ZoneMethod.hrr => 'Heart rate reserve (Karvonen)',
      ZoneMethod.percentOfMeasuredMax => 'Measured max HR',
      ZoneMethod.percentOfEstimatedMax => 'Age-estimated max HR',
    };
  }

  String _reliabilityLabel(ZoneReliability reliability) {
    return switch (reliability) {
      ZoneReliability.high => 'High',
      ZoneReliability.medium => 'Medium',
      ZoneReliability.low => 'Low',
    };
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your workout history and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared.')),
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
