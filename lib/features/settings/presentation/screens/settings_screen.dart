import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/rest_timer_settings_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
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
