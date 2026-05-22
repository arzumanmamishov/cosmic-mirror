import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:flutter/material.dart';

/// The Human Design BodyGraph — the nine energy centers in their canonical
/// shapes, positions and colors, the 64 gates rendered inside, and the
/// defined channels drawn as thick white ribbons.
///
/// Visual conventions:
///   - Defined center   → filled with the center's signature color.
///   - Undefined center → hollow (surface fill + hairline outline).
///   - Defined channel  → solid white ribbon between its two gates.
///   - Gate number      → white inside a defined center; faint inside an
///                        undefined one; active gates render brighter.
class BodyGraph extends StatelessWidget {
  const BodyGraph({required this.chart, this.size = 320, super.key});

  final HumanDesignChart chart;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Content aspect of a standard BodyGraph — taller than wide.
    final h = size * 1.6;
    return SizedBox(
      width: size,
      height: h,
      child: CustomPaint(
        size: Size(size, h),
        painter: _BodyGraphPainter(
          chart: chart,
          surface: p.surface,
          glassBorder: p.glassBorder,
          textPrimary: p.textPrimary,
          textMuted: p.textMuted,
        ),
      ),
    );
  }
}

class _BodyGraphPainter extends CustomPainter {
  _BodyGraphPainter({
    required this.chart,
    required this.surface,
    required this.glassBorder,
    required this.textPrimary,
    required this.textMuted,
  });

  final HumanDesignChart chart;
  final Color surface;
  final Color glassBorder;
  final Color textPrimary;
  final Color textMuted;

  // ===== Center signature colors — canonical Human Design palette. =====
  static const Map<String, Color> _centerColors = {
    'Head': Color(0xFFF2B43C), // golden amber
    'Ajna': Color(0xFF2F5E3F), // dark pine green
    'Throat': Color(0xFFBF5226), // burnt terracotta
    'G': Color(0xFFC99A2C), // ochre / mustard gold
    'Heart': Color(0xFFD62D6B), // raspberry magenta
    'Sacral': Color(0xFFDA615F), // coral red
    'SolarPlexus': Color(0xFF7CA23C), // olive green
    'Spleen': Color(0xFF2E5D50), // dark teal
    'Root': Color(0xFFA8431F), // rust / brick
  };

  // ===== Center positions (fractional w, h where h = 1.6w) =====
  static const Map<String, Offset> _centerPositions = {
    'Head': Offset(0.50, 0.075),
    'Ajna': Offset(0.50, 0.20),
    'Throat': Offset(0.50, 0.37),
    'G': Offset(0.50, 0.55),
    'Heart': Offset(0.70, 0.62),
    'Spleen': Offset(0.15, 0.76),
    'Sacral': Offset(0.50, 0.765),
    'SolarPlexus': Offset(0.85, 0.765),
    'Root': Offset(0.50, 0.925),
  };

  // Center sizes (fraction of chart width).
  static const Map<String, double> _centerSizes = {
    'Head': 0.20, 'Ajna': 0.22, 'Throat': 0.28, 'G': 0.22,
    'Heart': 0.18, 'Spleen': 0.24, 'Sacral': 0.24, 'SolarPlexus': 0.24,
    'Root': 0.24,
  };

