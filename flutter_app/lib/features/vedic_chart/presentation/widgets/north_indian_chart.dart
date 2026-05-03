import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/vedic_chart.dart';
import 'package:flutter/material.dart';

/// North Indian-style Vedic Kundli chart.
///
/// Layout (square divided into 12 cells):
///   - Outer square frame
///   - Two diagonals (corner to corner) intersecting at center
///   - Lines connecting midpoints of opposite sides (forming an inner diamond)
///
/// House numbering goes counter-clockwise from the top inner-diamond cell:
///   H1  top inner diamond
///   H2  top-left, upper sub-triangle (adjacent to top edge)
///   H3  top-left, lower sub-triangle (adjacent to left edge)
///   H4  left inner diamond
///   H5  bottom-left, upper sub-triangle (adjacent to left edge)
///   H6  bottom-left, lower sub-triangle (adjacent to bottom edge)
///   H7  bottom inner diamond
///   H8  bottom-right, lower sub-triangle (adjacent to bottom edge)
///   H9  bottom-right, upper sub-triangle (adjacent to right edge)
///   H10 right inner diamond
///   H11 top-right, lower sub-triangle (adjacent to right edge)
///   H12 top-right, upper sub-triangle (adjacent to top edge)
///
/// In Vedic convention, House 1 is fixed at the top — signs rotate based on
/// the Lagna (1st house always shows the Ascendant's sign).
class NorthIndianChart extends StatelessWidget {
  const NorthIndianChart({
    required this.chart,
    this.size = 320,
    this.onHouseTap,
    super.key,
  });

  final VedicChart chart;
  final double size;
  final ValueChanged<int>? onHouseTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onTapUp: onHouseTap == null
            ? null
            : (details) {
                final house = _houseAt(
                  details.localPosition,
                  size,
                );
                if (house != null) onHouseTap!(house);
              },
        child: CustomPaint(
          size: Size(size, size),
          painter: _NorthIndianPainter(
            chart: chart,
            frameColor: p.glassBorder,
            lineColor: p.textTertiary,
            primary: p.primary,
            accent: p.accent,
            textPrimary: p.textPrimary,
            textSecondary: p.textSecondary,
            highlight: p.gold,
          ),
        ),
      ),
    );
  }

  /// Returns the 1..12 house number at the given local point, or null.
  int? _houseAt(Offset p, double s) {
    final n = Offset(p.dx / s, p.dy / s);
    for (var h = 1; h <= 12; h++) {
      if (_pointInPolygon(n, _houseCells[h]!)) return h;
    }
    return null;
  }

  bool _pointInPolygon(Offset p, List<Offset> poly) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final pi = poly[i];
      final pj = poly[j];
      if (((pi.dy > p.dy) != (pj.dy > p.dy)) &&
          (p.dx <
              (pj.dx - pi.dx) * (p.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx)) {
        inside = !inside;
      }
    }
    return inside;
  }
}

class _NorthIndianPainter extends CustomPainter {
  _NorthIndianPainter({
    required this.chart,
    required this.frameColor,
    required this.lineColor,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.highlight,
  });

  final VedicChart chart;
  final Color frameColor;
  final Color lineColor;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final innerPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Outer square + 2. Two diagonals
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, s, s), framePaint)
      ..drawLine(Offset.zero, Offset(s, s), innerPaint)
      ..drawLine(Offset(s, 0), Offset(0, s), innerPaint);

    // 3. Inner diamond (connect midpoints of opposite sides)
    final tMid = Offset(s / 2, 0);
    final rMid = Offset(s, s / 2);
    final bMid = Offset(s / 2, s);
    final lMid = Offset(0, s / 2);
    final diamond = Path()
      ..moveTo(tMid.dx, tMid.dy)
      ..lineTo(rMid.dx, rMid.dy)
      ..lineTo(bMid.dx, bMid.dy)
      ..lineTo(lMid.dx, lMid.dy)
      ..close();
    canvas.drawPath(diamond, innerPaint);

    // 4. House numbers + sign labels (small, in a corner of each cell)
    _drawCellLabels(canvas, s);

    // 5. Planet glyphs (centered in each cell, multiple stacked vertically)
    _drawPlanets(canvas, s);
  }

  void _drawCellLabels(Canvas canvas, double s) {
    // Determine which sign is in House 1 (the Ascendant) — every other house's
    // sign rolls forward in the zodiac from that point (Whole Sign).
    final ascSignIdx = _signIndexOf(chart.lagna.sign);
    for (var h = 1; h <= 12; h++) {
      final signIdx = (ascSignIdx + h - 1) % 12;
      final signAbbr = _signAbbrev[signIdx];
      final pos = _labelAnchors[h]!;
      _paintText(
        canvas,
        signAbbr,
        Offset(pos.dx * s, pos.dy * s),
        color: highlight.withValues(alpha: 0.85),
        size: 10,
        weight: FontWeight.w600,
      );
    }
  }

  void _drawPlanets(Canvas canvas, double s) {
    // Group planets by house; render each as a small glyph stacked.
    final grouped = <int, List<VedicPlanetPlacement>>{};
    for (final p in chart.planets) {
      grouped.putIfAbsent(p.house, () => []).add(p);
    }
    for (final entry in grouped.entries) {
      final house = entry.key;
      final planets = entry.value;
      final center = _planetAnchors[house]!;
      var dy = -(planets.length - 1) * 7;
      for (final p in planets) {
        final glyph = _planetAbbrev[p.name] ?? p.name.substring(0, 2);
        final color = p.combust
            ? textSecondary
            : (p.retrograde ? accent : textPrimary);
        final label = p.retrograde ? '$glyph(R)' : glyph;
        _paintText(
          canvas,
          label,
          Offset(center.dx * s, center.dy * s + dy),
          color: color,
          size: 11,
          weight: FontWeight.w700,
        );
        dy += 14;
      }
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required double size,
    required FontWeight weight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _NorthIndianPainter old) =>
      old.chart != chart ||
      old.primary != primary ||
      old.textPrimary != textPrimary;
}

