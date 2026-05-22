import 'package:flutter/material.dart';

/// AppPalette is a ThemeExtension that holds custom design tokens not covered
/// by Material 3's ColorScheme. Both the dark and light themes register their
/// own instance so widgets that read it via Theme.of(context).extension<AppPalette>()
/// automatically switch when the theme changes.
///
/// The token set follows the **Lively design system** ("Dark · Cosmic" +
/// "Light · iOS" twins) — a warm bronze-gold accent on a near-black cosmic
/// ground, with an iOS-warm cream light theme. Older token names
/// (`accent`, `surfaceElevated`, `textSecondary`, `textTertiary`, the
/// gradient fields) are kept so existing screens compile unchanged; new
/// screens should prefer the design-system names (`primaryHi`, `primaryDim`,
/// `onPrimary`, `line`, `surfaceGlass`, `textMuted`, `textDim`, `bgDeep`).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.bgDeep,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceGlass,
    required this.line,
    required this.primary,
    required this.primaryHi,
    required this.primaryDim,
    required this.onPrimary,
    required this.accent,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.textDim,
    required this.success,
    required this.warning,
    required this.error,
    required this.glassBorder,
    required this.premiumGradient,
    required this.primaryGradient,
    required this.cardGradient,
    required this.cosmicGlow,
  });

  /// Page background.
  final Color background;

  /// A notch darker than [background] — used for the deepest layer of the
  /// cosmic backdrop and inset wells.
  final Color bgDeep;

  /// Default raised surface (cards, sheets).
  final Color surface;

  /// A raised surface one level above [surface].
  final Color surfaceElevated;

  /// Translucent glass fill — sits over the backdrop with a blur.
  final Color surfaceGlass;

  /// Hairline divider / idle input border.
  final Color line;

  /// Brand bronze-gold — primary action color.
  final Color primary;

  /// A lighter tint of [primary] — top highlight on buttons, hover.
  final Color primaryHi;

  /// A dimmed shade of [primary] — pressed states, low-emphasis gold.
  final Color primaryDim;

  /// Foreground color that sits ON [primary] (e.g. gold-button label).
  final Color onPrimary;

  /// Secondary accent. In the cosmic system this is a lighter gold so
  /// `[primary, accent]` gradients read as a soft gold sheen.
  final Color accent;

  /// Brand gold — kept as a distinct token for badges / logo glow.
  final Color gold;

  /// Primary text.
  final Color textPrimary;

  /// Secondary text (alias of [textMuted], kept for older screens).
  final Color textSecondary;

  /// Tertiary text (alias of [textDim], kept for older screens).
  final Color textTertiary;

  /// Muted text — captions, supporting copy.
  final Color textMuted;

  /// Dimmest text — placeholders, disabled.
  final Color textDim;

  final Color success;
  final Color warning;
  final Color error;

  /// Gold-tinted translucent border for glass cards.
  final Color glassBorder;

  final LinearGradient premiumGradient;
  final LinearGradient primaryGradient;
  final LinearGradient cardGradient;
  final LinearGradient cosmicGlow;

  // ───────────────────────────────────────────────────────────────
  // Dark · Cosmic — near-black ground, bronze-gold accent.
  // ───────────────────────────────────────────────────────────────
  static const dark = AppPalette(
    background: Color(0xFF08080F),
    bgDeep: Color(0xFF050509),
    surface: Color(0xFF13131C),
    surfaceElevated: Color(0xFF1B1B27),
    surfaceGlass: Color(0x0AFFFFFF), // white @ 4%
    line: Color(0x14FFFFFF), // white @ 8%
    primary: Color(0xFFD4B16A),
    primaryHi: Color(0xFFE8C988),
    primaryDim: Color(0xFF9C8049),
    onPrimary: Color(0xFF1A1408),
    accent: Color(0xFFE8C988),
    gold: Color(0xFFD4B16A),
    textPrimary: Color(0xFFF2EBD9),
    textSecondary: Color(0xFFA09989),
    textTertiary: Color(0xFF6A6358),
    textMuted: Color(0xFFA09989),
    textDim: Color(0xFF6A6358),
    success: Color(0xFF7FB686),
    warning: Color(0xFFE0A86E),
    error: Color(0xFFD87575),
    glassBorder: Color(0x38D4B16A), // gold @ 22%
    premiumGradient: LinearGradient(
      colors: [Color(0xFFE8C988), Color(0xFF9C8049)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryGradient: LinearGradient(
      colors: [Color(0xFFE8C988), Color(0xFFD4B16A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF13131C), Color(0xFF08080F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cosmicGlow: LinearGradient(
      colors: [Color(0x33D4B16A), Color(0x0008080F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ───────────────────────────────────────────────────────────────
  // Light · iOS — warm cream ground, deeper gold for AA contrast.
  // ───────────────────────────────────────────────────────────────
  static const light = AppPalette(
    background: Color(0xFFFBF7EE),
    bgDeep: Color(0xFFF4EFE2),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceGlass: Color(0xB3FFFFFF), // white @ 70%
    line: Color(0x141A1610), // ink @ 8%
    primary: Color(0xFFA88546),
    primaryHi: Color(0xFFC09957),
    primaryDim: Color(0xFF7A6233),
    onPrimary: Color(0xFFFFFBF1),
    accent: Color(0xFFC09957),
    gold: Color(0xFFA88546),
    textPrimary: Color(0xFF1A1610),
    textSecondary: Color(0xFF6B6259),
    textTertiary: Color(0xFFA09989),
    textMuted: Color(0xFF6B6259),
    textDim: Color(0xFFA09989),
    success: Color(0xFF5C8E66),
    warning: Color(0xFFB57F3C),
    error: Color(0xFFB85555),
    glassBorder: Color(0x40A88546), // gold @ 25%
    premiumGradient: LinearGradient(
      colors: [Color(0xFFC09957), Color(0xFF7A6233)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryGradient: LinearGradient(
      colors: [Color(0xFFC09957), Color(0xFFA88546)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF8F0DD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cosmicGlow: LinearGradient(
      colors: [Color(0x1FA88546), Color(0x00FBF7EE)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? bgDeep,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceGlass,
    Color? line,
    Color? primary,
    Color? primaryHi,
    Color? primaryDim,
    Color? onPrimary,
    Color? accent,
    Color? gold,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textMuted,
    Color? textDim,
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
      bgDeep: bgDeep ?? this.bgDeep,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      line: line ?? this.line,
      primary: primary ?? this.primary,
      primaryHi: primaryHi ?? this.primaryHi,
      primaryDim: primaryDim ?? this.primaryDim,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      gold: gold ?? this.gold,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
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
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      line: Color.lerp(line, other.line, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHi: Color.lerp(primaryHi, other.primaryHi, t)!,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
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
