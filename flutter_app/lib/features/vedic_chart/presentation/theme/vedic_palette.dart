import 'package:flutter/material.dart';

/// Traditional graha colors used for chips, glyphs, and accent strokes in
/// the Vedic UI. Kept as a feature-local palette so the global AppPalette
/// stays focused on app-wide tokens.
class VedicPalette {
  VedicPalette._();

  static const sun = Color(0xFFFFB347); // saffron / gold
  static const moon = Color(0xFFE8E8E8); // silver
  static const mars = Color(0xFFC0392B); // red
  static const mercury = Color(0xFF27AE60); // green
  static const jupiter = Color(0xFFF1C40F); // yellow
  static const venus = Color(0xFFFFFFFF); // white
  static const saturn = Color(0xFF34495E); // dark blue
  static const rahu = Color(0xFF8E44AD); // smoky purple
  static const ketu = Color(0xFF7F8C8D); // grey

  /// Dignity status colors.
  static const exalted = Color(0xFF2ECC71);
  static const debilitated = Color(0xFFE74C3C);
  static const ownSign = Color(0xFFF1C40F);

  static const _grahaColors = <String, Color>{
    'Sun': sun,
    'Moon': moon,
    'Mars': mars,
    'Mercury': mercury,
    'Jupiter': jupiter,
    'Venus': venus,
    'Saturn': saturn,
    'Rahu': rahu,
    'Ketu': ketu,
  };

  /// Convenience lookup by graha name. Returns a neutral grey for unknowns.
  static Color graha(String name) =>
      _grahaColors[name] ?? const Color(0xFF8E8BA3);
}
