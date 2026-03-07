import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/warning_messages.dart';

const _disclaimerShownKey = 'hr_disclaimer_shown';

/// Shows the first-use disclaimer dialog if it hasn't been shown before.
///
/// Returns `true` if the disclaimer was shown (and acknowledged), `false` if
/// it had already been shown previously.
Future<bool> showDisclaimerIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_disclaimerShownKey) == true) return false;

  if (!context.mounted) return false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Heart Rate Monitoring'),
      content: const SingleChildScrollView(
        child: Text(WarningMessages.generalDisclaimer),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('I understand'),
        ),
      ],
    ),
  );

  await prefs.setBool(_disclaimerShownKey, true);
  return true;
}
