import 'package:flutter/material.dart';

/// Legacy color constants used by screens that pre-date the
/// [AppPalette] ThemeExtension. Re-pointed at the **Lively "Dark ·
/// Cosmic"** values so every older screen that reads `CosmicColors.*`
/// picks up the bronze-gold-on-near-black design system automatically.
///
/// New screens should prefer `context.palette` (AppPalette) — this class
/// is kept only so the not-yet-rebuilt screens stay visually consistent.
class CosmicColors {
  CosmicColors._();

  // Core palette — Lively Dark · Cosmic.
  static const Color background = Color(0xFF08080F);
  static const Color surface = Color(0xFF13131C);
  static const Color surfaceLight = Color(0xFF1B1B27);
  static const Color primary = Color(0xFFD4B16A);
  static const Color primaryLight = Color(0xFFE8C988);
  static const Color accent = Color(0xFFE8C988);
  static const Color accentLight = Color(0xFFF0DCAE);
  static const Color gold = Color(0xFFD4B16A);

  // Text.
  static const Color textPrimary = Color(0xFFF2EBD9);
  static const Color textSecondary = Color(0xFFA09989);
  static const Color textTertiary = Color(0xFF6A6358);

  // Semantic.
  static const Color success = Color(0xFF7FB686);
  static const Color warning = Color(0xFFE0A86E);
  static const Color error = Color(0xFFD87575);

  // Gradients — gold sheens, no more purple/pink.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE8C988), Color(0xFFD4B16A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFE8C988), Color(0xFFD4B16A), Color(0xFF9C8049)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF13131C), Color(0xFF08080F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cosmicGlow = LinearGradient(
    colors: [
      Color(0x33D4B16A),
      Color(0x0008080F),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glassmorphism — gold-tinted hairline border.
  static final Color glassBackground = Colors.white.withValues(alpha: 0.04);
  static final Color glassBorder =
      const Color(0xFFD4B16A).withValues(alpha: 0.22);
}
