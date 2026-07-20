import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/app_scroll_behavior.dart';

void main() {
  test('lists are draggable with mouse, trackpad, stylus, and touch', () {
    const behaviour = AppScrollBehavior();
    expect(
      behaviour.dragDevices,
      containsAll(<PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      }),
    );
  });
}
