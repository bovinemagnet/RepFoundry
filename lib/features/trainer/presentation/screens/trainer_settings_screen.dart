import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../providers/coach_bridge.dart';
import '../providers/trainer_settings_provider.dart';
import '../widgets/trainer_disclaimer_sheet.dart';

class TrainerSettingsScreen extends ConsumerWidget {
  const TrainerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ListTile(
            title: Text(s.trainerPersona),
            subtitle: Text(
              '${s.trainerPersonaSteady} — ${s.trainerPersonaSteadyDescription}'
              '\n${s.trainerMoreVoicesComing}',
            ),
          ),
          ListTile(
            title: Text(s.trainerSpeechRate),
            subtitle: Slider(
              value: settings.speechRate,
              min: 0.25,
              max: 1.0,
              divisions: 15,
              onChanged: (value) => notifier.setSpeechRate(value),
            ),
            trailing: TextButton(
              onPressed: () =>
                  ref.read(speechServiceProvider).speak(s.trainerTestPhrase),
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
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.trainerReviewDisclaimer),
            onTap: () async {
              // Explicitly declining after having previously accepted
              // withdraws consent, so revoking is reachable from the UI
              // rather than only ever being set to true.
              final accepted = await showTrainerDisclaimer(context);
              if (accepted == false) {
                await notifier.revokeDisclaimer();
              }
            },
          ),
        ],
      ),
    );
  }
}
