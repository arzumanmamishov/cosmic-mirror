import 'package:flutter/material.dart';

/// Lively type ramp — **Instrument Serif** (italic display) × **Geist**
/// (UI) × **Geist Mono** (coordinates / timestamps).
///
/// All three families are bundled in `pubspec.yaml` under `assets/fonts/`
/// (not runtime-fetched) — exactly as the design handoff specifies. Geist
/// and Geist Mono are variable fonts; Flutter maps [FontWeight] onto their
/// `wght` axis.
///
/// Every method takes the resolved color so callers stay palette-driven:
/// `LivelyType.d2(p.textPrimary)`. Letter-spacing values are converted from
/// the design's `em` units to logical pixels at each size.
abstract final class LivelyType {
  static const String serif = 'InstrumentSerif';
  static const String ui = 'Geist';
  static const String monoFamily = 'GeistMono';

  // ── Display · Instrument Serif italic ──────────────────────────
  /// 56 / 60 · hero display.
  static TextStyle d1(Color color) => TextStyle(
        fontFamily: serif,
        fontStyle: FontStyle.italic,
        color: color,
        fontSize: 56,
        height: 60 / 56,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.12, // -0.02em
      );

  /// 42 / 46 · screen hero title.
  static TextStyle d2(Color color) => TextStyle(
        fontFamily: serif,
        fontStyle: FontStyle.italic,
        color: color,
        fontSize: 42,
        height: 46 / 42,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.63, // -0.015em
      );

  /// 32 / 36 · section hero title.
  static TextStyle d3(Color color) => TextStyle(
        fontFamily: serif,
        fontStyle: FontStyle.italic,
        color: color,
        fontSize: 32,
        height: 36 / 32,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32, // -0.01em
      );

  // ── UI · Geist ────────────────────────────────────────────────
  /// 22 / 28 · h1.
  static TextStyle h1(Color color) => TextStyle(
        fontFamily: ui,
        color: color,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.22,
      );

  /// 17 / 22 · h2.
  static TextStyle h2(Color color) => TextStyle(
        fontFamily: ui,
        color: color,
        fontSize: 17,
        height: 22 / 17,
        fontWeight: FontWeight.w500,
      );

  /// 15 / 22 · body.
  static TextStyle body(Color color) => TextStyle(
        fontFamily: ui,
        color: color,
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
      );

  /// 13 / 18 · small support copy.
  static TextStyle small(Color color) => TextStyle(
        fontFamily: ui,
        color: color,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
      );

  /// 11 / 14 · uppercase section label. Caller adds `.toUpperCase()`.
  static TextStyle caption(Color color) => TextStyle(
        fontFamily: ui,
        color: color,
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.66, // 0.06em
      );

  /// A wider-tracked caption used for kickers above hero titles.
  static TextStyle kicker(Color color) => TextStyle(
        fontFamily: ui,
        color: color,
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.98, // 0.18em
      );

  /// A button label.
  static TextStyle button(Color color, {double size = 16}) => TextStyle(
        fontFamily: ui,
        color: color,
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.08,
      );

  // ── Mono · Geist Mono ─────────────────────────────────────────
  /// Coordinates, timestamps, GMT offsets.
  static TextStyle mono(Color color, {double size = 12}) => TextStyle(
        fontFamily: monoFamily,
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.6,
      );
}
