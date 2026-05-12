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

  // Dark cosmic palette (default). Background matches the onboarding +
  // auth screens so every surface that reads `p.background` is the same
  // calm dark slate.
  static const dark = AppPalette(
    background: Color(0xFF1A1F2E),
    surface: Color(0xFF1F2436),
    surfaceElevated: Color(0xFF252A3A),
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

  // iOS-style light palette.
  //
  // Mirrors Apple's system colors so the light mode feels native on
  // both platforms: secondarySystemBackground (#F2F2F7) for the page,
  // pure white surfaces with a near-white elevated layer for cards,
  // systemBlue (#007AFF) as the primary action color, true label
  // black for primary text, and the system secondary/tertiary grays
  // for hierarchy. We keep our brand gold for the same accents the
  // dark theme uses (logo glow, master-number badges, etc.) so the
  // identity carries across.
  static const light = AppPalette(
    background: Color(0xFFF2F2F7), // systemGroupedBackground
    surface: Color(0xFFFFFFFF), // secondarySystemGroupedBackground
    surfaceElevated: Color(0xFFE5E5EA), // systemGray5
    primary: Color(0xFF007AFF), // systemBlue
    accent: Color(0xFFFF2D55), // systemPink
    gold: Color(0xFFD4B16A), // brand gold (matches dark)
    textPrimary: Color(0xFF000000), // label
    textSecondary: Color(0xFF3C3C43), // secondaryLabel (full alpha)
    textTertiary: Color(0xFF8E8E93), // systemGray
    success: Color(0xFF34C759), // systemGreen
    warning: Color(0xFFFF9500), // systemOrange
    error: Color(0xFFFF3B30), // systemRed
    glassBorder: Color(0x14000000), // 8% black hairline
    premiumGradient: LinearGradient(
      colors: [Color(0xFFD4B16A), Color(0xFF9F7637)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cosmicGlow: LinearGradient(
      colors: [Color(0x14007AFF), Color(0x00F2F2F7)],
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
