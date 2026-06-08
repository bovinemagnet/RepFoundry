import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_zones/hr_zones.dart';
import '../../../heart_rate/presentation/providers/health_profile_provider.dart';
import '../../../heart_rate/presentation/providers/max_hr_alert_provider.dart';
import '../../../heart_rate/presentation/providers/zone_bands_provider.dart';
import '../../../heart_rate/presentation/providers/zone_configuration_provider.dart';
import '../../../heart_rate/presentation/widgets/health_profile_onboarding.dart';
import '../../../../core/providers.dart'
    show
        healthSyncServiceProvider,
        importDataUseCaseProvider,
        syncOrchestratorProvider;
import '../../../sync/domain/models/sync_state.dart';
import '../../../sync/presentation/providers/sync_settings_provider.dart';
import '../../../sync/presentation/widgets/sync_consent_dialog.dart';
import '../../../health_sync/presentation/providers/health_sync_settings_provider.dart';
import '../providers/export_provider.dart';
import '../providers/rest_timer_settings_provider.dart';
import '../providers/show_exercise_images_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/user_age_provider.dart';
import '../../../notifications/presentation/providers/reminder_settings_provider.dart';
import '../../../notifications/domain/models/reminder_settings.dart';
import '../../../../core/widgets/kinetic.dart';

final _weightUnitProvider = NotifierProvider<_WeightUnitNotifier, String>(
  _WeightUnitNotifier.new,
);

class _WeightUnitNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'kg';
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

