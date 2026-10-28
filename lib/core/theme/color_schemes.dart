import 'package:flutter/material.dart';

class CulinaryColors {
  static const Color restOrange = Color(0xFFFF6B00); // Master Rest POS Brand Color
  static const Color tandoorOrange = Color(0xFFFF5722);
  static const Color flameOrange = Color(0xFFEA580C);
  static const Color tandoorSpice = Color(0xFFEA580C);
  static const Color turmericGold = Color(0xFFF59E0B);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color crimsonRed = Color(0xFFE11D48);
  static const Color royalBlue = Color(0xFF0284C7);
  static const Color amethystViolet = Color(0xFF8B5CF6);
  static const Color roseDessert = Color(0xFFEC4899);
}

class AppColorSchemes {
  // Vibrant Culinary Accent Tokens
  static const Color saffronOrange = Color(0xFFFF5722); // Deep Tandoor & Spices
  static const Color turmericGold = Color(0xFFF59E0B);  // Rich Curry & Ghee
  static const Color cardamomGreen = Color(0xFF10B981); // Fresh Mint & Veg
  static const Color crimsonRed = Color(0xFFE11D48);    // Non-Veg & Tandoori
  static const Color royalPlum = Color(0xFF8B5CF6);     // Premium Seating & Tables
  static const Color oceanicBlue = Color(0xFF0284C7);   // Refreshing Beverages
  static const Color dessertPink = Color(0xFFEC4899);   // Sweet Desserts

  // Semantic Restaurant Status Colors
  static const Color vegGreen = Color(0xFF16A34A);
  static const Color nonVegRed = Color(0xFFDC2626);
  static const Color eggAmber = Color(0xFFD97706);
  static const Color bestsellerGold = Color(0xFFEAB308);

  static const Color tableAvailable = Color(0xFF10B981);
  static const Color tableOccupied = Color(0xFF2563EB);
  static const Color tableBilled = Color(0xFFD97706);
  static const Color tableReserved = Color(0xFF9333EA);

  // Light Material 3 Color Scheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFEA580C), // Vibrant Fire Orange / Saffron
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFECE6),
    onPrimaryContainer: Color(0xFF7C2D12),
    secondary: Color(0xFFD97706), // Rich Golden Amber
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFEF3C7),
    onSecondaryContainer: Color(0xFF78350F),
    tertiary: Color(0xFF059669), // Emerald Leaf Green
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD1FAE5),
    onTertiaryContainer: Color(0xFF064E3B),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFDFBF9),
    onSurface: Color(0xFF1C1917),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F3EF),
    surfaceContainer: Color(0xFFEFE8E2),
    surfaceContainerHigh: Color(0xFFE7DDD5),
    surfaceContainerHighest: Color(0xFFDFD2C7),
    outline: Color(0xFF78716C),
    outlineVariant: Color(0xFFD6CECA),
  );

  // Dark Material 3 Color Scheme
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFB923C),
    onPrimary: Color(0xFF431407),
    primaryContainer: Color(0xFF7C2D12),
    onPrimaryContainer: Color(0xFFFFEDD5),
    secondary: Color(0xFFFBBF24),
    onSecondary: Color(0xFF451A03),
    secondaryContainer: Color(0xFF92400E),
    onSecondaryContainer: Color(0xFFFEF3C7),
    tertiary: Color(0xFF34D399),
    onTertiary: Color(0xFF022C22),
    tertiaryContainer: Color(0xFF064E3B),
    onTertiaryContainer: Color(0xFFA7F3D0),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF141211),
    onSurface: Color(0xFFF5F5F4),
    surfaceContainerLowest: Color(0xFF0C0A09),
    surfaceContainerLow: Color(0xFF1C1917),
    surfaceContainer: Color(0xFF292524),
    surfaceContainerHigh: Color(0xFF363230),
    surfaceContainerHighest: Color(0xFF44403C),
    outline: Color(0xFFA8A29E),
    outlineVariant: Color(0xFF57534E),
  );
}
