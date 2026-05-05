import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:flutter/material.dart';

/// The Human Design body graph — 9 energy centers with all 64 gates rendered
/// at canonical positions, defined channels drawn as gentle Bézier curves
/// colored by their HD circuit, and active gates highlighted in red
/// (Personality, conscious) or cream (Design, unconscious).
///
/// Visual conventions:
///   - Defined center  → filled with the center's signature color +
///                       soft outer halo (subtle glow).
///   - Undefined       → outline only, dark surface inside.
///   - Personality gate → red disc (you are aware of this energy).
///   - Design gate      → cream/light disc (this energy is unconscious).
///   - Both             → split disc (half red, half cream).
///   - Inactive gate    → faint outlined circle.
///   - Defined channel  → solid curved line, circuit-colored.
///   - Hanging gate     → short stub from center toward an active gate
///                        whose channel partner isn't active.
class BodyGraph extends StatelessWidget {
  const BodyGraph({required this.chart, this.size = 320, super.key});

  final HumanDesignChart chart;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Aspect 1:1.65 — slightly taller than 1:1.5 so the bigger shapes
    // (now sized to comfortably fit interior gate numbers + center labels)
    // don't crowd into each other.
    return SizedBox(
      width: size,
      height: size * 1.65,
      child: CustomPaint(
        size: Size(size, size * 1.65),
        painter: _BodyGraphPainter(
          chart: chart,
          background: p.background,
          surface: p.surface,
          surfaceElevated: p.surfaceElevated,
          glassBorder: p.glassBorder,
          textPrimary: p.textPrimary,
          textSecondary: p.textSecondary,
          textTertiary: p.textTertiary,
          personalityColor: const Color(0xFFE53935), // red
          designColor: const Color(0xFFF5F0E1), // warm cream
        ),
      ),
    );
  }
}

class _BodyGraphPainter extends CustomPainter {
  _BodyGraphPainter({
    required this.chart,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.glassBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.personalityColor,
    required this.designColor,
  });

  final HumanDesignChart chart;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color glassBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color personalityColor;
  final Color designColor;

  // ===== Center signature colors (canonical HD palette, dark-theme tuned) =====
  static const Map<String, Color> _centerColors = {
    'Head': Color(0xFFF4C542), // amber/gold
    'Ajna': Color(0xFF65B158), // green
    'Throat': Color(0xFF8B7DC3), // muted indigo
    'G': Color(0xFFFFB347), // warm gold
    'Heart': Color(0xFFC53030), // ruby red
    'Sacral': Color(0xFFE53E3E), // scarlet red
    'SolarPlexus': Color(0xFFC56AB6), // pink-purple
    'Spleen': Color(0xFF7BB68A), // sage green
    'Root': Color(0xFFB87333), // copper-brown
  };

  // ===== Center positions (fractional w, h where h = 1.65w) =====
  // Positions spread out vertically to leave clean spacing between the
  // bigger shapes below.
  static const Map<String, Offset> _centerPositions = {
    'Head': Offset(0.50, 0.07),
    'Ajna': Offset(0.50, 0.20),
    'Throat': Offset(0.50, 0.36),
    'G': Offset(0.50, 0.54),
    'Heart': Offset(0.71, 0.62),
    'Spleen': Offset(0.16, 0.73),
    'Sacral': Offset(0.50, 0.73),
    'SolarPlexus': Offset(0.84, 0.73),
    'Root': Offset(0.50, 0.91),
  };

  // Center sizes (fractions of chart width). Triangle centers (Ajna,
  // Spleen, Solar Plexus) and Heart get extra width because their narrow
  // apexes leave less room for gate numbers; the squares are already
  // generous.
  static const Map<String, double> _centerSizes = {
    'Head': 0.20, 'Ajna': 0.22, 'Throat': 0.28, 'G': 0.22,
    'Heart': 0.18, 'Spleen': 0.24, 'Sacral': 0.24, 'SolarPlexus': 0.24,
    'Root': 0.24,
  };

