import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'kinetic.dart';

/// The page bar at the top of a desktop power-layout (`.dtop` in the design):
/// an eyebrow + title/subtitle on the left and contextual actions on the right.
///
/// Sits above the two-pane body inside the content pane (the nav rail is the
/// shell). Use it instead of a Material [AppBar] on desktop screens.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  KineticEyebrow(eyebrow!),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: KineticText.display(
                    size: 28,
                    weight: FontWeight.w700,
                    letterSpacing: -0.7,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  actions[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
