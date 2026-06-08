import 'package:flutter/widgets.dart';

import 'layout_mode.dart';

/// Responsive breakpoints for the "desktop power-layout" pattern.
///
/// The app is mobile-first: below [tablet] it keeps the bottom-nav phone
/// layouts unchanged. From [tablet] up the navigation becomes a side-rail and
/// screens may reflow into two-pane "power layouts" (master-detail, dashboard
/// grid, library + canvas). See the docs site for the full pattern.
class Breakpoints {
  Breakpoints._();

  /// Width at or above which the side-rail appears (tablet and up).
  static const double tablet = 600;

  /// Width at or above which full desktop two-pane power-layouts are used.
  static const double desktop = 1024;

  /// Width of the labeled desktop navigation rail (`.dnav` in the design).
  static const double navRailWidth = 252;
}

/// Convenience width queries on [BuildContext].
///
/// [hasNavRail] and [isWide] honour the user's [LayoutMode] override, but only
/// from [Breakpoints.tablet] up — phone widths always use the mobile layout so
/// the desktop chrome can never be forced onto a too-small screen.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  LayoutMode get layoutMode => LayoutModeScope.of(this);

  /// Raw width buckets (ignore the override) — handy for fine-grained tuning.
  bool get isMobile => screenWidth < Breakpoints.tablet;
  bool get isTablet =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// True when the side-rail replaces the bottom nav. Honours the override on
  /// tablet+ widths; phones always return false.
  bool get hasNavRail {
    if (screenWidth < Breakpoints.tablet) return false;
    switch (layoutMode) {
      case LayoutMode.mobile:
        return false;
      case LayoutMode.desktop:
      case LayoutMode.auto:
        return true;
    }
  }

  /// True when bespoke two-pane power layouts apply. Honours the override on
  /// tablet+ widths; phones always return false.
  bool get isWide {
    if (screenWidth < Breakpoints.tablet) return false;
    switch (layoutMode) {
      case LayoutMode.mobile:
        return false;
      case LayoutMode.desktop:
        return true;
      case LayoutMode.auto:
        return screenWidth >= Breakpoints.desktop;
    }
  }
}
