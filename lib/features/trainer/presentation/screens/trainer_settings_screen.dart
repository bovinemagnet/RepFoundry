import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../data/persona_packs.dart';
import '../providers/coach_bridge.dart';
import '../providers/trainer_settings_provider.dart';
import '../widgets/trainer_disclaimer_sheet.dart';

class TrainerSettingsScreen extends ConsumerStatefulWidget {
  const TrainerSettingsScreen({super.key});

  @override
  ConsumerState<TrainerSettingsScreen> createState() =>
      _TrainerSettingsScreenState();
}

class _TrainerSettingsScreenState extends ConsumerState<TrainerSettingsScreen> {
  /// The rate being dragged right now. Held locally so the slider tracks the
  /// thumb without persisting — and so recreating the TTS engine — on every
  /// one of the drag's many intermediate values.
  double? _draggingRate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final settings = ref.watch(trainerSettingsProvider);
    final notifier = ref.read(trainerSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.trainerSettingsTitle)),
      body: ListView(
        children: [
          FutureBuilder<bool>(
            future: ref.read(speechServiceProvider).isAvailable(),
            builder: (context, snapshot) {
              if (snapshot.data == false) {
                return ListTile(
                  leading: const Icon(Icons.volume_off),
                  title: Text(s.trainerVoiceUnavailable),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SwitchListTile(
            title: Text(s.trainerEnable),
            subtitle: Text(s.trainerEnableSubtitle),
            value: settings.enabled,
            onChanged: (value) async {
              // Enabling without consent shows the notice instead; the notifier
              // refuses the change either way, so the gate cannot be skipped.
              if (value && !settings.disclaimerAccepted) {
                final accepted = await showTrainerDisclaimer(context);
                if (accepted != true) return;
                await notifier.acceptDisclaimer();
              }
              await notifier.setEnabled(value);
            },
          ),
          ListTile(title: Text(s.trainerPersona)),
          RadioGroup<String>(
            groupValue: settings.personaId,
            onChanged: (value) async {
              if (value != null) await notifier.setPersona(value);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(s.trainerPersonaSteady),
                  subtitle: Text(s.trainerPersonaSteadyDescription),
                  value: steadyPersona.id,
                ),
                RadioListTile<String>(
                  title: Text(s.trainerPersonaHype),
                  subtitle: Text(s.trainerPersonaHypeDescription),
                  value: hypePersona.id,
                ),
                RadioListTile<String>(
                  title: Text(s.trainerPersonaSergeant),
                  subtitle: Text(s.trainerPersonaSergeantDescription),
                  value: sergeantPersona.id,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(s.trainerSpeechRate),
            subtitle: Slider(
              value: _draggingRate ?? settings.speechRate,
              min: 0.25,
              max: 1.0,
              divisions: 15,
              // Persisting on every intermediate value would write to
              // preferences and tear down and rebuild the TTS engine up to
              // sixteen times per drag, each teardown calling stop() and so
              // cutting the coach off mid-sentence. The drag stays visually
              // live; only the final value is committed.
              onChanged: (value) => setState(() => _draggingRate = value),
              onChangeEnd: (value) async {
                await notifier.setSpeechRate(value);
                if (mounted) setState(() => _draggingRate = null);
              },
            ),
            trailing: TextButton(
              onPressed: () => _testVoice(context, settings, notifier, s),
              child: Text(s.trainerTestVoice),
            ),
          ),
          SwitchListTile(
            title: Text(s.trainerCountdowns),
            value: settings.countdownsEnabled,
            onChanged: notifier.setCountdowns,
          ),
          SwitchListTile(
            title: Text(s.trainerEncouragement),
            value: settings.encouragementEnabled,
            onChanged: notifier.setEncouragement,
          ),
          SwitchListTile(
            title: Text(s.trainerHrCallouts),
            subtitle: Text(s.trainerHrCalloutsSubtitle),
            value: settings.hrCalloutsEnabled,
            onChanged: notifier.setHrCallouts,
          ),
          // Listed last among the toggles and with copy explaining why: this
          // is the one setting the user should leave alone, but — as their
          // own choice — it must remain switchable off like every other cue.
          SwitchListTile(
            title: Text(s.trainerHrSafetyWarnings),
            subtitle: Text(s.trainerHrSafetyWarningsSubtitle),
            value: settings.hrSafetyWarningsEnabled,
            onChanged: notifier.setHrSafetyWarnings,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.trainerReviewDisclaimer),
            // Read-only: opened to re-read the notice, so neither button may
            // change any setting. "Not now" here must behave like closing
            // the sheet, not like withdrawing consent — that is a separate,
            // deliberate action below with its own confirmation.
            onTap: () => showTrainerDisclaimer(context),
          ),
          if (settings.disclaimerAccepted)
            ListTile(
              leading: Icon(
                Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                s.trainerWithdrawConsent,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _confirmWithdraw(context, notifier, s),
            ),
        ],
      ),
    );
  }

  /// Consent must precede speech, here as everywhere else: the test phrase is
  /// still the coach's voice, so an entitled user who has never seen the
  /// safety notice must see it first and accept it before the device speaks.
  Future<void> _testVoice(
    BuildContext context,
    TrainerSettings settings,
    TrainerSettingsNotifier notifier,
    S s,
  ) async {
    if (!settings.disclaimerAccepted) {
      final accepted = await showTrainerDisclaimer(context);
      if (accepted != true) return;
      await notifier.acceptDisclaimer();
    }
    await ref.read(speechServiceProvider).speak(s.trainerTestPhrase);
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    TrainerSettingsNotifier notifier,
    S s,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.trainerWithdrawConsentConfirmTitle),
        content: Text(s.trainerWithdrawConsentConfirmContent),
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
            child: Text(s.trainerWithdrawConsentAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.revokeDisclaimer();
    }
  }
}
