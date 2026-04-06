import 'package:flutter/material.dart';

/// An editorial-style date section header with uppercase tracking label
/// and a thin separator line extending to the right.
class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: cs.primary.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