// ─── Public screen ────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final weightUnit = ref.watch(_weightUnitProvider);
    final userAge = ref.watch(userAgeProvider);
    final profile = ref.watch(healthProfileProvider);
    final zoneConfig = ref.watch(zoneConfigurationProvider);

    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // No AppBar — the pagehead sits inside the scrollable body.
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 96),
          children: [
            // ── Pagehead ──────────────────────────────────────────────────
            _Pagehead(s: s),

            const SizedBox(height: 6),

            // ── HEALTH PROFILE ────────────────────────────────────────────
            KineticSectionLabel(s.sectionHealthProfile),
            const SizedBox(height: 11),
            _Set2Card(children: [
              // Age
              _Set2Row(
                icon: Icons.cake_outlined,
                title: s.ageLabel,
                subtitle: userAge != null
                    ? s.ageSubtitleSet(
                        userAge,
                        profile.estimatedMaxHr ??
                            MaxHrFormula.tanaka.apply(userAge),
                      )
                    : s.ageSubtitleEmpty,
                trailing: userAge != null
                    ? _ClearButton(
                        onPressed: () =>
                            ref.read(userAgeProvider.notifier).setAge(null),
                      )
                    : null,
                onTap: () => _showAgeDialog(context, ref, userAge),
              ),
              // Resting HR
              _Set2Row(
                icon: Icons.monitor_heart_outlined,
                title: s.restingHeartRate,
                subtitle: profile.restingHr != null
                    ? s.restingHrSubtitleSet(profile.restingHr!)
                    : s.restingHrSubtitleEmpty,
                trailing: profile.restingHr != null
                    ? _ClearButton(
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
                  current: profile.restingHr,
                  min: 20,
                  max: 220,
                  onSave: (v) => ref
                      .read(healthProfileProvider.notifier)
                      .updateRestingHeartRate(v),
                ),
              ),
              // Measured Max HR
              _Set2Row(
                icon: Icons.speed_outlined,
                title: s.measuredMaxHeartRate,
                subtitle: profile.measuredMaxHr != null
                    ? s.measuredMaxHrSubtitleSet(profile.measuredMaxHr!)
                    : s.measuredMaxHrSubtitleEmpty,
                trailing: profile.measuredMaxHr != null
                    ? _ClearButton(
                        onPressed: () => ref
                            .read(healthProfileProvider.notifier)
                            .updateMeasuredMaxHeartRate(null),
                      )
                    : _ChevronTrailing(),
                onTap: () => _showIntDialog(
                  context,
                  ref,
                  title: s.measuredMaxHeartRate,
                  label: s.bpmSuffix,
                  hint: s.measuredMaxHrHint,
                  suffix: s.bpmSuffix,
                  current: profile.measuredMaxHr,
                  min: 60,
                  max: 250,
                  onSave: (v) => ref
                      .read(healthProfileProvider.notifier)
                      .updateMeasuredMaxHeartRate(v),
                ),
              ),
              // Beta Blocker
              _Set2Row(
                icon: Icons.medication_outlined,
                title: s.betaBlockerMedication,
                subtitle: s.betaBlockerSubtitle,
                trailing: _KineticToggle(
                  value: profile.betaBlocker,
                  onChanged: (v) => ref
                      .read(healthProfileProvider.notifier)
                      .setTakingBetaBlocker(v),
                ),
              ),
              // Heart Condition
              _Set2Row(
                icon: Icons.favorite_outline,
                title: s.heartConditionLabel,
                subtitle: s.heartConditionSubtitle,
                trailing: _KineticToggle(
                  value: profile.heartCondition,
                  onChanged: (v) => ref
                      .read(healthProfileProvider.notifier)
                      .setHasHeartCondition(v),
                ),
              ),
              // Zone Method
              if (zoneConfig != null)
                _Set2Row(
                  icon: Icons.bar_chart_outlined,
                  title: s.zoneMethod,
                  subtitle: '${_methodLabel(zoneConfig.method, s)} · '
                      '${_reliabilityLabel(zoneConfig.reliability, s)} confidence',
                  trailing: _ChevronTrailing(),
                ),
              // Set up HR Zones (guided onboarding)
              _Set2Row(
                icon: Icons.tune_outlined,
                title: s.setUpHeartRateZones,
                subtitle: s.stepByStepGuidedSetup,
                trailing: _ChevronTrailing(),
                onTap: () => showHealthProfileOnboarding(context),
              ),
              // Zone Colour Bands
              _Set2Row(
                icon: Icons.palette_outlined,
                title: s.zoneColourBands,
                subtitle: s.zoneColourBandsSubtitle,
                trailing: _KineticToggle(
                  value: ref.watch(zoneBandsProvider),
                  onChanged: (_) =>
                      ref.read(zoneBandsProvider.notifier).toggle(),
                ),
              ),
            ]),

            const SizedBox(height: 22),

            // ── MAX HR ALERT ──────────────────────────────────────────────
            KineticSectionLabel(s.sectionMaxHrAlert),
            const SizedBox(height: 11),
            _Set2Card(children: [
              _Set2Row(
                icon: Icons.vibration,
                title: s.maxHrAlertVibration,
                subtitle: s.maxHrAlertVibrationSubtitle,
                trailing: _KineticToggle(
                  value: ref.watch(maxHrAlertProvider).vibrationEnabled,
                  onChanged: (_) =>
                      ref.read(maxHrAlertProvider.notifier).toggleVibration(),
                ),
              ),
              _Set2Row(
                icon: Icons.volume_up_outlined,
                title: s.maxHrAlertSound,
                subtitle: s.maxHrAlertSoundSubtitle,
                trailing: _KineticToggle(
                  value: ref.watch(maxHrAlertProvider).soundEnabled,
                  onChanged: (_) =>
                      ref.read(maxHrAlertProvider.notifier).toggleSound(),
                ),
              ),
              // Alert Cooldown — dropdown pill trailing
              _Set2Row(
                icon: Icons.timer_outlined,
                title: s.maxHrAlertCooldown,
                subtitle: s.maxHrAlertCooldownSubtitle,
                trailing: _DropdownPill<int>(
                  value: ref.watch(maxHrAlertProvider).cooldownSeconds,
                  items: const [10, 15, 30, 60],
                  labelBuilder: (v) => '${v}s',
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(maxHrAlertProvider.notifier).setCooldown(v);
                    }
                  },
                ),
              ),
            ]),

            // Disclaimer paragraph (faint, small) beneath Max HR Alert card
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
              child: Text(
                s.warningGeneralDisclaimer,
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  height: 1.5,
                  color: cs.outline,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── APPEARANCE ────────────────────────────────────────────────
            KineticSectionLabel(s.sectionAppearance),
            const SizedBox(height: 11),
            _Set2Card(children: [
              _Set2Row(
                icon: Icons.image_outlined,
                title: s.settingsShowExerciseImages,
                subtitle: s.settingsShowExerciseImagesSubtitle,
                trailing: _KineticToggle(
                  value: ref.watch(showExerciseImagesProvider),
                  onChanged: (_) =>
                      ref.read(showExerciseImagesProvider.notifier).toggle(),
                ),
              ),
              // Theme — compact segmented
              _Set2Row(
                icon: Icons.contrast,
                title: s.themeLabel,
                subtitle: null,
                trailing: _CompactSegmented<ThemeMode>(
                  selected: themeMode,
                  options: [
                    _SegOption(
                      value: ThemeMode.light,
                      icon: Icons.light_mode,
                      label: s.themeLight,
                    ),
                    _SegOption(
                      value: ThemeMode.dark,
                      icon: Icons.dark_mode,
                      label: s.themeDark,
                    ),
                    _SegOption(
                      value: ThemeMode.system,
                      icon: Icons.brightness_auto,
                      label: s.themeAuto,
                    ),
                  ],
                  onSelected: (v) =>
                      ref.read(themeModeProvider.notifier).set(v),
                ),
              ),
            ]),

            const SizedBox(height: 22),

            // ── UNITS ─────────────────────────────────────────────────────
            KineticSectionLabel(s.sectionUnits),
            const SizedBox(height: 11),
            _Set2Card(children: [
              _Set2Row(
                icon: Icons.scale_outlined,
                title: s.weightUnitLabel,
                subtitle: null,
                trailing: _CompactSegmented<String>(
                  selected: weightUnit,
                  options: [
                    _SegOption(value: 'kg', label: s.kgUnit),
                    _SegOption(value: 'lbs', label: s.lbsUnit),
                  ],
                  onSelected: (v) =>
                      ref.read(_weightUnitProvider.notifier).set(v),
                ),
              ),
            ]),

            const SizedBox(height: 22),

            // ── REST TIMER ────────────────────────────────────────────────
            KineticSectionLabel(s.sectionRestTimer),
            const SizedBox(height: 11),
            _Set2Card(children: [
              _Set2Row(
                icon: Icons.vibration,
                title: s.vibrationAlert,
                subtitle: s.vibrationAlertSubtitle,
                trailing: _KineticToggle(
                  value: ref.watch(restTimerSettingsProvider).vibrationEnabled,
                  onChanged: (_) => ref
                      .read(restTimerSettingsProvider.notifier)
                      .toggleVibration(),
                ),
              ),
              _Set2Row(
                icon: Icons.volume_up_outlined,
                title: s.soundAlert,
                subtitle: s.soundAlertSubtitle,
                trailing: _KineticToggle(
                  value: ref.watch(restTimerSettingsProvider).soundEnabled,
                  onChanged: (_) => ref
                      .read(restTimerSettingsProvider.notifier)
                      .toggleSound(),
                ),
              ),
            ]),

            const SizedBox(height: 22),

            // ── SYNC & REMINDERS ──────────────────────────────────────────
            KineticSectionLabel(s.sectionReminders),
            const SizedBox(height: 11),
            _SyncRemindersCard(s: s),

            const SizedBox(height: 22),

            // ── DATA ──────────────────────────────────────────────────────
            KineticSectionLabel(s.sectionData),
            const SizedBox(height: 11),
            _DataCard(s: s),

            const SizedBox(height: 22),

            // ── ABOUT ─────────────────────────────────────────────────────
            KineticSectionLabel(s.sectionAbout),
            const SizedBox(height: 11),
            _Set2Card(children: [
              _Set2Row(
                icon: Icons.info_outline,
                title: s.aboutAppName,
                subtitle: null,
                trailing: _ChevronTrailing(),
                onTap: () => context.push('/settings/about'),
              ),
            ]),

            const SizedBox(height: 28),

            // ── Footer wordmark ───────────────────────────────────────────
            _Footer(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

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

  // ─── Helper label methods ─────────────────────────────────────────────────

  String _methodLabel(ZoneMethod method, S s) {
    return switch (method) {
      ZoneMethod.custom => s.zoneMethodCustom,
      ZoneMethod.clinicianCap => s.zoneMethodClinicianCap,
      ZoneMethod.hrrKarvonen => s.zoneMethodHrr,
      ZoneMethod.lthrFriel => s.zoneMethodLthrFriel,
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
}

// ─── Pagehead ─────────────────────────────────────────────────────────────────

class _Pagehead extends StatelessWidget {
  const _Pagehead({required this.s});

  final S s;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow: "REPFOUNDRY V1.0"
          const KineticEyebrow('RepFoundry v1.0'),
          const SizedBox(height: 10),
          // Large display title
          Text(
            s.settingsTitle,
            style: KineticText.display(size: 32, letterSpacing: -0.8),
          ),
          const SizedBox(height: 8),
          // Dim subtitle — matches design spec; no ARB key exists for this string
          // (the original file also had this hardcoded).
          Text(
            'Fine-tune your performance experience.',
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings card container (.set2) ─────────────────────────────────────────

/// Rounded card that groups setting rows with 1 px hairline dividers.
/// Mirrors rf.css `.set2` — `surfaceContainerLow` background, radius 18.
class _Set2Card extends StatelessWidget {
  const _Set2Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _withDividers(children, cs),
      ),
    );
  }

  static List<Widget> _withDividers(List<Widget> rows, ColorScheme cs) {
    if (rows.isEmpty) return rows;
    final result = <Widget>[rows.first];
    for (int i = 1; i < rows.length; i++) {
      result.add(Divider(
        height: 1,
        thickness: 1,
        color: cs.outlineVariant,
        indent: 0,
        endIndent: 0,
      ));
      result.add(rows[i]);
    }
    return result;
  }
}

// ─── Individual settings row (.set2row) ───────────────────────────────────────

/// One row inside a [_Set2Card].
/// Mirrors rf.css `.set2row`: 21 px outline accent icon, Space Grotesk title,
/// dim subtitle, trailing control.
class _Set2Row extends StatelessWidget {
  const _Set2Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// When true, colours the icon and title with [ColorScheme.error].
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColour = danger ? cs.error : cs.primary;
    final titleColour = danger ? cs.error : cs.onSurface;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon — 21 px, accent or error colour
          SizedBox(
            width: 24,
            child: Icon(icon, size: 21, color: iconColour),
          ),
          const SizedBox(width: 14),
          // Title + optional subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: KineticText.display(
                    size: 14.5,
                    weight: FontWeight.w600,
                    letterSpacing: 0,
                    color: titleColour,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      height: 1.35,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

// ─── Trailing controls ────────────────────────────────────────────────────────

/// iOS-style toggle that reflects the Kinetic Green design (.toggle / .toggle--on).
/// Uses Flutter's [Switch] for accessibility; styled via the ambient theme.
class _KineticToggle extends StatelessWidget {
  const _KineticToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: cs.onPrimary,
      activeTrackColor: cs.primary,
      inactiveThumbColor: cs.onSurfaceVariant,
      inactiveTrackColor: cs.surfaceContainerHigh,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Faint chevron_right icon (.set2row__chev).
class _ChevronTrailing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      size: 20,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

/// Small × button to clear a value.
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        Icons.close,
        size: 20,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

/// Compact segmented control (.segsm). Accepts generic type for the selected value.
class _SegOption<T> {
  const _SegOption({required this.value, this.icon, required this.label});

  final T value;
  final IconData? icon;
  final String label;
}

class _CompactSegmented<T> extends StatelessWidget {
  const _CompactSegmented({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final T selected;
  final List<_SegOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final active = opt.value == selected;
          return GestureDetector(
            onTap: () => onSelected(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: active ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (opt.icon != null) ...[
                    Icon(
                      opt.icon,
                      size: 15,
                      color: active ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    opt.label,
                    style: KineticText.mono(
                      size: 12,
                      weight: FontWeight.w700,
                      color: active ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Dropdown pill (.ddpill) — a rounded chip that opens a Flutter DropdownButton.
class _DropdownPill<T> extends StatelessWidget {
  const _DropdownPill({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(Icons.expand_more, size: 16, color: cs.onSurfaceVariant),
        style: KineticText.mono(size: 12, color: cs.onSurface),
        dropdownColor: cs.surfaceContainerHigh,
        items: items
            .map((v) => DropdownMenuItem<T>(
                  value: v,
                  child: Text(labelBuilder(v)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Sync & Reminders card (combines Notifications + Health Sync + Cloud Sync) ─

/// Renders the "SYNC & REMINDERS" grouped card, incorporating
/// [_NotificationsTile], [_HealthSyncSection], and [_CloudSyncSection] rows.
class _SyncRemindersCard extends ConsumerWidget {
  const _SyncRemindersCard({required this.s});

  final S s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Notifications
    final reminderSettings = ref.watch(reminderSettingsProvider);
    final reminderSubtitle = _reminderSummary(context, s, reminderSettings);

    // Health sync
    final healthSettings = ref.watch(healthSyncSettingsProvider);

    // Cloud sync
    final syncSettings = ref.watch(syncSettingsProvider);
    final syncState = ref.watch(syncStateProvider);

    final List<Widget> rows = [
      // Notifications
      _Set2Row(
        icon: Icons.notifications_outlined,
        title: s.notificationsTileTitle,
        subtitle: reminderSubtitle,
        trailing: _ChevronTrailing(),
        onTap: () => context.push('/settings/notifications'),
      ),

      // Health Sync toggle
      _Set2Row(
        icon: Icons.favorite_outlined,
        title: s.healthSyncEnabled,
        subtitle: s.healthSyncSubtitle,
        trailing: _KineticToggle(
          value: healthSettings.enabled,
          onChanged: (_) async {
            if (!healthSettings.enabled) {
              final service = ref.read(healthSyncServiceProvider);
              final granted = await service.requestAuthorisation(
                writeWorkouts: healthSettings.writeWorkouts,
                writeWeight: healthSettings.writeWeight,
                writeHeartRate: healthSettings.writeHeartRate,
                readWeight: healthSettings.readWeight,
              );
              if (!granted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.healthSyncPermissionDenied)),
                );
                return;
              }
            }
            ref.read(healthSyncSettingsProvider.notifier).toggleEnabled();
          },
        ),
      ),

      // Expanded health sync sub-toggles (when enabled)
      if (healthSettings.enabled) ...[
        _Set2Row(
          icon: Icons.fitness_center,
          title: s.writeWorkoutsLabel,
          subtitle: s.writeWorkoutsSubtitle,
          trailing: _KineticToggle(
            value: healthSettings.writeWorkouts,
            onChanged: (_) => ref
                .read(healthSyncSettingsProvider.notifier)
                .toggleWriteWorkouts(),
          ),
        ),
        _Set2Row(
          icon: Icons.monitor_weight,
          title: s.writeWeightLabel,
          subtitle: s.writeWeightSubtitle,
          trailing: _KineticToggle(
            value: healthSettings.writeWeight,
            onChanged: (_) => ref
                .read(healthSyncSettingsProvider.notifier)
                .toggleWriteWeight(),
          ),
        ),
        _Set2Row(
          icon: Icons.monitor_heart,
          title: s.writeHeartRateLabel,
          subtitle: s.writeHeartRateSubtitle,
          trailing: _KineticToggle(
            value: healthSettings.writeHeartRate,
            onChanged: (_) => ref
                .read(healthSyncSettingsProvider.notifier)
                .toggleWriteHeartRate(),
          ),
        ),
        _Set2Row(
          icon: Icons.download,
          title: s.readWeightLabel,
          subtitle: s.readWeightSubtitle,
          trailing: _KineticToggle(
            value: healthSettings.readWeight,
            onChanged: (_) => ref
                .read(healthSyncSettingsProvider.notifier)
                .toggleReadWeight(),
          ),
        ),
      ],

      // Cross-Device Sync toggle
      _Set2Row(
        icon: Icons.sync,
        title: s.syncEnabled,
        subtitle: s.syncEnabledSubtitle,
        trailing: _KineticToggle(
          value: syncSettings.enabled,
          onChanged: (_) async {
            if (!syncSettings.enabled) {
              if (!syncSettings.consentGiven) {
                final accepted = await SyncConsentDialog.show(context);
                if (!accepted) return;
                await ref
                    .read(syncSettingsProvider.notifier)
                    .setConsentGiven(true);
              }
              if (!context.mounted) return;
              final result = await _runManualSync(context, ref);
              if (result) {
                await ref.read(syncSettingsProvider.notifier).setEnabled(true);
              }
            } else {
              await ref.read(syncSettingsProvider.notifier).setEnabled(false);
            }
          },
        ),
      ),

      // Expanded cloud-sync rows (when enabled)
      if (syncSettings.enabled) ...[
        _Set2Row(
          icon: Icons.access_time,
          title: syncSettings.lastSyncAt != null
              ? s.syncLastSynced(DateFormat.yMd()
                  .add_jm()
                  .format(syncSettings.lastSyncAt!.toLocal()))
              : s.syncNeverSynced,
          subtitle: null,
        ),
        _Set2Row(
          icon: Icons.cloud_sync_outlined,
          title: syncState.status == SyncStatus.syncing
              ? s.syncSyncing
              : s.syncNow,
          subtitle: null,
          trailing: syncState.status == SyncStatus.syncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: syncState.status == SyncStatus.syncing
              ? null
              : () => _runManualSync(context, ref),
        ),
        _Set2Row(
          icon: Icons.delete_outline,
          title: s.syncDisableAndDelete,
          subtitle: null,
          danger: true,
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.syncDisableConfirmTitle),
                content: Text(s.syncDisableConfirmBody),
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
                    child: Text(s.syncDisableConfirmAction),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref
                  .read(syncOrchestratorProvider)
                  .deleteCloudData(interactive: true);
              ref.read(syncSettingsProvider.notifier).disableAndClear();
              ref.read(syncStateProvider.notifier).setStatus(SyncStatus.idle);
            }
          },
        ),
      ],
    ];

    return _Set2Card(children: rows);
  }

  Future<bool> _runManualSync(BuildContext context, WidgetRef ref) async {
    ref.read(syncStateProvider.notifier).setStatus(SyncStatus.syncing);
    final result =
        await ref.read(syncOrchestratorProvider).sync(interactive: true);
    if (result.success) {
      ref.read(syncStateProvider.notifier).setStatus(
            SyncStatus.success,
            lastSyncAt: result.syncedAt,
          );
      await ref
          .read(syncSettingsProvider.notifier)
          .updateLastSyncAt(result.syncedAt);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.syncSuccess)),
        );
      }
      return true;
    }

    ref.read(syncStateProvider.notifier).setStatus(
          SyncStatus.error,
          error: result.errorMessage,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.syncError(result.errorMessage ?? ''))),
      );
    }
    return false;
  }

  String _reminderSummary(
    BuildContext context,
    S s,
    ReminderSettings settings,
  ) {
    if (!settings.hasReminders) {
      return s.notificationsTileSubtitleEmpty;
    }
    final dayLabels = <int, String>{
      DateTime.monday: s.mondayShort,
      DateTime.tuesday: s.tuesdayShort,
      DateTime.wednesday: s.wednesdayShort,
      DateTime.thursday: s.thursdayShort,
      DateTime.friday: s.fridayShort,
      DateTime.saturday: s.saturdayShort,
      DateTime.sunday: s.sundayShort,
    };
    final days = (settings.enabledDays.toList()..sort())
        .map((d) => dayLabels[d]!)
        .join(', ');
    final time = s.reminderTimeOfDay(
      settings.hour.toString().padLeft(2, '0'),
      settings.minute.toString().padLeft(2, '0'),
    );
    return s.notificationsTileSubtitleSummary(days, time);
  }
}

// ─── Data card ────────────────────────────────────────────────────────────────

/// Groups all DATA-section rows, including the export/import tiles and the
/// destructive "Clear All Data" row.
class _DataCard extends ConsumerWidget {
  const _DataCard({required this.s});

  final S s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);

    ref.listen<ExportState>(exportProvider, (_, state) {
      if (state.status == ExportStatus.completed) {
        final message = state.savedPath != null
            ? '${s.exportComplete} — ${state.savedPath}'
            : s.exportComplete;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        ref.read(exportProvider.notifier).reset();
      } else if (state.status == ExportStatus.failed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.exportFailed(state.error ?? ''))),
        );
        ref.read(exportProvider.notifier).reset();
      }
    });

    final exporting = exportState.status == ExportStatus.exporting;

    final Widget progressIndicator = const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    return _Set2Card(children: [
      _Set2Row(
        icon: Icons.calendar_month_outlined,
        title: s.programmesTitle,
        subtitle: s.noProgrammesYetSubtitle,
        trailing: _ChevronTrailing(),
        onTap: () => context.push('/programmes'),
      ),
      _Set2Row(
        icon: Icons.view_list_outlined,
        title: s.templatesTitle,
        subtitle: s.templatesSubtitle,
        trailing: _ChevronTrailing(),
        onTap: () => context.push('/templates'),
      ),
      _Set2Row(
        icon: Icons.monitor_weight_outlined,
        title: s.bodyMetricsTitle,
        subtitle: s.bodyMetricsSubtitle,
        trailing: _ChevronTrailing(),
        onTap: () => context.push('/body-metrics'),
      ),
      _Set2Row(
        icon: Icons.data_object_outlined,
        title: s.exportAsJson,
        subtitle: s.exportAsJsonSubtitle,
        trailing: exporting ? progressIndicator : _ChevronTrailing(),
        onTap: exporting
            ? null
            : () => ref.read(exportProvider.notifier).exportJson(),
      ),
      _Set2Row(
        icon: Icons.table_chart_outlined,
        title: s.exportAsCsv,
        subtitle: s.exportAsCsvSubtitle,
        trailing: exporting ? progressIndicator : _ChevronTrailing(),
        onTap: exporting
            ? null
            : () => ref.read(exportProvider.notifier).exportCsv(),
      ),
      _ImportRow(s: s),
      // Danger row — no trailing control, error colour
      _Set2Row(
        icon: Icons.delete_forever_outlined,
        title: s.clearAllData,
        subtitle: s.clearAllDataSubtitle,
        danger: true,
        onTap: () => _confirmClearData(context, s),
      ),
    ]);
  }

  Future<void> _confirmClearData(BuildContext context, S s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearAllDataConfirmTitle),
        content: Text(s.clearAllDataConfirmContent),
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

