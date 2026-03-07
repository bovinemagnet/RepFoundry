import 'package:flutter/material.dart';

import '../../domain/zone_calculator.dart';

/// Shows the reliability level of the current zone configuration.
class ReliabilityIndicator extends StatelessWidget {
  const ReliabilityIndicator({super.key, required this.config});

  final ZoneConfiguration config;

  @override
  Widget build(BuildContext context) {
    final (colour, icon, label) = switch (config.reliability) {
      ZoneReliability.high => (Colors.green, Icons.verified, 'High'),
      ZoneReliability.medium => (Colors.amber, Icons.info_outline, 'Medium'),
      ZoneReliability.low => (Colors.red, Icons.warning_outlined, 'Low'),
    };

    return Tooltip(
      message: config.reason,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colour),
          const SizedBox(width: 4),
          Text(
            '$label confidence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colour,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
