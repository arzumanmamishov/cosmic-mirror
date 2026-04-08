import 'package:flutter/material.dart';

class CosmicColors {
  CosmicColors._();

  // Core palette
  static const Color background = Color(0xFF0A0E27);
  static const Color surface = Color(0xFF141833);
  static const Color surfaceLight = Color(0xFF1E2347);
  static const Color primary = Color(0xFF6C3CE1);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFE14B8A);
  static const Color accentLight = Color(0xFFF472B6);
  static const Color gold = Color(0xFFF4C542);

  // Text
  static const Color textPrimary = Color(0xFFF0EFF4);
  static const Color textSecondary = Color(0xFF8E8BA3);
  static const Color textTertiary = Color(0xFF5C5A6E);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF6C3CE1), Color(0xFFE14B8A), Color(0xFFF4C542)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F3D), Color(0xFF141833)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cosmicGlow = LinearGradient(
    colors: [
      Color(0x336C3CE1),
      Color(0x00141833),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glassmorphism
  static Color glassBackground = Colors.white.withOpacity(0.05);
  static Color glassBorder = Colors.white.withOpacity(0.1);
}
