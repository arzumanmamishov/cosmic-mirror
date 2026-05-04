import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:flutter/material.dart';

/// The iconic Human Design body graph — 9 energy centers laid out vertically
/// with their gates dotted around the perimeter and defined channels drawn
/// as lines connecting them.
///
/// Defined centers are filled with the center's signature color; undefined
/// centers are outline-only. Active gates are drawn as small filled dots,
/// inactive gates as faint outlines. Defined channels are highlighted as
/// solid colored lines; undefined channels are not drawn at all.
class BodyGraph extends StatelessWidget {
  const BodyGraph({required this.chart, this.size = 320, super.key});

  final HumanDesignChart chart;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size * 1.5, // body graph is taller than wide
      child: CustomPaint(
        size: Size(size, size * 1.5),
        painter: _BodyGraphPainter(
          chart: chart,
          surface: p.surface,
          surfaceElevated: p.surfaceElevated,
          glassBorder: p.glassBorder,
          textPrimary: p.textPrimary,
          textTertiary: p.textTertiary,
        ),
      ),
    );
  }
}

class _BodyGraphPainter extends CustomPainter {
  _BodyGraphPainter({
    required this.chart,
    required this.surface,
    required this.surfaceElevated,
    required this.glassBorder,
    required this.textPrimary,
    required this.textTertiary,
  });

  final HumanDesignChart chart;
  final Color surface;
  final Color surfaceElevated;
  final Color glassBorder;
  final Color textPrimary;
  final Color textTertiary;

  // Hardcoded center colors per HD convention.
  static const Map<String, Color> _centerColors = {
    'Head': Color(0xFFEAC75A), // yellow
    'Ajna': Color(0xFF65B158), // green
    'Throat': Color(0xFF8B7DC3), // muted violet
    'G': Color(0xFFE8B557), // gold/yellow
    'Heart': Color(0xFFE45A5A), // red
    'Sacral': Color(0xFFE45A5A), // red
    'SolarPlexus': Color(0xFFC56AB6), // pink-purple
    'Spleen': Color(0xFF7BB68A), // sage green
    'Root': Color(0xFFB87333), // brown/copper
  };

  // Each center's center-position in unit square (x, y in [0, 1]).
  // The body graph is taller than wide; we use y in [0, 1.5]-equivalent
  // by treating size.height = size.width * 1.5 in the paint() method.
  static const Map<String, Offset> _centerPositions = {
    'Head': Offset(0.50, 0.07),
    'Ajna': Offset(0.50, 0.20),
    'Throat': Offset(0.50, 0.34),
    'G': Offset(0.50, 0.52),
    'Heart': Offset(0.68, 0.52),
    'Spleen': Offset(0.18, 0.66),
    'Sacral': Offset(0.50, 0.69),
    'SolarPlexus': Offset(0.82, 0.66),
    'Root': Offset(0.50, 0.88),
  };

  static const Map<String, double> _centerSizes = {
    'Head': 0.16, 'Ajna': 0.16, 'Throat': 0.18, 'G': 0.16,
    'Heart': 0.13, 'Spleen': 0.18, 'Sacral': 0.18, 'SolarPlexus': 0.18,
    'Root': 0.18,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Build active gate map — a gate is "active" if any activation references it.
    final activeGates = <int>{for (final g in chart.gates) g.gate};

    // Build defined-centers map.
    final definedCenters = <String, bool>{
      for (final c in chart.centers) c.name: c.defined,
    };

    // 1) Draw channels first (so centers sit on top of them).
    final channelPaint = Paint()..strokeWidth = 3 ..strokeCap = StrokeCap.round;
    for (final ch in chart.channels) {
      if (ch.centers.length < 2) continue;
      final a = _centerPositions[ch.centers[0]];
      final b = _centerPositions[ch.centers[1]];
      if (a == null || b == null) continue;
      final color = _centerColors[ch.centers[0]] ?? glassBorder;
      channelPaint.color = color;
      canvas.drawLine(
        Offset(a.dx * w, a.dy * h),
        Offset(b.dx * w, b.dy * h),
        channelPaint,
      );
    }

    // 2) Draw the centers.
    for (final centerName in _centerPositions.keys) {
      final pos = _centerPositions[centerName]!;
      final radius = (_centerSizes[centerName] ?? 0.16) * w / 2;
      final cx = pos.dx * w;
      final cy = pos.dy * h;
      final color = _centerColors[centerName] ?? glassBorder;
      final defined = definedCenters[centerName] ?? false;

      _drawCenterShape(
        canvas, centerName, cx, cy, radius,
        color: color, defined: defined,
        outlineColor: defined ? color : glassBorder,
      );

      // Center label inside the shape.
      _paintText(
        canvas,
        _shortLabel(centerName),
        Offset(cx, cy),
        color: defined ? Colors.white : textTertiary,
        size: 9,
        weight: FontWeight.w800,
      );
    }

    // 3) Draw gate dots near each center showing active gates.
    for (final c in chart.centers) {
      final pos = _centerPositions[c.name];
      if (pos == null) continue;
      final radius = (_centerSizes[c.name] ?? 0.16) * w / 2 + 12;
      final cx = pos.dx * w;
      final cy = pos.dy * h;
      final activeForCenter = c.gates.where(activeGates.contains).toList();
      if (activeForCenter.isEmpty) continue;

      // Distribute around the center perimeter.
      final n = activeForCenter.length;
      for (var i = 0; i < n; i++) {
        final theta = (i / n) * 2 * math.pi;
        final dotX = cx + radius * math.cos(theta);
        final dotY = cy + radius * math.sin(theta);
        final dotPaint = Paint()..color = _centerColors[c.name] ?? glassBorder;
        canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
        _paintText(
          canvas,
          '${activeForCenter[i]}',
          Offset(dotX, dotY),
          color: Colors.white,
          size: 7,
          weight: FontWeight.w800,
        );
      }
    }
  }

  /// _drawCenterShape paints the right shape per center: triangle for Head,
  /// inverted triangle for Ajna, diamond for G, square for everything else.
  void _drawCenterShape(
    Canvas canvas,
    String name,
    double cx,
    double cy,
    double radius, {
    required Color color,
    required bool defined,
    required Color outlineColor,
  }) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = outlineColor;
    fillPaint.color = defined ? color : surface;

    final path = Path();
    switch (name) {
      case 'Head': // upright triangle
        path
          ..moveTo(cx, cy - radius)
          ..lineTo(cx + radius, cy + radius * 0.7)
          ..lineTo(cx - radius, cy + radius * 0.7)
          ..close();
      case 'Ajna': // inverted triangle
        path
          ..moveTo(cx - radius, cy - radius * 0.7)
          ..lineTo(cx + radius, cy - radius * 0.7)
          ..lineTo(cx, cy + radius)
          ..close();
      case 'G': // diamond
        path
          ..moveTo(cx, cy - radius)
          ..lineTo(cx + radius, cy)
          ..lineTo(cx, cy + radius)
          ..lineTo(cx - radius, cy)
          ..close();
      default: // square (Throat, Heart, Sacral, Spleen, SolarPlexus, Root)
        path.addRect(Rect.fromCenter(
          center: Offset(cx, cy),
          width: radius * 2,
          height: radius * 2,
        ));
    }
    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, strokePaint);
  }

  String _shortLabel(String name) {
    switch (name) {
      case 'SolarPlexus':
        return 'Solar';
      case 'Heart':
        return 'Heart';
      case 'Sacral':
        return 'Sacral';
      case 'Spleen':
        return 'Spleen';
      default:
        return name;
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
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BodyGraphPainter old) =>
      old.chart != chart;
}

