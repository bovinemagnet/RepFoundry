import 'package:flutter/material.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Shows the safety notice. Resolves true only when the user accepts.
Future<bool?> showTrainerDisclaimer(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final s = S.of(context)!;
      // SingleChildScrollView so a long body at a large text scale on a
      // short viewport scrolls rather than pushing the accept/decline
      // buttons off-screen — this sheet is the one gate the whole feature
      // depends on, so it must stay reachable at any size.
      return Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.trainerDisclaimerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(s.trainerDisclaimerBody),
              const SizedBox(height: 24),
              // Stacked rather than side by side: at 411dp a two-button row
              // squeezes these labels onto three lines each.
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(s.trainerDisclaimerAccept),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.trainerDisclaimerDecline),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
