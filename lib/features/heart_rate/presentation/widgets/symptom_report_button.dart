import 'package:flutter/material.dart';

import '../../domain/analytics_events.dart';
import '../../domain/warning_messages.dart';

/// Button shown during active monitoring to report symptoms.
class SymptomReportButton extends StatelessWidget {
  const SymptomReportButton({
    super.key,
    required this.onStopRequested,
    this.analytics,
  });

  /// Called when the user reports a symptom and exercise should stop.
  final VoidCallback onStopRequested;

  /// Optional analytics reporter for tracking warning events.
  final HrAnalyticsReporter? analytics;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      onPressed: () => _showSymptomDialog(context),
      icon: const Icon(Icons.warning_amber_rounded),
      label: const Text('Report Symptom'),
    );
  }

  void _showSymptomDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Symptom Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(WarningMessages.symptomListIntro),
            const SizedBox(height: 12),
            for (final symptom in WarningMessages.symptomOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error,
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showStopExerciseDialog(context, symptom);
                  },
                  child: Text(symptom),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showStopExerciseDialog(BuildContext context, String symptom) {
    onStopRequested();
    analytics?.trackEvent(HrAnalyticsEvent.warningDisplayed, {
      'type': 'symptom_report',
      'symptom': symptom,
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.emergency,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: const Text('Stop Exercise'),
        content: const Text(WarningMessages.stopExercisePrompt),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("I'm OK, stopping exercise"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I need help'),
          ),
        ],
      ),
    );
  }
}
