import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../domain/models/health_profile.dart';

/// Amber caution badge shown when the user has medical flags.
class CautionBadge extends StatelessWidget {
  const CautionBadge({super.key, required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    if (!profile.isCautionMode) return const SizedBox.shrink();

    final s = S.of(context)!;
    final String message;
    if (profile.takingBetaBlocker && profile.hasHeartCondition) {
      message = '${s.warningBetaBlocker}\n\n'
          '${s.warningHeartCondition}';
    } else if (profile.takingBetaBlocker) {
      message = s.warningBetaBlocker;
    } else {
      message = s.warningHeartCondition;
    }

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.cautionModeTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
