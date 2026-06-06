import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hand-crafted "Kinetic Green" design system colours that have no direct
/// [ColorScheme] slot. The redesign moves the app off amethyst onto an
/// electric spring-green spine over neutral charcoal/paper surfaces.
class StitchColors {
  StitchColors._();

  /// Deeper emerald used for secondary chart bars and accents.
  static const primaryDim = Color(0xFF10B981);

  /// Accent gradient — electric spring green into deeper emerald.
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF10B981)],
  );
}

class AppTheme {
  AppTheme._();

  // ── Dark scheme (native) ─────────────────────────────────────────────
  // Tokens from rf.css `.phone[data-theme="dark"]`.

  @visibleForTesting
  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    // accent → primary
    primary: Color(0xFF00E5A0),
    onPrimary: Color(0xFF04130D),
    primaryContainer: Color(0xFF00382A),
    onPrimaryContainer: Color(0xFF7BF5CE),
    // accent-2 (deeper emerald) → secondary
    secondary: Color(0xFF10B981),
    onSecondary: Color(0xFF04130D),
    secondaryContainer: Color(0xFF0B3B2C),
    onSecondaryContainer: Color(0xFF8FF3D4),
    // volt (PR / record pop) → tertiary
    tertiary: Color(0xFFC6FF3D),
    onTertiary: Color(0xFF14210A),
    tertiaryContainer: Color(0xFF38450F),
    onTertiaryContainer: Color(0xFFDDFF8F),
    // danger → error
    error: Color(0xFFFF5D73),
    onError: Color(0xFF3A0510),
    errorContainer: Color(0xFF7A0C20),
    onErrorContainer: Color(0xFFFFB2BC),
    // neutral surfaces (bg + s1/s2/s3)
    surface: Color(0xFF0A0B0D),
    onSurface: Color(0xFFF3F6F4),
    onSurfaceVariant: Color(0xFF8B938F), // --dim
    surfaceContainerLowest: Color(0xFF070809),
    surfaceContainerLow: Color(0xFF15181C), // --s1 (cards)
    surfaceContainer: Color(0xFF1C2026), // --s2 (raised / active)
    surfaceContainerHigh: Color(0xFF252A31), // --s3 (chips / tracks)
    surfaceContainerHighest: Color(0xFF2B3138),
    surfaceBright: Color(0xFF0E1013), // glass nav base
    outline: Color(0xFF565D59), // --faint
    outlineVariant: Color(0xFF3A4047),
    inverseSurface: Color(0xFFF3F6F4),
    onInverseSurface: Color(0xFF0C1410),
    inversePrimary: Color(0xFF00C389),
    surfaceTint: Color(0xFF00E5A0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // ── Light scheme (opt-in) ────────────────────────────────────────────
  // Tokens from rf.css `.phone[data-theme="light"]`. Not a naive inversion —
  // the accent is deeper and lines are darker for legibility on paper.

  @visibleForTesting
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00C389),
    onPrimary: Color(0xFF042016),
    primaryContainer: Color(0xFFB8F5E0),
    onPrimaryContainer: Color(0xFF00382A),
    secondary: Color(0xFF059669),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFC4F0E1),
    onSecondaryContainer: Color(0xFF00382A),
    tertiary: Color(0xFF5B8C00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD7F59A),
    onTertiaryContainer: Color(0xFF233600),
    error: Color(0xFFD4264A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDADD),
    onErrorContainer: Color(0xFF5C0014),
    surface: Color(0xFFEAEEEC),
    onSurface: Color(0xFF0C1410),
    onSurfaceVariant: Color(0xFF5D655F), // --dim
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F8F6), // --s1 (cards)
    surfaceContainer: Color(0xFFEEF2F0), // --s2
    surfaceContainerHigh: Color(0xFFE5EBE7), // --s3
    surfaceContainerHighest: Color(0xFFDDE4DF),
    surfaceBright: Color(0xFFFFFFFF), // glass nav base
    outline: Color(0xFF9AA39D), // --faint
    outlineVariant: Color(0xFFD4DCD6),
    inverseSurface: Color(0xFF0E1013),
    onInverseSurface: Color(0xFFF3F6F4),
    inversePrimary: Color(0xFF00E5A0),
    surfaceTint: Color(0xFF00C389),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // ── Typography ───────────────────────────────────────────────────────
  // Space Grotesk for display/headings, Manrope for body/UI. (Numerals use
  // JetBrains Mono at the widget level where a technical feel is wanted.)

  static TextTheme get _textTheme {
    final headline = GoogleFonts.spaceGroteskTextTheme(
      const TextTheme(
        displayLarge: TextStyle(),
        displayMedium: TextStyle(),
        displaySmall: TextStyle(),
        headlineLarge: TextStyle(),
        headlineMedium: TextStyle(),
        headlineSmall: TextStyle(),
        titleLarge: TextStyle(),
      ),
    );

    final body = GoogleFonts.manropeTextTheme(
      const TextTheme(
        titleMedium: TextStyle(),
        titleSmall: TextStyle(),
        bodyLarge: TextStyle(),
        bodyMedium: TextStyle(),
        bodySmall: TextStyle(),
        labelLarge: TextStyle(),
        labelMedium: TextStyle(),
        labelSmall: TextStyle(),
      ),
    );

    return headline.merge(body);
  }

  // ── Theme Data ───────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme scheme) => ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: scheme.surface,
        textTheme: _textTheme,
        cardTheme: CardThemeData(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          dividerHeight: 0,
          indicatorColor: scheme.primary,
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurfaceVariant,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          thickness: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  static ThemeData get dark => _build(darkScheme);

  static ThemeData get light => _build(lightScheme);
}
