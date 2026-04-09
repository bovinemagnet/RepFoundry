import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  static const _navBarHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page content with bottom padding for the nav bar.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: _navBarHeight),
              child: child,
            ),
          ),
          // Glassmorphism navigation bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _GlassNavBar(
              selectedIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onDestinationSelected(index, context),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/workout')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/cardio')) return 2;
    if (location.startsWith('/heart-rate')) return 3;
    return 4;
  }

  void _onDestinationSelected(int index, BuildContext context) {
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
      (Icons.history, s.navHistory),
      (Icons.directions_run, s.navCardio),
      (Icons.monitor_heart, s.navHeartRate),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    isSelected: i == selectedIndex,
                    onTap: () => onTap(i),
                    colorScheme: cs,
                    textTheme: tt,
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
    final inactiveColor = colorScheme.primaryContainer.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
    );
  }
}
