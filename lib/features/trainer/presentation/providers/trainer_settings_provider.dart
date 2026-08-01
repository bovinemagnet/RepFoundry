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
  });

  final bool enabled;
  final bool countdownsEnabled;
  final bool encouragementEnabled;
  final double speechRate;
  final bool disclaimerAccepted;
  final String personaId;

  TrainerSettings copyWith({
    bool? enabled,
    bool? countdownsEnabled,
    bool? encouragementEnabled,
    double? speechRate,
    bool? disclaimerAccepted,
    String? personaId,
  }) {
    return TrainerSettings(
      enabled: enabled ?? this.enabled,
      countdownsEnabled: countdownsEnabled ?? this.countdownsEnabled,
      encouragementEnabled: encouragementEnabled ?? this.encouragementEnabled,
      speechRate: speechRate ?? this.speechRate,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      personaId: personaId ?? this.personaId,
    );
  }
}

class TrainerSettingsNotifier extends Notifier<TrainerSettings> {
  @override
  TrainerSettings build() {
    Future.microtask(_load);
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
    );
  }

  /// Enabling is refused until the safety notice has been accepted, so the
  /// gate cannot be bypassed by toggling the switch.
  Future<void> setEnabled(bool value) async {
    if (value && !state.disclaimerAccepted) return;
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_enabled', value);
  }

  Future<void> setCountdowns(bool value) async {
    state = state.copyWith(countdownsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_countdowns', value);
  }

  Future<void> setEncouragement(bool value) async {
    state = state.copyWith(encouragementEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_encouragement', value);
  }

  Future<void> setSpeechRate(double value) async {
    state = state.copyWith(speechRate: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('trainer_speech_rate', value);
  }

  Future<void> acceptDisclaimer() async {
    state = state.copyWith(disclaimerAccepted: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_disclaimer_accepted', true);
  }

  /// Revoking also silences the coach: consent and speech move together.
  Future<void> revokeDisclaimer() async {
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
