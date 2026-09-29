import 'package:flutter/material.dart';

/// Apple macOS system color palette (Human Interface Guidelines), with the
/// light- and dark-appearance variant of every hue plus the neutral
/// window / label / separator colors.
///
/// Use [MacOSColors.of] to pick the right variant for the current theme:
/// `MacOSColors.of(context).blue`.
@immutable
// Two const instances plus a context lookup — reads better as a class.
// ignore: use_enums
class MacOSColors {
  const MacOSColors._({
    required this.red,
    required this.orange,
    required this.yellow,
    required this.green,
    required this.mint,
    required this.teal,
    required this.cyan,
    required this.blue,
    required this.indigo,
    required this.purple,
    required this.pink,
    required this.brown,
    required this.gray,
    required this.windowBackground,
    required this.controlBackground,
    required this.underPageBackground,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.quaternaryLabel,
    required this.separator,
  });

  final Color red;
  final Color orange;
  final Color yellow;
  final Color green;
  final Color mint;
  final Color teal;
  final Color cyan;
  final Color blue;
  final Color indigo;
  final Color purple;
  final Color pink;
  final Color brown;
  final Color gray;

  /// Window / page background.
  final Color windowBackground;

  /// Background of content controls (lists, text fields, cards).
  final Color controlBackground;

  /// Area behind document pages.
  final Color underPageBackground;

  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color quaternaryLabel;
  final Color separator;

  /// The system hues in HIG order — handy for pickers and charts.
  List<Color> get hues => [
        red,
        orange,
        yellow,
        green,
        mint,
        teal,
        cyan,
        blue,
        indigo,
        purple,
        pink,
        brown,
        gray,
      ];

  /// A stable, colorful hue for [key] (e.g. a space or category name) —
  /// the same key always maps to the same color. Skips gray.
  Color hueFor(String key) {
    final colors = hues.sublist(0, hues.length - 1);
    final hash =
        key.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    return colors[hash % colors.length];
  }

  static const light = MacOSColors._(
    red: Color(0xFFFF3B30),
    orange: Color(0xFFFF9500),
    yellow: Color(0xFFFFCC00),
    green: Color(0xFF28CD41),
    mint: Color(0xFF00C7BE),
    teal: Color(0xFF59ADC4),
    cyan: Color(0xFF55BEF0),
    blue: Color(0xFF007AFF),
    indigo: Color(0xFF5856D6),
    purple: Color(0xFFAF52DE),
    pink: Color(0xFFFF2D55),
    brown: Color(0xFFA2845E),
    gray: Color(0xFF8E8E93),
    windowBackground: Color(0xFFECECEC),
    controlBackground: Color(0xFFFFFFFF),
    underPageBackground: Color(0xFFE3E3E3),
    label: Color(0xD9000000), // black @ 85%
    secondaryLabel: Color(0x80000000), // black @ 50%
    tertiaryLabel: Color(0x42000000), // black @ 26%
    quaternaryLabel: Color(0x1A000000), // black @ 10%
    separator: Color(0x1A000000),
  );

  static const dark = MacOSColors._(
    red: Color(0xFFFF453A),
    orange: Color(0xFFFF9F0A),
    yellow: Color(0xFFFFD60A),
    green: Color(0xFF32D74B),
    mint: Color(0xFF66D4CF),
    teal: Color(0xFF6AC4DC),
    cyan: Color(0xFF5AC8F5),
    blue: Color(0xFF0A84FF),
    indigo: Color(0xFF5E5CE6),
    purple: Color(0xFFBF5AF2),
    pink: Color(0xFFFF375F),
    brown: Color(0xFFAC8E68),
    gray: Color(0xFF98989D),
    windowBackground: Color(0xFF323232),
    controlBackground: Color(0xFF1E1E1E),
    underPageBackground: Color(0xFF282828),
    label: Color(0xD9FFFFFF), // white @ 85%
    secondaryLabel: Color(0x8CFFFFFF), // white @ 55%
    tertiaryLabel: Color(0x40FFFFFF), // white @ 25%
    quaternaryLabel: Color(0x1AFFFFFF), // white @ 10%
    separator: Color(0x1AFFFFFF),
  );

  static MacOSColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
