import 'dart:math' as math;

import 'package:flutter/material.dart';

/// NatalChartWheel renders a circular natal chart in classic Western
/// astrology style:
///
///   * Outer ring: the 12 zodiac signs as labeled segments.
///   * Middle ring: the 12 house cusps as numbered wedges.
///   * Inner area: aspect lines between planets, color-coded by aspect type.
///   * Planet glyphs placed at their ecliptic longitudes.
///
/// The chart is rotated so the Ascendant (1st house cusp) sits at 9 o'clock,
/// matching the convention used by professional software.
class NatalChartWheel extends StatelessWidget {
  const NatalChartWheel({
    required this.planets,
    required this.houses,
    required this.aspects,
    super.key,
    this.size = 320,
    this.ringColor,
    this.aspectsVisible = true,
  });

  final List<Map<String, dynamic>> planets;
  final List<Map<String, dynamic>> houses;
  final List<Map<String, dynamic>> aspects;
  final double size;
  final Color? ringColor;
  final bool aspectsVisible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ChartPainter(
          planets: planets,
          houses: houses,
          aspects: aspectsVisible ? aspects : const [],
          ringColor: ringColor ?? scheme.outline,
          textColor: scheme.onSurface,
          mutedColor: scheme.onSurface.withValues(alpha: 0.5),
          surfaceColor: scheme.surface,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.planets,
    required this.houses,
    required this.aspects,
    required this.ringColor,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
  });

  final List<Map<String, dynamic>> planets;
  final List<Map<String, dynamic>> houses;
  final List<Map<String, dynamic>> aspects;
  final Color ringColor;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;

  // Zodiac sign symbols (Unicode astrological characters)
  static const _signGlyphs = [
    '♈', // Aries
    '♉', // Taurus
    '♊', // Gemini
    '♋', // Cancer
    '♌', // Leo
    '♍', // Virgo
    '♎', // Libra
    '♏', // Scorpio
    '♐', // Sagittarius
    '♑', // Capricorn
    '♒', // Aquarius
    '♓', // Pisces
  ];

  static const _signNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer',
    'Leo', 'Virgo', 'Libra', 'Scorpio',
    'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  // Planet symbols
  static const _planetGlyphs = {
    'Sun': '☉',
    'Moon': '☽',
    'Mercury': '☿',
    'Venus': '♀',
    'Mars': '♂',
    'Jupiter': '♃',
    'Saturn': '♄',
    'Uranus': '♅',
    'Neptune': '♆',
    'Pluto': '♇',
    'North Node': '☊',
    'Chiron': '⚷',
  };

  // Aspect colors keyed by type
  static const _aspectColors = {
    'conjunction': Color(0xFFE6EAF2),
    'sextile': Color(0xFF5ED39A),
    'square': Color(0xFFF07C82),
    'trine': Color(0xFF4DA3FF),
    'opposition': Color(0xFFE14B8A),
    'quincunx': Color(0xFFF2B66D),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 2;
    final signR = outerR - 22; // boundary between sign band and houses
    final houseR = signR - 36; // boundary between houses and aspect circle
    final innerR = houseR - 8;

    // Determine the Ascendant longitude for chart rotation. Falls back to 0
    // (Aries 0°) if no house data is available.
    final ascLongitude = _ascendantLongitude();

    _drawRings(canvas, center, outerR, signR, houseR);
    _drawSigns(canvas, center, signR, outerR, ascLongitude);
    _drawHouses(canvas, center, houseR, signR, ascLongitude);
    if (aspects.isNotEmpty) {
      _drawAspects(canvas, center, innerR, ascLongitude);
    }
    _drawPlanets(canvas, center, signR - 14, ascLongitude);
  }

  // ---- helpers ----

  double _ascendantLongitude() {
    if (houses.isEmpty) return 0;
    final h1 = houses.first;
    final sign = h1['sign'] as String? ?? 'Aries';
    final degree = (h1['degree'] as num?)?.toDouble() ?? 0.0;
    final signIndex = _signNames.indexOf(sign).clamp(0, 11);
    return _toRadians(signIndex * 30 + degree);
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  /// Maps an ecliptic longitude (radians, 0..2π) to the corresponding
  /// Flutter canvas angle so that the Ascendant sits at 9 o'clock and
  /// later longitudes progress counter-clockwise (visually).
  double _angle(double longitudeRad, double ascRad) {
    return math.pi - (longitudeRad - ascRad);
  }

  Offset _polar(Offset c, double r, double angle) =>
      Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));

  void _drawRings(
    Canvas canvas,
    Offset center,
    double outerR,
    double signR,
    double houseR,
  ) {
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, outerR, ringPaint);
    canvas.drawCircle(center, signR, ringPaint);
    canvas.drawCircle(center, houseR, ringPaint);

    // Subtle radial gradient fill in the very center
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          surfaceColor.withValues(alpha: 0.4),
          surfaceColor.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: houseR - 10),
      );
    canvas.drawCircle(center, houseR - 10, fillPaint);
  }

  void _drawSigns(
    Canvas canvas,
    Offset center,
    double innerR,
    double outerR,
    double ascRad,
  ) {
    final dividerPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final midR = (innerR + outerR) / 2;

    for (var i = 0; i < 12; i++) {
      final lonStart = _toRadians(i * 30.0);
      final angleStart = _angle(lonStart, ascRad);

      // Radial divider line between this sign and the next
      canvas.drawLine(
        _polar(center, innerR, angleStart),
        _polar(center, outerR, angleStart),
        dividerPaint,
      );

      // Sign glyph at the middle of the segment
      final lonMid = _toRadians(i * 30.0 + 15);
      final angleMid = _angle(lonMid, ascRad);
      final glyphPos = _polar(center, midR, angleMid);
      _drawText(
        canvas,
        _signGlyphs[i],
        glyphPos,
        color: textColor,
        size: 18,
      );
    }
  }

  void _drawHouses(
    Canvas canvas,
    Offset center,
    double innerR,
    double outerR,
    double ascRad,
  ) {
    final dividerPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final midR = (innerR + outerR) / 2;

    for (var i = 0; i < houses.length; i++) {
      final cusp = houses[i];
      final sign = cusp['sign'] as String? ?? 'Aries';
      final degree = (cusp['degree'] as num?)?.toDouble() ?? 0.0;
      final signIndex = _signNames.indexOf(sign).clamp(0, 11);
      final lonRad = _toRadians(signIndex * 30 + degree);
      final ang = _angle(lonRad, ascRad);

      // Cusp line: thicker for the four angles (1, 4, 7, 10)
      final houseNum = (cusp['number'] as int?) ?? (i + 1);
      final isAxis = houseNum == 1 || houseNum == 4 ||
          houseNum == 7 || houseNum == 10;
      dividerPaint.strokeWidth = isAxis ? 1.6 : 0.8;
      dividerPaint.color = isAxis
          ? ringColor.withValues(alpha: 0.85)
          : ringColor.withValues(alpha: 0.45);

      canvas.drawLine(
        _polar(center, innerR, ang),
        _polar(center, outerR, ang),
        dividerPaint,
      );

      // House number placed in the middle of this house wedge.
      // Find the next cusp longitude to compute the wedge midpoint.
      final next = houses[(i + 1) % houses.length];
      final nextSign = next['sign'] as String? ?? 'Aries';
      final nextDeg = (next['degree'] as num?)?.toDouble() ?? 0.0;
      final nextSignIdx = _signNames.indexOf(nextSign).clamp(0, 11);
      var nextLon = _toRadians(nextSignIdx * 30 + nextDeg);
      // Handle wrap so the midpoint is inside the house, not opposite
      var span = nextLon - lonRad;
      if (span <= 0) span += 2 * math.pi;
      final midLon = lonRad + span / 2;
      final midAngle = _angle(midLon, ascRad);
      final labelPos = _polar(center, midR, midAngle);
      _drawText(
        canvas,
        '$houseNum',
        labelPos,
        color: mutedColor,
        size: 11,
        weight: FontWeight.w600,
      );
    }
  }

  void _drawAspects(
    Canvas canvas,
    Offset center,
    double radius,
    double ascRad,
  ) {
    for (final aspect in aspects) {
      final type = aspect['type'] as String? ?? '';
      final p1Name = aspect['planet1'] as String? ?? '';
      final p2Name = aspect['planet2'] as String? ?? '';
      final p1Lon = _planetLongitude(p1Name);
      final p2Lon = _planetLongitude(p2Name);
      if (p1Lon == null || p2Lon == null) continue;

      final color = _aspectColors[type] ?? mutedColor;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final pos1 = _polar(center, radius, _angle(p1Lon, ascRad));
      final pos2 = _polar(center, radius, _angle(p2Lon, ascRad));
      canvas.drawLine(pos1, pos2, paint);
    }
  }

  /// Returns the absolute zodiac longitude (radians) of the given planet,
  /// or null if it isn't in the planets list.
  double? _planetLongitude(String name) {
    for (final p in planets) {
      if ((p['name'] as String?) == name) {
        final sign = p['sign'] as String? ?? 'Aries';
        final deg = (p['degree'] as num?)?.toDouble() ?? 0.0;
        final idx = _signNames.indexOf(sign).clamp(0, 11);
        return _toRadians(idx * 30 + deg);
      }
    }
    return null;
  }

  void _drawPlanets(
    Canvas canvas,
    Offset center,
    double radius,
    double ascRad,
  ) {
    // Sort planets by longitude so we can detect collisions and offset
    final sortedPlanets = [...planets]..sort((a, b) {
        return (_planetLongitude(a['name'] as String) ?? 0)
            .compareTo(_planetLongitude(b['name'] as String) ?? 0);
      });

    double? prevDeg;
    var stack = 0; // how many overlapping planets we've already offset

    for (final p in sortedPlanets) {
      final name = p['name'] as String? ?? '';
      final glyph = _planetGlyphs[name];
      if (glyph == null) continue;
      final lon = _planetLongitude(name);
      if (lon == null) continue;
      final lonDeg = lon * 180 / math.pi;

      // If two planets are within 5° of each other, push the second one
      // slightly inward to avoid glyph overlap.
      if (prevDeg != null && (lonDeg - prevDeg).abs() < 6) {
        stack += 1;
      } else {
        stack = 0;
      }
      prevDeg = lonDeg;

      final r = radius - stack * 18;
      final ang = _angle(lon, ascRad);
      final pos = _polar(center, r, ang);

      // Background disc behind glyph for legibility
      final discPaint = Paint()..color = surfaceColor;
      canvas.drawCircle(pos, 11, discPaint);
      _drawText(
        canvas,
        glyph,
        pos,
        color: textColor,
        size: 16,
        weight: FontWeight.w500,
      );

      // Retrograde mark
      if ((p['retrograde'] as bool?) ?? false) {
        _drawText(
          canvas,
          'R',
          Offset(pos.dx + 9, pos.dy + 9),
          color: const Color(0xFFF2B66D),
          size: 8,
          weight: FontWeight.w700,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    required Color color,
    double size = 12,
    FontWeight weight = FontWeight.w500,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = position - Offset(tp.width / 2, tp.height / 2);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ChartPainter old) {
    return old.planets != planets ||
        old.houses != houses ||
        old.aspects != aspects ||
        old.ringColor != ringColor ||
        old.textColor != textColor;
  }
}