  // ===== Per-center gate positions (interior, in unit-radius from center) =====
  // Each gate sits INSIDE its shape at a canonical position chosen to
  // *encircle* the central label rather than overlap it. The center of
  // each shape is reserved for the label text; gates fan around it.
  static const Map<String, Map<int, Offset>> _gateOffsets = {
    'Head': {
      // Triangle ↑ — three gates along the bottom; label sits above them.
      64: Offset(-0.45, 0.50),
      61: Offset(0.00, 0.55),
      63: Offset(0.45, 0.50),
    },
    'Ajna': {
      // Triangle ↓ — top row of 3 + side "ears" at the widest point + apex.
      // All gates pulled in to stay inside the triangle's narrowing apex.
      47: Offset(-0.45, -0.50),
      24: Offset(0.00, -0.55),
      4: Offset(0.45, -0.50),
      17: Offset(-0.40, -0.05),
      11: Offset(0.40, -0.05),
      43: Offset(0.00, 0.50),
    },
    'Throat': {
      // Square — 11 gates around all four edges, no interior gates.
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
      // Diamond — 8 gates pulled inward from the sharp diamond points so
      // every number sits comfortably inside the shape, encircling the label.
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
      // Small triangle ↑ — 4 gates around the central label, all kept
      // inside the triangle's narrowing apex.
      21: Offset(-0.20, -0.30),
      51: Offset(0.20, -0.30),
      26: Offset(-0.40, 0.30),
      40: Offset(0.40, 0.30),
    },
    'Sacral': {
      // Square — top row, side rails (pushed up so they sit ABOVE the
      // central label), 27 in the lower-left corner, bottom row.
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
      // Triangle ▶ — left rail (48/57/44), upper/lower fans (50/28),
      // gate near the apex (32), and bottom-left interior (18).
      // All offsets kept inside the right-pointing triangle.
      48: Offset(-0.35, -0.55),
      57: Offset(-0.40, -0.10),
      44: Offset(-0.35, 0.55),
      50: Offset(0.05, -0.40),
      32: Offset(0.45, 0),
      28: Offset(0.05, 0.40),
      18: Offset(-0.30, 0.20),
    },
    'SolarPlexus': {
      // Triangle ◀ — mirror of Spleen. All offsets kept inside the
      // left-pointing triangle's apex.
      36: Offset(0.35, -0.55),
      22: Offset(0.40, -0.10),
      37: Offset(0.35, 0.55),
      6: Offset(-0.45, 0),
      49: Offset(-0.05, -0.40),
      55: Offset(-0.05, 0.40),
      30: Offset(0.30, 0.20),
    },
    'Root': {
      // Square — top row, side rails pushed to ±0.35 (out of label band),
      // bottom rails for 38/39, two-gate bottom for 58/41.
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

  // ===== Channel → circuit color map (canonical HD circuit assignment) =====
  static const Map<(int, int), Color> _channelCircuitColor = {
    // Integration — light teal
    (10, 20): Color(0xFFA8D5BA), (10, 34): Color(0xFFA8D5BA),
    (10, 57): Color(0xFFA8D5BA), (20, 34): Color(0xFFA8D5BA),
    (20, 57): Color(0xFFA8D5BA), (34, 57): Color(0xFFA8D5BA),
    // Individual — olive
    (1, 8): Color(0xFFA8AA60), (2, 14): Color(0xFFA8AA60),
    (3, 60): Color(0xFFA8AA60), (12, 22): Color(0xFFA8AA60),
    (23, 43): Color(0xFFA8AA60), (24, 61): Color(0xFFA8AA60),
    (25, 51): Color(0xFFA8AA60), (28, 38): Color(0xFFA8AA60),
    (39, 55): Color(0xFFA8AA60), (47, 64): Color(0xFFA8AA60),
    // Tribal — peach/clay
    (6, 59): Color(0xFFD9A57A), (19, 49): Color(0xFFD9A57A),
    (21, 45): Color(0xFFD9A57A), (26, 44): Color(0xFFD9A57A),
    (27, 50): Color(0xFFD9A57A), (32, 54): Color(0xFFD9A57A),
    (37, 40): Color(0xFFD9A57A),
    // Collective Logic — slate blue
    (4, 63): Color(0xFF5C7AAF), (5, 15): Color(0xFF5C7AAF),
    (7, 31): Color(0xFF5C7AAF), (9, 52): Color(0xFF5C7AAF),
    (16, 48): Color(0xFF5C7AAF), (17, 62): Color(0xFF5C7AAF),
    (18, 58): Color(0xFF5C7AAF), (42, 53): Color(0xFF5C7AAF),
    // Collective Sensing — terracotta
    (11, 56): Color(0xFFC25450), (13, 33): Color(0xFFC25450),
    (29, 46): Color(0xFFC25450), (30, 41): Color(0xFFC25450),
    (35, 36): Color(0xFFC25450),
  };

  Color _channelColor(int g1, int g2, Color fallback) {
    final key = g1 < g2 ? (g1, g2) : (g2, g1);
    return _channelCircuitColor[key] ?? fallback;
  }

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

    // Active gates split by source.
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

    // Defined-channels lookup for hanging-gate detection.
    final definedChannelKeys = <(int, int)>{
      for (final ch in chart.channels)
        ch.gate1 < ch.gate2 ? (ch.gate1, ch.gate2) : (ch.gate2, ch.gate1),
    };

    // Defined-centers map.
    final definedCenters = <String, bool>{
      for (final c in chart.centers) c.name: c.defined,
    };

    // 1) Draw hanging-gate stubs (one-sided activations) BEHIND channels.
    _drawHangingStubs(canvas, w, h, activeGates, definedChannelKeys);

    // 2) Defined channels (curved Bézier, circuit-colored).
    _drawDefinedChannels(canvas, w, h);

    // 3) Glow halos behind defined centers.
    _drawCenterGlows(canvas, w, h, definedCenters);

    // 4) Centers themselves.
    _drawCenters(canvas, w, h, definedCenters);

    // 5) All gates (active highlighted, inactive faint).
    _drawGates(canvas, w, h, personalityGates, designGates);
  }

  // ===== Hanging gate stubs — short line from each active gate toward
  // its channel partner's home center. Drawn FAINT so they don't compete
  // with defined channels. Only draws for gates whose channel is NOT defined.
  void _drawHangingStubs(
    Canvas canvas,
    double w,
    double h,
    Set<int> activeGates,
    Set<(int, int)> definedChannelKeys,
  ) {
    final stubPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = textTertiary.withValues(alpha: 0.5);

    for (final ch in _allChannels) {
      final aActive = activeGates.contains(ch.$1);
      final bActive = activeGates.contains(ch.$2);
      if (aActive == bActive) continue; // both or neither — skip
      if (definedChannelKeys.contains(ch)) continue;

      // Draw a stub from the active gate toward the OTHER center (1/3 of way).
      final (activeGate, partnerGate) =
          aActive ? (ch.$1, ch.$2) : (ch.$2, ch.$1);
      final activeCenter = _gateToCenter[activeGate];
      final partnerCenter = _gateToCenter[partnerGate];
      if (activeCenter == null || partnerCenter == null) continue;

      final activePos = _gatePixelPos(activeGate, w, h);
      final partnerCenterPos = _centerPixelPos(partnerCenter, w, h);
      if (activePos == null) continue;

      // Stub goes 35% of the way toward the partner center.
      final stubEnd = Offset(
        activePos.dx + (partnerCenterPos.dx - activePos.dx) * 0.35,
        activePos.dy + (partnerCenterPos.dy - activePos.dy) * 0.35,
      );
      canvas.drawLine(activePos, stubEnd, stubPaint);
    }
  }

  // ===== Defined channels — curved Béziers colored by circuit =====
  void _drawDefinedChannels(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (final ch in chart.channels) {
      final start = _gatePixelPos(ch.gate1, w, h);
      final end = _gatePixelPos(ch.gate2, w, h);
      if (start == null || end == null) continue;

      paint.color = _channelColor(ch.gate1, ch.gate2,
          _centerColors[ch.centers.first] ?? glassBorder);

      // Bow the curve outward from the chart's center axis.
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final centerX = w * 0.5;
      // Direction perpendicular to start→end, pointed away from the center axis.
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final perpX = -dy / (dist == 0 ? 1 : dist);
      final perpY = dx / (dist == 0 ? 1 : dist);
      // Push the control point outward (away from x = centerX).
      final outwardSign = (mid.dx >= centerX ? 1.0 : -1.0);
      final bow = dist * 0.10 * outwardSign;
      final controlPoint = Offset(
        mid.dx + perpX * bow.abs() * (perpX * outwardSign).sign,
        mid.dy + perpY * bow,
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  // ===== Glow halos behind defined centers =====
  void _drawCenterGlows(
    Canvas canvas,
    double w,
    double h,
    Map<String, bool> definedCenters,
  ) {
    for (final entry in _centerPositions.entries) {
      final name = entry.key;
      if (!(definedCenters[name] ?? false)) continue;
      final pos = entry.value;
      final radius = (_centerSizes[name] ?? 0.16) * w / 2;
      final color = _centerColors[name] ?? glassBorder;

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(
        Offset(pos.dx * w, pos.dy * h),
        radius * 1.15,
        glowPaint,
      );
    }
  }

  // ===== Centers (proper canonical shapes) =====
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
        defined: defined,
        fillColor: defined ? color : surface,
        outlineColor: defined ? color : glassBorder.withValues(alpha: 0.7),
      );

      // Label inside — Title Case, regular weight, smaller.
      _paintText(
        canvas,
        _shortLabel(name),
        Offset(cx, cy),
        color: defined ? Colors.white : textSecondary,
        size: w * 0.028,
        weight: FontWeight.w400,
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
    required bool defined,
    required Color fillColor,
    required Color outlineColor,
  }) {
    // Corner-rounding radius — uniform 18% of the center's half-width gives
    // a soft, modern look without losing the shape's identity.
    final cornerR = radius * 0.18;

    Path path;
    switch (name) {
      case 'Head': // triangle pointing UP
        path = _roundedPolygon([
          Offset(cx, cy - radius),
          Offset(cx + radius, cy + radius * 0.7),
          Offset(cx - radius, cy + radius * 0.7),
        ], cornerR);
      case 'Ajna': // triangle pointing DOWN
        path = _roundedPolygon([
          Offset(cx - radius, cy - radius * 0.7),
          Offset(cx + radius, cy - radius * 0.7),
          Offset(cx, cy + radius),
        ], cornerR);
      case 'G': // diamond
        path = _roundedPolygon([
          Offset(cx, cy - radius),
          Offset(cx + radius, cy),
          Offset(cx, cy + radius),
          Offset(cx - radius, cy),
        ], cornerR);
      case 'Heart': // small triangle pointing UP
        path = _roundedPolygon([
          Offset(cx, cy - radius),
          Offset(cx + radius * 0.85, cy + radius * 0.6),
          Offset(cx - radius * 0.85, cy + radius * 0.6),
        ], cornerR);
      case 'Spleen': // triangle pointing RIGHT
        path = _roundedPolygon([
          Offset(cx - radius * 0.55, cy - radius),
          Offset(cx + radius, cy),
          Offset(cx - radius * 0.55, cy + radius),
        ], cornerR);
      case 'SolarPlexus': // triangle pointing LEFT
        path = _roundedPolygon([
          Offset(cx + radius * 0.55, cy - radius),
          Offset(cx - radius, cy),
          Offset(cx + radius * 0.55, cy + radius),
        ], cornerR);
      default: // square (Throat, Sacral, Root) — use RRect directly
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
              ..strokeWidth = 1.5
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
          ..strokeWidth = 1.5
          ..color = outlineColor,
      );
  }

  /// Builds a closed [Path] for a polygon whose corners are rounded by a
  /// quadratic Bézier of the given radius. Each vertex is the apex of the
  /// curve; the path travels along the interior of each edge between
  /// inset points.
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

      // Don't let the rounding chew through more than half of either edge.
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

  // ===== All 64 gates (active highlighted, inactive faint) =====
  void _drawGates(
    Canvas canvas,
    double w,
    double h,
    Set<int> personalityGates,
    Set<int> designGates,
  ) {
    // Text size scales with chart width — bold yellow numbers, no disc.
    // Active gates are full-opacity yellow; inactive gates fade. Sized
    // small enough that every number stays inside its shape.
    final fontSize = w * 0.016;

    // Gates sit INSIDE each shape at canonical layout positions (matches
    // the reference HD body-graph rendering). Offsets are unit-radius, so
    // we just multiply by `radius` and translate by the center position.
    for (final centerEntry in _gateOffsets.entries) {
      final centerName = centerEntry.key;
      final gates = centerEntry.value;
      final pos = _centerPositions[centerName];
      final radius = (_centerSizes[centerName] ?? 0.16) * w / 2;
      if (pos == null) continue;
      final cx = pos.dx * w;
      final cy = pos.dy * h;

      for (final ge in gates.entries) {
        final gate = ge.key;
        final off = ge.value;
        final gx = cx + off.dx * radius;
        final gy = cy + off.dy * radius;

        final inP = personalityGates.contains(gate);
        final inD = designGates.contains(gate);
        _drawGateMark(
          canvas,
          Offset(gx, gy),
          gate,
          inP: inP,
          inD: inD,
          fontSize: fontSize,
        );
      }
    }
  }

  /// Renders a gate as just a bold yellow number — no disc background.
  /// Active gates are full-opacity yellow; inactive gates are a faint
  /// transparent yellow so they're still visible but don't compete.
  void _drawGateMark(
    Canvas canvas,
    Offset pos,
    int gate, {
    required bool inP,
    required bool inD,
    required double fontSize,
  }) {
    const yellow = Color(0xFFF4C542);
    final isActive = inP || inD;
    _paintText(
      canvas,
      '$gate',
      pos,
      color: yellow.withValues(alpha: isActive ? 1.0 : 0.35),
      size: fontSize,
      weight: FontWeight.w900,
    );
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

  String _shortLabel(String name) {
    switch (name) {
      case 'SolarPlexus':
        return 'Solar';
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
    double letterSpacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
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