  // ===== Per-center gate positions (interior, unit-radius from center) =====
  static const Map<String, Map<int, Offset>> _gateOffsets = {
    'Head': {
      64: Offset(-0.45, 0.50),
      61: Offset(0.00, 0.55),
      63: Offset(0.45, 0.50),
    },
    'Ajna': {
      47: Offset(-0.45, -0.50),
      24: Offset(0.00, -0.55),
      4: Offset(0.45, -0.50),
      17: Offset(-0.40, -0.05),
      11: Offset(0.40, -0.05),
      43: Offset(0.00, 0.50),
    },
    'Throat': {
      62: Offset(-0.60, -0.70),
      23: Offset(0.00, -0.70),
      56: Offset(0.60, -0.70),
      16: Offset(-0.75, -0.30),
      35: Offset(0.75, -0.30),
      20: Offset(-0.75, 0.30),
      12: Offset(0.75, 0.30),
      31: Offset(-0.60, 0.70),
      8: Offset(-0.20, 0.70),
      33: Offset(0.20, 0.70),
      45: Offset(0.60, 0.70),
    },
    'G': {
      1: Offset(0.00, -0.55),
      7: Offset(-0.35, -0.35),
      13: Offset(0.35, -0.35),
      10: Offset(-0.55, 0.00),
      25: Offset(0.55, 0.00),
      15: Offset(-0.35, 0.35),
      46: Offset(0.35, 0.35),
      2: Offset(0.00, 0.55),
    },
    'Heart': {
      21: Offset(-0.20, -0.30),
      51: Offset(0.20, -0.30),
      26: Offset(-0.40, 0.30),
      40: Offset(0.40, 0.30),
    },
    'Sacral': {
      5: Offset(-0.55, -0.70),
      14: Offset(0.00, -0.70),
      29: Offset(0.55, -0.70),
      34: Offset(-0.75, -0.35),
      59: Offset(0.75, -0.35),
      27: Offset(-0.70, 0.40),
      42: Offset(-0.40, 0.70),
      3: Offset(0.00, 0.70),
      9: Offset(0.40, 0.70),
    },
    'Spleen': {
      48: Offset(-0.35, -0.55),
      57: Offset(-0.40, -0.10),
      44: Offset(-0.35, 0.55),
      50: Offset(0.05, -0.40),
      32: Offset(0.45, 0),
      28: Offset(0.05, 0.40),
      18: Offset(-0.30, 0.20),
    },
    'SolarPlexus': {
      36: Offset(0.35, -0.55),
      22: Offset(0.40, -0.10),
      37: Offset(0.35, 0.55),
      6: Offset(-0.45, 0),
      49: Offset(-0.05, -0.40),
      55: Offset(-0.05, 0.40),
      30: Offset(0.30, 0.20),
    },
    'Root': {
      53: Offset(-0.55, -0.70),
      60: Offset(0.00, -0.70),
      52: Offset(0.55, -0.70),
      54: Offset(-0.75, -0.35),
      19: Offset(0.75, -0.35),
      38: Offset(-0.65, 0.30),
      39: Offset(0.65, 0.30),
      58: Offset(-0.25, 0.70),
      41: Offset(0.25, 0.70),
    },
  };

  // ===== Gate → home center map (built from _gateOffsets) =====
  static final Map<int, String> _gateToCenter = () {
    final m = <int, String>{};
    _gateOffsets.forEach((center, gates) {
      gates.forEach((gate, _) => m[gate] = center);
    });
    return m;
  }();

  // ===== All 36 channels (canonical) for hanging-gate detection =====
  static const List<(int, int)> _allChannels = [
    (1, 8), (2, 14), (3, 60), (4, 63), (5, 15), (6, 59), (7, 31),
    (9, 52), (10, 20), (10, 34), (10, 57), (11, 56), (12, 22),
    (13, 33), (16, 48), (17, 62), (18, 58), (19, 49), (20, 34),
    (20, 57), (21, 45), (23, 43), (24, 61), (25, 51), (26, 44),
    (27, 50), (28, 38), (29, 46), (30, 41), (32, 54), (34, 57),
    (35, 36), (37, 40), (39, 55), (42, 53), (47, 64),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Active gates.
    final personalityGates = <int>{};
    final designGates = <int>{};
    for (final g in chart.gates) {
      if (g.isPersonality) {
        personalityGates.add(g.gate);
      } else {
        designGates.add(g.gate);
      }
    }
    final activeGates = personalityGates.union(designGates);

    final definedChannelKeys = <(int, int)>{
      for (final ch in chart.channels)
        ch.gate1 < ch.gate2 ? (ch.gate1, ch.gate2) : (ch.gate2, ch.gate1),
    };

    final definedCenters = <String, bool>{
      for (final c in chart.centers) c.name: c.defined,
    };

    // 1) Hanging-gate stubs (one-sided activations) — faint, behind.
    _drawHangingStubs(canvas, w, h, activeGates, definedChannelKeys);
    // 2) Defined channels — thick white ribbons.
    _drawDefinedChannels(canvas, w, h);
    // 3) The nine centers.
    _drawCenters(canvas, w, h, definedCenters);
    // 4) Gate numbers.
    _drawGates(canvas, w, h, definedCenters, activeGates);
  }