// ─── Import row (stateful — needs local _importing flag) ──────────────────────

class _ImportRow extends ConsumerStatefulWidget {
  const _ImportRow({required this.s});

  final S s;

  @override
  ConsumerState<_ImportRow> createState() => _ImportRowState();
}

class _ImportRowState extends ConsumerState<_ImportRow> {
  bool _importing = false;

  Future<void> _import() async {
    final s = widget.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.importDataTitle),
        content: Text(s.importDataConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.importDataButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);

    try {
      final json = await _pickJson();
      if (json != null) {
        final useCase = ref.read(importDataUseCaseProvider);
        final importResult = await useCase.importFromJson(json);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.importComplete(
                importResult.workoutsImported,
                importResult.setsImported,
                importResult.cardioSessionsImported,
              )),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.importFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<String?> _pickJson() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final s = widget.s;
        return AlertDialog(
          title: Text(s.importPasteJsonTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: s.importPasteJsonHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(s.importDataButton),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result?.isNotEmpty == true ? result : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return _Set2Row(
      icon: Icons.file_upload_outlined,
      title: s.importFromJson,
      subtitle: s.importFromJsonSubtitle,
      trailing: _importing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _ChevronTrailing(),
      onTap: _importing ? null : _import,
    );
  }
}

// ─── Footer wordmark ──────────────────────────────────────────────────────────

/// Ghosted "REPFOUNDRY" wordmark + mono caption.
/// Mirrors the design's footer: very low opacity Space Grotesk + dim mono.
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          Text(
            'REPFOUNDRY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: cs.onSurface.withValues(alpha: 0.16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'kinetic-green · made for lifters',
            style: KineticText.mono(
              size: 11,
              weight: FontWeight.w600,
              color: cs.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Removed sub-sections (inlined into cards above) ─────────────────────────
// _ExportJsonTile, _ExportCsvTile, _ImportJsonTile, _HealthSyncSection,
// _CloudSyncSection, _SectionHeader, _NotificationsTile — all consolidated
// into _Set2Card / _Set2Row / _SyncRemindersCard / _DataCard above.
