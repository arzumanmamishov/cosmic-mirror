import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lively type ramp — **Instrument Serif** (italic display) × a Geist-class
/// UI sans × a mono for coordinates / timestamps.
///
/// Font note: the design calls for Geist + Geist Mono, but the bundled
/// `google_fonts` version doesn't ship them. We substitute **Inter** (the
/// canonical neo-grotesque stand-in for Geist — near-identical metrics and
/// proportions) and **JetBrains Mono**. Instrument Serif is available and
/// used as specified. If `google_fonts` is later upgraded, swap the two
/// `_ui` / `_mono` helpers to `GoogleFonts.geist` / `geistMono`.
///
/// Every method takes the resolved color so callers stay palette-driven:
/// `LivelyType.d2(p.textPrimary)`. Letter-spacing values are converted from
/// the design's `em` units to logical pixels at each size.
abstract final class LivelyType {
  // Internal font selectors — swap these two if Geist becomes available.
  static TextStyle _ui({
    required Color color,
    required double size,
    required double height,
    required FontWeight weight,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  static TextStyle _mono({
    required Color color,
    required double size,
    double letterSpacing = 0.6,
  }) =>
      GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacing,
      );

  // ── Display · Instrument Serif italic ──────────────────────────
  /// 56 / 60 · hero display.
  static TextStyle d1(Color color) => GoogleFonts.instrumentSerif(
        color: color,
        fontSize: 56,
        height: 60 / 56,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.12, // -0.02em
      );

  /// 42 / 46 · screen hero title.
  static TextStyle d2(Color color) => GoogleFonts.instrumentSerif(
        color: color,
        fontSize: 42,
        height: 46 / 42,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.63, // -0.015em
      );

  /// 32 / 36 · section hero title.
  static TextStyle d3(Color color) => GoogleFonts.instrumentSerif(
        color: color,
        fontSize: 32,
        height: 36 / 32,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32, // -0.01em
      );

  // ── UI · Geist-class sans ─────────────────────────────────────
  /// 22 / 28 · h1.
  static TextStyle h1(Color color) =>
      _ui(color: color, size: 22, height: 28, weight: FontWeight.w500, letterSpacing: -0.22);

  /// 17 / 22 · h2.
  static TextStyle h2(Color color) =>
      _ui(color: color, size: 17, height: 22, weight: FontWeight.w500);

  /// 15 / 22 · body.
  static TextStyle body(Color color) =>
      _ui(color: color, size: 15, height: 22, weight: FontWeight.w400);

  /// 13 / 18 · small support copy.
  static TextStyle small(Color color) =>
      _ui(color: color, size: 13, height: 18, weight: FontWeight.w400);

  /// 11 / 14 · uppercase section label. Caller adds `.toUpperCase()`.
  static TextStyle caption(Color color) =>
      _ui(color: color, size: 11, height: 14, weight: FontWeight.w500, letterSpacing: 0.66);

  /// A wider-tracked caption used for kickers above hero titles.
  static TextStyle kicker(Color color) =>
      _ui(color: color, size: 11, height: 14, weight: FontWeight.w500, letterSpacing: 1.98);

  /// A button label.
  static TextStyle button(Color color, {double size = 16}) =>
      _ui(color: color, size: size, height: size * 1.1, weight: FontWeight.w600, letterSpacing: -0.08);

  // ── Mono ──────────────────────────────────────────────────────
  /// Coordinates, timestamps, GMT offsets.
  static TextStyle mono(Color color, {double size = 12}) =>
      _mono(color: color, size: size);
}