// ---------- geometry constants ----------
//
// Outer square has corners TL(0,0), TR(1,0), BR(1,1), BL(0,1).
// The inner diamond has vertices at the midpoints of the four outer sides:
// topMid, rightMid, bottomMid, leftMid. The two outer diagonals each hit
// exactly one diamond side at a 0.25-offset point.
const Offset _topMid = Offset(0.5, 0);
const Offset _rightMid = Offset(1, 0.5);
const Offset _bottomMid = Offset(0.5, 1);
const Offset _leftMid = Offset(0, 0.5);
const Offset _center = Offset(0.5, 0.5);
// Outer-diagonal × diamond-side intersections.
const Offset _ltHit = Offset(0.25, 0.25); // on left-top side, from TL-BR
const Offset _trHit = Offset(0.75, 0.25); // on top-right side, from TR-BL
const Offset _rbHit = Offset(0.75, 0.75); // on right-bottom side, from TL-BR
const Offset _blHit = Offset(0.25, 0.75); // on bottom-left side, from TR-BL
const Offset _tlCorner = Offset.zero;
const Offset _trCorner = Offset(1, 0);
const Offset _brCorner = Offset(1, 1);
const Offset _blCorner = Offset(0, 1);

/// 12 cell polygons in unit-square coordinates. Vertices listed clockwise.
/// House 1 = top inner-diamond cell. See widget docs for the full mapping.
const Map<int, List<Offset>> _houseCells = {
  // Inner-diamond cells (4 quadrants of the diamond around the center)
  1: [_topMid, _trHit, _center, _ltHit],
  4: [_leftMid, _ltHit, _center, _blHit],
  7: [_bottomMid, _blHit, _center, _rbHit],
  10: [_rightMid, _rbHit, _center, _trHit],
  // Corner sub-triangles — each outer corner is split in half by the
  // diagonal from that corner to the center.
  2: [_tlCorner, _topMid, _ltHit], // TL corner, upper half (adjacent top edge)
  3: [_tlCorner, _ltHit, _leftMid], // TL corner, lower half (adjacent left)
  5: [_leftMid, _blHit, _blCorner], // BL upper (adjacent left)
  6: [_blCorner, _blHit, _bottomMid], // BL lower (adjacent bottom)
  8: [_bottomMid, _rbHit, _brCorner], // BR lower (adjacent bottom)
  9: [_brCorner, _rbHit, _rightMid], // BR upper (adjacent right)
  11: [_rightMid, _trHit, _trCorner], // TR lower (adjacent right)
  12: [_trCorner, _trHit, _topMid], // TR upper (adjacent top)
};

/// Approximate centroid of each house cell (where planet glyphs render).
/// Computed as the average of the cell's vertices.
const Map<int, Offset> _planetAnchors = {
  1: Offset(0.5, 0.25),
  2: Offset(0.25, 0.08),
  3: Offset(0.08, 0.25),
  4: Offset(0.25, 0.5),
  5: Offset(0.08, 0.75),
  6: Offset(0.25, 0.92),
  7: Offset(0.5, 0.75),
  8: Offset(0.75, 0.92),
  9: Offset(0.92, 0.75),
  10: Offset(0.75, 0.5),
  11: Offset(0.92, 0.25),
  12: Offset(0.75, 0.08),
};

/// Where to place the small sign-abbreviation label per house cell.
/// Slightly offset from the planet centroid so they don't overlap.
const Map<int, Offset> _labelAnchors = {
  1: Offset(0.5, 0.06),
  2: Offset(0.16, 0.045),
  3: Offset(0.045, 0.16),
  4: Offset(0.06, 0.5),
  5: Offset(0.045, 0.84),
  6: Offset(0.16, 0.955),
  7: Offset(0.5, 0.94),
  8: Offset(0.84, 0.955),
  9: Offset(0.955, 0.84),
  10: Offset(0.94, 0.5),
  11: Offset(0.955, 0.16),
  12: Offset(0.84, 0.045),
};

const _signOrder = [
  'Aries',
  'Taurus',
  'Gemini',
  'Cancer',
  'Leo',
  'Virgo',
  'Libra',
  'Scorpio',
  'Sagittarius',
  'Capricorn',
  'Aquarius',
  'Pisces',
];

const _signAbbrev = [
  'Ar', 'Ta', 'Ge', 'Cn',
  'Le', 'Vi', 'Li', 'Sc',
  'Sg', 'Cp', 'Aq', 'Pi',
];

int _signIndexOf(String name) {
  final i = _signOrder.indexOf(name);
  return i < 0 ? 0 : i;
}

const _planetAbbrev = {
  'Sun': 'Su',
  'Moon': 'Mo',
  'Mars': 'Ma',
  'Mercury': 'Me',
  'Jupiter': 'Ju',
  'Venus': 'Ve',
  'Saturn': 'Sa',
  'Rahu': 'Ra',
  'Ketu': 'Ke',
};
