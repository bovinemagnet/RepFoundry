import 'package:flutter/widgets.dart';

/// User preference for which responsive layout to present.
///
/// The override is **tablet-and-up only** — on phone widths (`< 600`) the app
/// always uses the mobile layout regardless of this value. See
/// `ResponsiveContext` in `breakpoints.dart` for how it is applied.
enum LayoutMode {
  /// Pick the layout from the window width (the default behaviour).
  auto,

  /// Force the mobile experience (bottom nav, single-pane) on tablet+ widths.
  mobile,

  /// Force the desktop experience (side-rail, two-pane power layouts) on
  /// tablet+ widths.
  desktop,
}

/// Propagates the active [LayoutMode] down the tree so the width-based
/// breakpoint helpers can consult it. Installed near the app root (see
/// `RepFoundryApp`); absent in isolated widget tests, where it defaults to
/// [LayoutMode.auto].
class LayoutModeScope extends InheritedWidget {
  const LayoutModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  final LayoutMode mode;

  static LayoutMode? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LayoutModeScope>()?.mode;
  }

  static LayoutMode of(BuildContext context) {
    return maybeOf(context) ?? LayoutMode.auto;
  }

  @override
  bool updateShouldNotify(LayoutModeScope oldWidget) => mode != oldWidget.mode;
}
