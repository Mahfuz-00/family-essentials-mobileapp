import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Warm Sage" design system for the mobile app.
///
/// Mirrors the web tokens in `Frontend/src/index.css`, which in turn mirror
/// `UI/` design exports and `stitch_cross_platform_dashboard_ui/warm_sage/DESIGN.md`.
///
/// TYPEFACES: the design specifies Plus Jakarta Sans, applied below through the
/// `google_fonts` package. That fetches the face on first use and caches it on
/// device; to remove the runtime fetch entirely, drop the TTFs into
/// `assets/fonts/` and declare them under `fonts:` in pubspec.yaml — the
/// package will then prefer the bundled files.
class AppTheme {
  // ------------------------------------------------------------------ colours
  static const Color primary = Color(0xFF4D6054);
  static const Color primaryContainer = Color(0xFF66796C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFF6FFF6);

  static const Color secondary = Color(0xFF376847);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFB6EDC2);

  static const Color tertiary = Color(0xFF97422B);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color canvas = Color(0xFFFDFCF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F2FF);
  static const Color surfaceContainer = Color(0xFFEDECFF);

  static const Color ink = Color(0xFF181A2E);
  static const Color onSurfaceVariant = Color(0xFF434844);
  static const Color muted = Color(0xFF6C757D);
  static const Color outline = Color(0xFFC3C8C2);
  static const Color inverseSurface = Color(0xFF2D2F44);
  static const Color inverseOnSurface = Color(0xFFF1EFFF);

  static const Color forestSoft = Color(0xFFE4EDE7);
  static const Color sageSoft = Color(0xFFEBF0ED);
  static const Color coralSoft = Color(0xFFFCECE7);

  static const Color success = Color(0xFF81B29A);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFE76F51);

  // -------------------------------------------------------------------- shape
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  /// 8-point spatial system.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;

  // ---------------------------------------------------------------- elevation
  // Slate-tinted ambient shadows, never pure black.
  static const List<BoxShadow> elev1 = [
    BoxShadow(color: Color(0x0A2B2D42), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x052B2D42), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> elev2 = [
    BoxShadow(color: Color(0x0F2B2D42), blurRadius: 16, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A2B2D42), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elev3 = [
    BoxShadow(color: Color(0x2E4A7C59), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0F2B2D42), blurRadius: 10, offset: Offset(0, 4)),
  ];

  // ------------------------------------------------------------------- type
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * 32,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.01 * 24,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, color: ink),
    bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, color: ink),
    bodySmall: TextStyle(fontSize: 12, height: 18 / 12, color: muted),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.01 * 12,
      color: ink,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.02 * 11,
      color: muted,
    ),
  );

  // ------------------------------------------------------------------- theme
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      tertiary: tertiary,
      surface: surface,
      onSurface: ink,
      error: error,
    ),
    scaffoldBackgroundColor: canvas,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(textTheme),

    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: ink,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.01 * 20,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: Color(0x0D2B2D42)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0x1F2B2D42)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0x1F2B2D42)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error),
      ),
    ),

    // Primary action: deep forest teal, 52pt tall, 14pt radius.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: ink,
        backgroundColor: surface,
        side: const BorderSide(color: Color(0x8066796C)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: sageSoft,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? secondary : outline,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: forestSoft,
      elevation: 3,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0x142B2D42),
      thickness: 1,
      space: 1,
    ),
  );
}
