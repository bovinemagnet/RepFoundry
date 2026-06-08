import 'package:flutter/material.dart';

class RepFoundryAppIcon extends StatelessWidget {
  const RepFoundryAppIcon({
    super.key,
    this.size = 48,
    this.borderRadius,
  });

  static const assetPath = 'assets/images/icons/RepFoundary_icon.png';

  final double size;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    final fallbackColor = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        assetPath,
        key: const ValueKey('rep_foundry_app_icon_image'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        semanticLabel: 'RepFoundry app icon',
        errorBuilder: (_, __, ___) => SizedBox.square(
          dimension: size,
          child: Icon(
            Icons.fitness_center,
            size: size * 0.72,
            color: fallbackColor,
          ),
        ),
      ),
    );
  }
}
