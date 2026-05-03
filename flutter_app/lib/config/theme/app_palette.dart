import 'package:flutter/material.dart';

/// AppPalette is a ThemeExtension that holds custom design tokens not covered
/// by Material 3's ColorScheme. Both the dark and light themes register their
/// own instance so widgets that read it via Theme.of(context).extension<AppPalette>()
/// automatically switch when the theme changes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.accent,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.error,
    required this.glassBorder,
    required this.premiumGradient,
    required this.primaryGradient,
    required this.cardGradient,
    required this.cosmicGlow,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color accent;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color error;
  final Color glassBorder;
  final LinearGradient premiumGradient;
  final LinearGradient primaryGradient;
  final LinearGradient cardGradient;
  final LinearGradient cosmicGlow;

  // Dark cosmic palette (default)
  static const dark = AppPalette(
    background: Color(0xFF0A0E27),
    surface: Color(0xFF141833),
    surfaceElevated: Color(0xFF1E2347),
    primary: Color(0xFF6C3CE1),
    accent: Color(0xFFE14B8A),
    gold: Color(0xFFF4C542),
    textPrimary: Color(0xFFF0EFF4),
    textSecondary: Color(0xFF8E8BA3),
    textTertiary: Color(0xFF5C5A6E),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    glassBorder: Color(0x1AFFFFFF),
    premiumGradient: LinearGradient(
      colors: [Color(0xFFE14B8A), Color(0xFF8B2A55)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF6C3CE1), Color(0xFFE14B8A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF1A1F3D), Color(0xFF141833)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cosmicGlow: LinearGradient(
      colors: [Color(0x336C3CE1), Color(0x00141833)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // Light cream/brown palette
  static const light = AppPalette(
    background: Color(0xFFFAF6F0),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF5EFE6),
    primary: Color(0xFF8B5A2B),
    accent: Color(0xFFC76E5E),
    gold: Color(0xFFB8860B),
    textPrimary: Color(0xFF2D1810),
    textSecondary: Color(0xFF8A7565),
    textTertiary: Color(0xFFB8A89A),
    success: Color(0xFF5B8C5A),
    warning: Color(0xFFD4A04C),
    error: Color(0xFFB85450),
    glassBorder: Color(0x1A2D1810),
    premiumGradient: LinearGradient(
      colors: [Color(0xFFC76E5E), Color(0xFF8B3A2B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF8B5A2B), Color(0xFFC76E5E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF5EFE6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cosmicGlow: LinearGradient(
      colors: [Color(0x338B5A2B), Color(0x00FAF6F0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? accent,
    Color? gold,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? warning,
    Color? error,
    Color? glassBorder,
    LinearGradient? premiumGradient,
    LinearGradient? primaryGradient,
    LinearGradient? cardGradient,
    LinearGradient? cosmicGlow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      gold: gold ?? this.gold,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      glassBorder: glassBorder ?? this.glassBorder,
      premiumGradient: premiumGradient ?? this.premiumGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      cosmicGlow: cosmicGlow ?? this.cosmicGlow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      premiumGradient: t < 0.5 ? premiumGradient : other.premiumGradient,
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      cardGradient: t < 0.5 ? cardGradient : other.cardGradient,
      cosmicGlow: t < 0.5 ? cosmicGlow : other.cosmicGlow,
    );
  }
}

/// Convenient accessor: `context.palette.primary`.
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
