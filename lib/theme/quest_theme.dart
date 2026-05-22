import 'package:flutter/material.dart';

/// Retro 8-bit RPG color palette and typography.
abstract final class QuestTheme {
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color border = Color(0xFF444444);
  static const Color primary = Color(0xFF39FF14);
  static const Color secondary = Color(0xFFFFD700);
  static const Color error = Color(0xFFFF4444);
  static const Color onBackground = Color(0xFFE0E0E0);
  static const Color onSurfaceMuted = Color(0xFF888888);

  static ThemeData get dark {
    const fontFamily = 'monospace';

    final colorScheme = ColorScheme.dark(
      surface: surface,
      onSurface: onBackground,
      primary: primary,
      onPrimary: background,
      secondary: secondary,
      onSecondary: background,
      error: error,
      onError: onBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primary,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: border, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: border, width: 2),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: onSurfaceMuted,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: onSurfaceMuted,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primary,
          letterSpacing: 2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: onBackground,
          letterSpacing: 1,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: secondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: onBackground,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: onBackground,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: onSurfaceMuted,
          letterSpacing: 1,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 2,
        space: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: onBackground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: border, width: 2),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
