import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/core/widgets/rep_foundry_app_icon.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import 'kinetic.dart';

/// A single destination in the desktop navigation rail.
class RailDestination {
  const RailDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// A named group of destinations in the rail (e.g. "Train", "Review").
class RailGroup {
  const RailGroup({required this.heading, required this.destinations});

  final String heading;
  final List<RailDestination> destinations;
}

/// Persistent labeled side navigation for desktop/tablet widths — the
/// "desktop power-layout" shell. Mirrors the design's `.dnav` (252px): a logo
/// header, intent-grouped destinations (Train / Review / Plan), and Settings
/// pinned to the bottom. The active item uses an accent-soft background with
/// accent text and a filled icon.
///
/// Destinations are addressed by a flat index spanning all groups plus the
/// trailing Settings entry, so it composes with a simple `int selectedIndex`.
class DesktopNavRail extends StatelessWidget {
  const DesktopNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  /// Flat index across all grouped destinations followed by Settings (last).
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final groups = [
      RailGroup(
        heading: s.navGroupTrain,
        destinations: [
          RailDestination(
            label: s.navWorkout,
            icon: Icons.fitness_center,
            activeIcon: Icons.fitness_center,
          ),
          RailDestination(
            label: s.navCardio,
            icon: Icons.directions_run,
            activeIcon: Icons.directions_run,
          ),
        ],
      ),
      RailGroup(
        heading: s.navGroupReview,
        destinations: [
          RailDestination(
            label: s.navHistory,
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
          ),
          RailDestination(
            label: s.analyticsTitle,
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights,
          ),
          RailDestination(
            label: s.navHeartRate,
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
          ),
        ],
      ),
      RailGroup(
        heading: s.navGroupPlan,
        destinations: [
          RailDestination(
            label: s.templatesTitle,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
          ),
          RailDestination(
            label: s.programmesTitle,
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
          ),
        ],
      ),
    ];

    // Index of the trailing Settings entry = total grouped destinations.
    final settingsIndex =
        groups.fold<int>(0, (sum, g) => sum + g.destinations.length);

    // Build the grouped items, tracking the running flat index.
    final children = <Widget>[];
    var flatIndex = 0;
    for (final group in groups) {
      children.add(_GroupHeading(group.heading));
      for (final dest in group.destinations) {
        final i = flatIndex;
        children.add(_RailItem(
          destination: dest,
          selected: i == selectedIndex,
          onTap: () => onDestinationSelected(i),
        ));
        flatIndex++;
      }
      children.add(const SizedBox(height: 18));
    }

    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: cs.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RailHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              children: children,
            ),
          ),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: _RailItem(
              destination: RailDestination(
                label: s.navSettings,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
              ),
              selected: selectedIndex == settingsIndex,
              onTap: () => onDestinationSelected(settingsIndex),
            ),
          ),
          const _RailFooter(),
        ],
      ),
    );
  }
}

/// Logo + wordmark header at the top of the rail.
class _RailHeader extends StatelessWidget {
  const _RailHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Row(
        children: [
          const RepFoundryAppIcon(size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              TextSpan(
                style: KineticText.display(
                  size: 18,
                  letterSpacing: -0.2,
                  color: cs.onSurface,
                ),
                children: [
                  const TextSpan(text: 'Rep'),
                  TextSpan(
                      text: 'Foundry', style: TextStyle(color: cs.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase mono group heading (e.g. "TRAIN").
class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: KineticText.mono(
          size: 10,
          weight: FontWeight.w700,
          letterSpacing: 1.8,
          color: cs.outline,
        ),
      ),
    );
  }
}

/// A single tappable rail destination row.
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final RailDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.primary : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color:
            selected ? cs.primary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? destination.activeIcon : destination.icon,
                  size: 20,
                  color: fg,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative footer beneath the rail — offline-first reassurance line.
class _RailFooter extends StatelessWidget {
  const _RailFooter();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
      child: Text(
        'KINETIC-GREEN · OFFLINE-FIRST',
        style: KineticText.mono(
          size: 8.5,
          weight: FontWeight.w600,
          letterSpacing: 1.0,
          color: cs.outline,
        ),
      ),
    );
  }
}
