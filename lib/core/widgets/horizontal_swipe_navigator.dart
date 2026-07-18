import 'package:flutter/material.dart';

/// Detects horizontal fling gestures over [child] and invokes the matching
/// callback, so two screens can offer a swipe shortcut to one another
/// without a PageView.
///
/// Vertical scrolling inside [child] is unaffected: only the horizontal
/// drag gesture is claimed, and a fling must exceed [velocityThreshold]
/// (logical pixels per second) to count as a swipe.
class HorizontalSwipeNavigator extends StatelessWidget {
  const HorizontalSwipeNavigator({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.velocityThreshold = 400,
  });

  final Widget child;

  /// Called on a leftward fling (finger moves right to left).
  final VoidCallback? onSwipeLeft;

  /// Called on a rightward fling (finger moves left to right).
  final VoidCallback? onSwipeRight;

  final double velocityThreshold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity <= -velocityThreshold) {
          onSwipeLeft?.call();
        } else if (velocity >= velocityThreshold) {
          onSwipeRight?.call();
        }
      },
      child: child,
    );
  }
}
