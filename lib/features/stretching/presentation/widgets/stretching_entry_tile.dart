import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../domain/models/stretching_session.dart';
import 'stretch_preset_localiser.dart';

class StretchingEntryTile extends StatelessWidget {
  const StretchingEntryTile({
    super.key,
    required this.session,
    this.onDelete,
  });

  final StretchingSession session;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            session.entryMethod == StretchingEntryMethod.timer
                ? Icons.timer_outlined
                : Icons.edit_note,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localiseStretch(
                    s,
                    session.type,
                    customName: session.customName,
                  ),
                  style: tt.bodyMedium,
                ),
                if (session.notes != null && session.notes!.isNotEmpty)
                  Text(
                    session.notes!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatStretchDuration(session.durationSeconds),
            style: tt.titleSmall?.copyWith(fontFeatures: const [
              FontFeature.tabularFigures(),
            ]),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: s.delete,
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
