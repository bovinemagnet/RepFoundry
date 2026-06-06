import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/app/theme.dart';

void main() {
  group('AppTheme — Kinetic Green', () {
    test('dark uses the electric spring-green accent, not amethyst', () {
      const scheme = AppTheme.darkScheme;
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.primary, const Color(0xFF00E5A0));
      expect(scheme.onPrimary, const Color(0xFF04130D));
      // PR/record "volt" pop maps to tertiary.
      expect(scheme.tertiary, const Color(0xFFC6FF3D));
      // Destructive "danger" maps to error.
      expect(scheme.error, const Color(0xFFFF5D73));
    });

    test('dark surfaces are charcoal — no purple tint', () {
      const scheme = AppTheme.darkScheme;
      // Base background is near-black charcoal (bg token).
      expect(scheme.surface, const Color(0xFF0A0B0D));
      // Card surface is the s1 charcoal tile.
      expect(scheme.surfaceContainerLow, const Color(0xFF15181C));
    });

    test('light is a real light scheme with its own grounded green', () {
      const scheme = AppTheme.lightScheme;
      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, const Color(0xFF00C389));
      expect(scheme.surface, const Color(0xFFEAEEEC));
    });

    test('dark and light are distinct (light is not aliased to dark)', () {
      expect(
        AppTheme.lightScheme.surface,
        isNot(AppTheme.darkScheme.surface),
      );
      expect(
        AppTheme.lightScheme.brightness,
        isNot(AppTheme.darkScheme.brightness),
      );
    });
  });
}
