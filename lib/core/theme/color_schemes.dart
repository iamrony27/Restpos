import 'package:flutter/material.dart';

class AppColorSchemes {
  // Light Material 3 Color Scheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFC0392B), // Restaurant Terracotta / Crimson
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDAD4),
    onPrimaryContainer: Color(0xFF410001),
    secondary: Color(0xFFD97706), // Warm Amber
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFEF3C7),
    onSecondaryContainer: Color(0xFF78350F),
    tertiary: Color(0xFF0D9488), // Fresh Teal
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCCFBF1),
    onTertiaryContainer: Color(0xFF134E4A),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFBF9F8),
    onSurface: Color(0xFF201A19),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F2F1),
    surfaceContainer: Color(0xFFF1ECEB),
    surfaceContainerHigh: Color(0xFFEBE6E5),
    surfaceContainerHighest: Color(0xFFE5E0DF),
    outline: Color(0xFF857371),
    outlineVariant: Color(0xFFD8C2BF),
  );

  // Dark Material 3 Color Scheme
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF897D),
    onPrimary: Color(0xFF680003),
    primaryContainer: Color(0xFF930006),
    onPrimaryContainer: Color(0xFFFFDAD4),
    secondary: Color(0xFFFBBF24),
    onSecondary: Color(0xFF451A03),
    secondaryContainer: Color(0xFF92400E),
    onSecondaryContainer: Color(0xFFFEF3C7),
    tertiary: Color(0xFF2DD4BF),
    onTertiary: Color(0xFF003732),
    tertiaryContainer: Color(0xFF115E59),
    onTertiaryContainer: Color(0xFFCCFBF1),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF181211),
    onSurface: Color(0xFFEDE0DE),
    surfaceContainerLowest: Color(0xFF120D0C),
    surfaceContainerLow: Color(0xFF201A19),
    surfaceContainer: Color(0xFF251E1D),
    surfaceContainerHigh: Color(0xFF2F2827),
    surfaceContainerHighest: Color(0xFF3B3332),
    outline: Color(0xFFA08C8A),
    outlineVariant: Color(0xFF534341),
  );
}
