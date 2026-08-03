import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainerSettings {
  const TrainerSettings({
    this.enabled = false,
    this.countdownsEnabled = true,
    this.encouragementEnabled = true,
    this.speechRate = 0.5,
    this.disclaimerAccepted = false,
    this.personaId = 'steady',
    this.hrCalloutsEnabled = true,
    this.hrSafetyWarningsEnabled = true,
  });

  final bool enabled;
  final bool countdownsEnabled;
  final bool encouragementEnabled;
  final double speechRate;
  final bool disclaimerAccepted;
  final String personaId;

  /// Whether the coach announces heart-rate zone changes.
  final bool hrCalloutsEnabled;

  /// Whether the coach speaks above/below-cap safety cues. Defaults to
  /// true and is presented in settings as the one to leave switched on —
  /// but, as the user's own choice, it must remain switchable off.
  final bool hrSafetyWarningsEnabled;

  TrainerSettings copyWith({
    bool? enabled,
    bool? countdownsEnabled,
    bool? encouragementEnabled,
    double? speechRate,
    bool? disclaimerAccepted,
    String? personaId,
    bool? hrCalloutsEnabled,
    bool? hrSafetyWarningsEnabled,
  }) {
    return TrainerSettings(
      enabled: enabled ?? this.enabled,
      countdownsEnabled: countdownsEnabled ?? this.countdownsEnabled,
      encouragementEnabled: encouragementEnabled ?? this.encouragementEnabled,
      speechRate: speechRate ?? this.speechRate,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      personaId: personaId ?? this.personaId,
      hrCalloutsEnabled: hrCalloutsEnabled ?? this.hrCalloutsEnabled,
      hrSafetyWarningsEnabled:
          hrSafetyWarningsEnabled ?? this.hrSafetyWarningsEnabled,
    );
  }
}

class TrainerSettingsNotifier extends Notifier<TrainerSettings> {
  /// Every mutator awaits this before touching `state`, so a write landing
  /// before the initial `SharedPreferences` load resolves is never clobbered
  /// by that load completing afterwards. Mirrors the same guard in
  /// `UnlockedEntitlementsNotifier`.
  Future<void>? _loading;

  @override
  TrainerSettings build() {
    _loading = _load();
    return const TrainerSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = TrainerSettings(
      enabled: prefs.getBool('trainer_enabled') ?? false,
      countdownsEnabled: prefs.getBool('trainer_countdowns') ?? true,
      encouragementEnabled: prefs.getBool('trainer_encouragement') ?? true,
      speechRate: prefs.getDouble('trainer_speech_rate') ?? 0.5,
      disclaimerAccepted: prefs.getBool('trainer_disclaimer_accepted') ?? false,
      personaId: prefs.getString('trainer_persona') ?? 'steady',
      hrCalloutsEnabled: prefs.getBool('trainer_hr_callouts') ?? true,
      hrSafetyWarningsEnabled: prefs.getBool('trainer_hr_safety') ?? true,
    );
  }

  /// Enabling is refused until the safety notice has been accepted, so the
  /// gate cannot be bypassed by toggling the switch.
  Future<void> setEnabled(bool value) async {
    await _loading;
    if (value && !state.disclaimerAccepted) return;
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_enabled', value);
  }

  Future<void> setCountdowns(bool value) async {
    await _loading;
    state = state.copyWith(countdownsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_countdowns', value);
  }

  Future<void> setEncouragement(bool value) async {
    await _loading;
    state = state.copyWith(encouragementEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_encouragement', value);
  }

  Future<void> setPersona(String value) async {
    await _loading;
    state = state.copyWith(personaId: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trainer_persona', value);
  }

  Future<void> setHrCallouts(bool value) async {
    await _loading;
    state = state.copyWith(hrCalloutsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_hr_callouts', value);
  }

  Future<void> setHrSafetyWarnings(bool value) async {
    await _loading;
    state = state.copyWith(hrSafetyWarningsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_hr_safety', value);
  }

  Future<void> setSpeechRate(double value) async {
    await _loading;
    state = state.copyWith(speechRate: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('trainer_speech_rate', value);
  }

  Future<void> acceptDisclaimer() async {
    await _loading;
    state = state.copyWith(disclaimerAccepted: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_disclaimer_accepted', true);
  }

  /// Revoking also silences the coach: consent and speech move together.
  Future<void> revokeDisclaimer() async {
    await _loading;
    state = state.copyWith(disclaimerAccepted: false, enabled: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_disclaimer_accepted', false);
    await prefs.setBool('trainer_enabled', false);
  }
}

final trainerSettingsProvider =
    NotifierProvider<TrainerSettingsNotifier, TrainerSettings>(
  TrainerSettingsNotifier.new,
);
