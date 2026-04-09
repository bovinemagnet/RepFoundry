import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hand-crafted "Kinetic Precision" design system colours that have no
/// direct [ColorScheme] slot.
class StitchColors {
  StitchColors._();

  static const primaryDim = Color(0xFF8354F4);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFB99FFF), Color(0xFF8354F4)],
  );
}

class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────────────────────────────

  static const _surface = Color(0xFF16052A);
  static const _surfaceContainerLowest = Color(0xFF000000);
  static const _surfaceContainerLow = Color(0xFF1D0832);
  static const _surfaceContainer = Color(0xFF240E3B);
  static const _surfaceContainerHigh = Color(0xFF2B1344);
  static const _surfaceContainerHighest = Color(0xFF32194E);
  static const _surfaceBright = Color(0xFF391E58);

  static const _primary = Color(0xFFB99FFF);
  static const _primaryContainer = Color(0xFFAC8EFF);
  static const _onPrimary = Color(0xFF38008D);
  static const _onPrimaryContainer = Color(0xFF2A006F);

  static const _secondary = Color(0xFFBF8CF7);
  static const _secondaryContainer = Color(0xFF5D2C92);
  static const _onSecondary = Color(0xFF380069);
  static const _onSecondaryContainer = Color(0xFFE2C5FF);

  static const _tertiary = Color(0xFFFF97B7);
  static const _tertiaryContainer = Color(0xFFFC81AA);
  static const _onTertiary = Color(0xFF6A0936);
  static const _onTertiaryContainer = Color(0xFF59002B);

  static const _error = Color(0xFFFF6E84);
  static const _errorContainer = Color(0xFFA70138);
  static const _onError = Color(0xFF490013);
  static const _onErrorContainer = Color(0xFFFFB2B9);

  static const _onSurface = Color(0xFFF1DFFF);
  static const _onSurfaceVariant = Color(0xFFB9A2D0);
  static const _outline = Color(0xFF826D97);
  static const _outlineVariant = Color(0xFF534067);
  static const _inverseSurface = Color(0xFFFFF7FF);
  static const _inversePrimary = Color(0xFF6C3ADC);
  static const _surfaceTint = Color(0xFFB99FFF);

  // ── Colour Scheme ────────────────────────────────────────────────────

  static const _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _primary,
    onPrimary: _onPrimary,
    primaryContainer: _primaryContainer,
    onPrimaryContainer: _onPrimaryContainer,
    secondary: _secondary,
    onSecondary: _onSecondary,
    secondaryContainer: _secondaryContainer,
    onSecondaryContainer: _onSecondaryContainer,
    tertiary: _tertiary,
    onTertiary: _onTertiary,
    tertiaryContainer: _tertiaryContainer,
    onTertiaryContainer: _onTertiaryContainer,
    error: _error,
    onError: _onError,
    errorContainer: _errorContainer,
    onErrorContainer: _onErrorContainer,
    surface: _surface,
    onSurface: _onSurface,
    onSurfaceVariant: _onSurfaceVariant,
    outline: _outline,
    outlineVariant: _outlineVariant,
    inverseSurface: _inverseSurface,
    inversePrimary: _inversePrimary,
    surfaceTint: _surfaceTint,
    surfaceContainerLowest: _surfaceContainerLowest,
    surfaceContainerLow: _surfaceContainerLow,
    surfaceContainer: _surfaceContainer,
    surfaceContainerHigh: _surfaceContainerHigh,
    surfaceContainerHighest: _surfaceContainerHighest,
    surfaceBright: _surfaceBright,
  );

  // ── Typography ───────────────────────────────────────────────────────

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

  static ThemeData get dark => ThemeData(
        colorScheme: _colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: _surface,
        textTheme: _textTheme,
        cardTheme: CardThemeData(
          elevation: 0,
          color: _surfaceContainer,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _onSurface,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          dividerHeight: 0,
          indicatorColor: _primary,
          labelColor: _onSurface,
          unselectedLabelColor: _onSurfaceVariant,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          thickness: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryContainer,
          foregroundColor: _onPrimaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceContainerHighest,
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  static ThemeData get light => dark;
}
