import 'dart:ui';

import 'package:flutter/material.dart';

/// Desktop-friendly scrolling: lists can be dragged with a mouse or trackpad
/// as well as touch. The inherited [MaterialScrollBehavior] keeps the default
/// automatic scrollbars on desktop platforms.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