  // ===== Hanging-gate stubs — short white nub from an active gate toward
  // its (inactive) channel partner. Faint so defined channels dominate.
  void _drawHangingStubs(
    Canvas canvas,
    double w,
    double h,
    Set<int> activeGates,
    Set<(int, int)> definedChannelKeys,
  ) {
    final stubPaint = Paint()
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.28);

    for (final ch in _allChannels) {
      final aActive = activeGates.contains(ch.$1);
      final bActive = activeGates.contains(ch.$2);
      if (aActive == bActive) continue;
      if (definedChannelKeys.contains(ch)) continue;

      final (activeGate, partnerGate) =
          aActive ? (ch.$1, ch.$2) : (ch.$2, ch.$1);
      final activePos = _gatePixelPos(activeGate, w, h);
      final partnerCenter = _gateToCenter[partnerGate];
      if (activePos == null || partnerCenter == null) continue;

      final partnerCenterPos = _centerPixelPos(partnerCenter, w, h);
      final stubEnd = Offset(
        activePos.dx + (partnerCenterPos.dx - activePos.dx) * 0.32,
        activePos.dy + (partnerCenterPos.dy - activePos.dy) * 0.32,
      );
      canvas.drawLine(activePos, stubEnd, stubPaint);
    }
  }

  // ===== Defined channels — straight thick white ribbons =====
  void _drawDefinedChannels(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    for (final ch in chart.channels) {
      final start = _gatePixelPos(ch.gate1, w, h);
      final end = _gatePixelPos(ch.gate2, w, h);
      if (start == null || end == null) continue;
      canvas.drawLine(start, end, paint);
    }
  }

  // ===== The nine centers =====
  void _drawCenters(
    Canvas canvas,
    double w,
    double h,
    Map<String, bool> definedCenters,
  ) {
    for (final entry in _centerPositions.entries) {
      final name = entry.key;
      final pos = entry.value;
      final radius = (_centerSizes[name] ?? 0.16) * w / 2;
      final cx = pos.dx * w;
      final cy = pos.dy * h;
      final defined = definedCenters[name] ?? false;
      final color = _centerColors[name] ?? glassBorder;

      _drawCenterShape(
        canvas,
        name,
        cx,
        cy,
        radius,
        fillColor: defined ? color : surface,
        outlineColor:
            defined ? color : glassBorder.withValues(alpha: 0.8),
      );
    }
  }

  // ===== Center shape paths — canonical HD orientations, rounded corners =====
  void _drawCenterShape(
    Canvas canvas,
    String name,
    double cx,
    double cy,
    double radius, {
    required Color fillColor,
    required Color outlineColor,
  }) {
    final cornerR = radius * 0.16;

    Path path;
    switch (name) {
      case 'Head': // triangle pointing UP
        path = _roundedPolygon(
          [
            Offset(cx, cy - radius),
            Offset(cx + radius, cy + radius * 0.7),
            Offset(cx - radius, cy + radius * 0.7),
          ],
          cornerR,
        );
      case 'Ajna': // triangle pointing DOWN
        path = _roundedPolygon(
          [
            Offset(cx - radius, cy - radius * 0.7),
            Offset(cx + radius, cy - radius * 0.7),
            Offset(cx, cy + radius),
          ],
          cornerR,
        );
      case 'G': // diamond
        path = _roundedPolygon(
          [
            Offset(cx, cy - radius),
            Offset(cx + radius, cy),
            Offset(cx, cy + radius),
            Offset(cx - radius, cy),
          ],
          cornerR,
        );
      case 'Heart': // small triangle pointing UP
        path = _roundedPolygon(
          [
            Offset(cx, cy - radius),
            Offset(cx + radius * 0.85, cy + radius * 0.6),
            Offset(cx - radius * 0.85, cy + radius * 0.6),
          ],
          cornerR,
        );
      case 'Spleen': // triangle pointing RIGHT
        path = _roundedPolygon(
          [
            Offset(cx - radius * 0.55, cy - radius),
            Offset(cx + radius, cy),
            Offset(cx - radius * 0.55, cy + radius),
          ],
          cornerR,
        );
      case 'SolarPlexus': // triangle pointing LEFT
        path = _roundedPolygon(
          [
            Offset(cx + radius * 0.55, cy - radius),
            Offset(cx - radius, cy),
            Offset(cx + radius * 0.55, cy + radius),
          ],
          cornerR,
        );
      default: // square (Throat, Sacral, Root)
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: radius * 2,
            height: radius * 2,
          ),
          Radius.circular(cornerR),
        );
        canvas
          ..drawRRect(rrect, Paint()..color = fillColor)
          ..drawRRect(
            rrect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = outlineColor,
          );
        return;
    }

    canvas
      ..drawPath(path, Paint()..color = fillColor)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = outlineColor,
      );
  }

  /// A closed [Path] for a polygon with corners rounded by a quadratic
  /// Bézier of the given radius.
  Path _roundedPolygon(List<Offset> vertices, double cornerR) {
    final path = Path();
    final n = vertices.length;
    if (n < 3) return path;
    for (var i = 0; i < n; i++) {
      final prev = vertices[(i - 1 + n) % n];
      final curr = vertices[i];
      final next = vertices[(i + 1) % n];

      final inDx = prev.dx - curr.dx;
      final inDy = prev.dy - curr.dy;
      final inLen = math.sqrt(inDx * inDx + inDy * inDy);
      final outDx = next.dx - curr.dx;
      final outDy = next.dy - curr.dy;
      final outLen = math.sqrt(outDx * outDx + outDy * outDy);

      final r = math.min(cornerR, math.min(inLen / 2, outLen / 2));

      final inPt = Offset(
        curr.dx + (inDx / inLen) * r,
        curr.dy + (inDy / inLen) * r,
      );
      final outPt = Offset(
        curr.dx + (outDx / outLen) * r,
        curr.dy + (outDy / outLen) * r,
      );

      if (i == 0) {
        path.moveTo(inPt.dx, inPt.dy);
      } else {
        path.lineTo(inPt.dx, inPt.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, outPt.dx, outPt.dy);
    }
    path.close();
    return path;
  }

  // ===== All 64 gates rendered inside their centers =====
  void _drawGates(
    Canvas canvas,
    double w,
    double h,
    Map<String, bool> definedCenters,
    Set<int> activeGates,
  ) {
    final fontSize = w * 0.030;

    for (final centerEntry in _gateOffsets.entries) {
      final centerName = centerEntry.key;
      final gates = centerEntry.value;
      final pos = _centerPositions[centerName];
      final radius = (_centerSizes[centerName] ?? 0.16) * w / 2;
      if (pos == null) continue;
      final cx = pos.dx * w;
      final cy = pos.dy * h;
      final defined = definedCenters[centerName] ?? false;

      for (final ge in gates.entries) {
        final gate = ge.key;
        final off = ge.value;
        final gx = cx + off.dx * radius;
        final gy = cy + off.dy * radius;
        final active = activeGates.contains(gate);

        // White inside a coloured (defined) center; muted otherwise.
        // Active gates render brighter / heavier.
        final Color color;
        if (defined) {
          color = Colors.white.withValues(alpha: active ? 1.0 : 0.7);
        } else {
          color = (active ? textPrimary : textMuted)
              .withValues(alpha: active ? 1.0 : 0.7);
        }

        _paintText(
          canvas,
          '$gate',
          Offset(gx, gy),
          color: color,
          size: fontSize,
          weight: active ? FontWeight.w800 : FontWeight.w600,
        );
      }
    }
  }

  // ===== Helpers =====

  Offset _centerPixelPos(String name, double w, double h) {
    final p = _centerPositions[name]!;
    return Offset(p.dx * w, p.dy * h);
  }

  Offset? _gatePixelPos(int gate, double w, double h) {
    final centerName = _gateToCenter[gate];
    if (centerName == null) return null;
    final centerPos = _centerPositions[centerName];
    if (centerPos == null) return null;
    final radius = (_centerSizes[centerName] ?? 0.16) * w / 2;
    final off = _gateOffsets[centerName]?[gate];
    if (off == null) return null;
    return Offset(
      centerPos.dx * w + off.dx * radius,
      centerPos.dy * h + off.dy * radius,
    );
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
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _BodyGraphPainter old) => old.chart != chart;
}
