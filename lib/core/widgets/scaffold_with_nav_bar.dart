import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../responsive/breakpoints.dart';
import 'desktop_nav_rail.dart';

/// Adaptive navigation shell.
///
/// - **Mobile** (`< 600`): the existing glass bottom navigation bar, shown only
///   for the five core tabs (Workout, History, Cardio, Heart Rate, Settings).
///   Deeper routes that the shell also wraps (Analytics, Templates, Programmes)
///   keep their original full-screen presentation with no bottom nav.
/// - **Tablet / Desktop** (`>= 600`): a persistent labeled [DesktopNavRail] on
///   the left with the page content beside it. Screens that provide a bespoke
///   two-pane "power layout" fill the pane; the rest are centred at a readable
///   maximum width rather than stretched.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  static const _navBarHeight = 72.0;

  /// Maximum content width for screens without a bespoke desktop layout, so a
  /// phone-shaped screen reads as a centred column rather than stretched.
  static const _centredMaxWidth = 980.0;

  /// Route prefixes that show the bottom nav on mobile (the five core tabs).
  static const _coreTabPrefixes = [
    '/workout',
    '/history',
    '/cardio',
    '/heart-rate',
    '/settings',
  ];

  /// Route prefixes with a bespoke full-width desktop two-pane layout.
  static const _fullWidthDesktopPrefixes = [
    '/history',
    '/analytics',
    '/templates',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (context.hasNavRail) {
      return _buildWithRail(context, location);
    }
    return _buildWithBottomNav(context, location);
  }

  // ── Desktop / tablet: side-rail + content pane ──────────────────────────

  Widget _buildWithRail(BuildContext context, String location) {
    final fullWidth =
        _fullWidthDesktopPrefixes.any((p) => location.startsWith(p));

    final content = fullWidth
        ? child
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _centredMaxWidth),
              child: child,
            ),
          );

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            DesktopNavRail(
              selectedIndex: _railIndexForLocation(location),
              onDestinationSelected: (index) =>
                  _onRailDestinationSelected(index, context),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  // ── Mobile: glass bottom navigation ─────────────────────────────────────

  Widget _buildWithBottomNav(BuildContext context, String location) {
    final showBottomNav = _coreTabPrefixes.any((p) => location.startsWith(p));

    final Widget inner;
    if (!showBottomNav) {
      // Deeper routes wrapped by the shell (templates/programmes/analytics)
      // keep their original full-screen presentation on mobile.
      inner = child;
    } else {
      inner = Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: _navBarHeight),
                child: child,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _GlassNavBar(
                selectedIndex: _bottomNavIndex(location),
                onTap: (index) => _onBottomNavSelected(index, context),
              ),
            ),
          ],
        ),
      );
    }

    // When the mobile layout is forced onto a wide screen (LayoutMode.mobile),
    // present it as a centred phone-width column rather than stretching it.
    if (context.screenWidth >= Breakpoints.tablet) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: SizedBox(width: Breakpoints.tablet, child: inner),
        ),
      );
    }
    return inner;
  }

  // ── Index helpers ───────────────────────────────────────────────────────

  /// Bottom-nav (mobile) index across the five core tabs.
  int _bottomNavIndex(String location) {
    if (location.startsWith('/workout')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/cardio')) return 2;
    if (location.startsWith('/heart-rate')) return 3;
    return 4;
  }

  void _onBottomNavSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/workout');
      case 1:
        context.go('/history');
      case 2:
        context.go('/cardio');
      case 3:
        context.go('/heart-rate');
      case 4:
        context.go('/settings');
    }
  }

  /// Rail (desktop) flat index across all eight destinations.
  /// Order: Workout, Cardio, History, Analytics, Heart Rate, Templates,
  /// Programmes, Settings.
  int _railIndexForLocation(String location) {
    if (location.startsWith('/workout')) return 0;
    if (location.startsWith('/cardio')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/heart-rate')) return 4;
    if (location.startsWith('/templates')) return 5;
    if (location.startsWith('/programmes')) return 6;
    return 7; // settings
  }

  void _onRailDestinationSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/workout');
      case 1:
        context.go('/cardio');
      case 2:
        context.go('/history');
      case 3:
        context.go('/analytics');
      case 4:
        context.go('/heart-rate');
      case 5:
        context.go('/templates');
      case 6:
        context.go('/programmes');
      case 7:
        context.go('/settings');
    }
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final items = [
      (Icons.fitness_center, s.navWorkout),
      (Icons.bar_chart, s.navHistory),
      (Icons.directions_run, s.navCardio),
      (Icons.favorite, s.navHeartRate),
      (Icons.settings, s.navSettings),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: cs.surfaceBright.withValues(alpha: 0.6),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SizedBox(
            height: ScaffoldWithNavBar._navBarHeight,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: items[i].$1,
                      label: items[i].$2,
                      isSelected: i == selectedIndex,
                      onTap: () => onTap(i),
                      colorScheme: cs,
                      textTheme: tt,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
