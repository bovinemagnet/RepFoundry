import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/analytics_events.dart';

const _disclaimerShownKey = 'hr_disclaimer_shown';

/// Shows the first-use disclaimer dialog if it hasn't been shown before.
///
/// Returns `true` if the disclaimer was shown (and acknowledged), `false` if
/// it had already been shown previously.
Future<bool> showDisclaimerIfNeeded(
  BuildContext context, {
  HrAnalyticsReporter? analytics,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_disclaimerShownKey) == true) return false;

  if (!context.mounted) return false;

  final s = S.of(context)!;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(s.disclaimerDialogTitle),
      content: SingleChildScrollView(
        child: Text(s.warningGeneralDisclaimer),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.disclaimerDialogButton),
        ),
      ],
    ),
  );

  await prefs.setBool(_disclaimerShownKey, true);
  analytics?.trackEvent(HrAnalyticsEvent.warningDisplayed, {
    'type': 'disclaimer',
  });
  return true;
}
