import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Makes all descendant text selectable on desktop platforms, where users
/// expect to be able to copy stats, notes, and error messages. Mobile keeps
/// the default non-selectable text so gestures are unaffected.
class DesktopTextSelection extends StatelessWidget {
  const DesktopTextSelection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return SelectionArea(child: child);
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return child;
    }
  }
}
