import 'package:flutter/material.dart';

import 'colors.dart';

/// Legacy text styles for screens that pre-date [LivelyType]. Re-pointed
/// at the bundled Lively fonts — **Instrument Serif** (italic display) and
/// **Geist** (UI) — so older screens inherit the design-system type
/// identity. New screens should prefer `LivelyType`.
class CosmicTypography {
  CosmicTypography._();

  static const String _serif = 'InstrumentSerif';
  static const String _ui = 'Geist';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _serif,
    fontStyle: FontStyle.italic,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    color: CosmicColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _serif,
    fontStyle: FontStyle.italic,
    fontSize: 29,
    fontWeight: FontWeight.w400,
    color: CosmicColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _serif,
    fontStyle: FontStyle.italic,
    fontSize: 25,
    fontWeight: FontWeight.w400,
    color: CosmicColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: CosmicColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _ui,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: CosmicColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _ui,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: CosmicColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: CosmicColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: CosmicColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: CosmicColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CosmicColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _ui,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: CosmicColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CosmicColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _ui,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: CosmicColors.textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CosmicColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _ui,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: CosmicColors.textSecondary,
    letterSpacing: 1.2,
  );

  static const TextStyle affirmation = TextStyle(
    fontFamily: _serif,
    fontStyle: FontStyle.italic,
    fontSize: 21,
    fontWeight: FontWeight.w400,
    color: CosmicColors.gold,
    height: 1.6,
  );
}
