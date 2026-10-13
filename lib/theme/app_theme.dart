import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared design system for Campus Supply.
///
/// Warm neutrals, strong blue actions, deep navy text, and consistent
/// components keep customer and admin screens visually aligned.
class AppTheme {
  static const canvas = Color(0xFFFAF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF172554);
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const accent = Color(0xFFFFC66D);
  static const coral = Color(0xFFFF8066);
  static const mint = Color(0xFFE8F7F0);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const softBlue = Color(0xFFEAF2FF);
  static const softYellow = Color(0xFFFFF7CC);
  static const softCoral = Color(0xFFFFE9E6);
  static const danger = Color(0xFFB42318);
  static const success = Color(0xFF15803D);

  // Keep existing names available for screens that are still migrating.
  static const cream = canvas;
  static const blue = primary;
  static const blueDark = primaryDark;
  static const yellow = accent;
  static const white = surface;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
    );
    final interText = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );
    final textTheme = interText.copyWith(
      displayLarge: GoogleFonts.poppins(
        textStyle: interText.displayLarge,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      displayMedium: GoogleFonts.poppins(
        textStyle: interText.displayMedium,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      displaySmall: GoogleFonts.poppins(
        textStyle: interText.displaySmall,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      headlineLarge: GoogleFonts.poppins(
        textStyle: interText.headlineLarge,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: interText.headlineMedium,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      headlineSmall: GoogleFonts.poppins(
        textStyle: interText.headlineSmall,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: interText.titleLarge,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: interText.titleMedium,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surface,
      primary: primary,
      secondary: accent,
      error: danger,
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: border),
    );

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      colorScheme: scheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          minimumSize: const Size(0, 50),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          minimumSize: const Size(0, 48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        indicatorColor: softBlue,
        height: 72,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          color: surface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}
