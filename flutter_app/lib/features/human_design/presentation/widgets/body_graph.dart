import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The Human Design BodyGraph, drawn the way the original (Jovian Archive)
/// chart is: on a white sheet, the nine centers in their canonical shapes,
/// positions and colors, all 36 channels as tracks whose halves are filled
/// by the gate at that end (black = Personality, red = Design, striped =
/// both), and the Design (red) / Personality (black) planet columns
/// flanking the graph.
class BodyGraph extends StatelessWidget {
  const BodyGraph({required this.chart, super.key});

  final HumanDesignChart chart;

  // Classic chart ink colors.
  static const personalityInk = Color(0xFF1A1A1A);
  static const designInk = Color(0xFFD0312D);
  static const sheet = Color(0xFFFFFFFF);

  Object get _heroTag => 'bodygraph-${identityHashCode(chart)}';

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) =>
            _BodyGraphFullScreen(chart: chart, heroTag: _heroTag),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Hero(
          tag: _heroTag,
          // The card itself flies into the full-screen view — the "zoom".
          child: _BodyGraphSheet(chart: chart, zoomable: true),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: _RoundIconButton(
            icon: Icons.open_in_full_rounded,
            onPressed: () => _openFullScreen(context),
          ),
        ),
      ],
    );
  }
}

/// The white chart sheet: Design column, graph, Personality column.
class _BodyGraphSheet extends StatelessWidget {
  const _BodyGraphSheet({
    required this.chart,
    required this.zoomable,
    this.radius = 20,
  });

  final HumanDesignChart chart;

  /// Inline card: pinch-zoom on the graph itself. Full screen wraps the
  /// whole sheet in its own viewer instead, so this is off there.
  final bool zoomable;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final design = chart.gates.where((g) => !g.isPersonality).toList();
    final personality = chart.gates.where((g) => g.isPersonality).toList();
    final graph = CustomPaint(painter: _BodyGraphPainter(chart));
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        decoration: BoxDecoration(
          color: BodyGraph.sheet,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlanetColumn(
              title: l.hdDesignHeader,
              ink: BodyGraph.designInk,
              activations: design,
            ),
            Expanded(
              child: AspectRatio(
                aspectRatio: _Layout.width / _Layout.height,
                child: zoomable
                    ? InteractiveViewer(maxScale: 4, child: graph)
                    : graph,
              ),
            ),
            _PlanetColumn(
              title: l.hdPersonalityHeader,
              ink: BodyGraph.personalityInk,
              activations: personality,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen viewer: pinch to zoom up to 6x, double-tap to zoom in on a
/// spot (again to reset), swipe down or tap ✕ to close.
class _BodyGraphFullScreen extends StatefulWidget {
  const _BodyGraphFullScreen({required this.chart, required this.heroTag});

  final HumanDesignChart chart;
  final Object heroTag;

  @override
  State<_BodyGraphFullScreen> createState() => _BodyGraphFullScreenState();
}

class _BodyGraphFullScreenState extends State<_BodyGraphFullScreen>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  Animation<Matrix4>? _zoomTween;
  Offset _doubleTapAt = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _zoomAnim.addListener(() {
      if (_zoomTween != null) _transform.value = _zoomTween!.value;
    });
    _transform.addListener(() {
      final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _zoomAnim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 end) {
    _zoomTween = Matrix4Tween(begin: _transform.value, end: end).animate(
      CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic),
    );
    _zoomAnim.forward(from: 0);
  }

  void _onDoubleTap() {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    const scale = 2.5;
    final p = _doubleTapAt;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              // Swipe down to dismiss — only when not zoomed, so it never
              // fights with panning around a zoomed chart.
              onVerticalDragEnd: _zoomed
                  ? null
                  : (d) {
                      if ((d.primaryVelocity ?? 0) > 600) {
                        Navigator.of(context).pop();
                      }
                    },
              onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
              onDoubleTap: _onDoubleTap,
              child: InteractiveViewer(
                transformationController: _transform,
                maxScale: 6,
                panEnabled: _zoomed,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      padding.top + 56,
                      12,
                      padding.bottom + 24,
                    ),
                    child: FittedBox(
                      child: SizedBox(
                        width: 460,
                        child: Hero(
                          tag: widget.heroTag,
                          child: _BodyGraphSheet(
                            chart: widget.chart,
                            zoomable: false,
                            radius: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 8,
            right: 16,
            child: _RoundIconButton(
              icon: Icons.close_rounded,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: const Color(0xFFF2F2F2),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x1A000000)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: BodyGraph.personalityInk),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// One column of planetary activations: glyph + gate.line, in the
/// traditional body order.
class _PlanetColumn extends StatelessWidget {
  const _PlanetColumn({
    required this.title,
    required this.ink,
    required this.activations,
  });

  final String title;
  final Color ink;
  final List<HDGateActivation> activations;

  static const _order = [
    'Sun', 'Earth', 'NorthNode', 'SouthNode', 'Moon', 'Mercury', 'Venus', //
    'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto',
  ];

  // ︎ forces the text (not emoji) presentation of each glyph.
  static const _glyphs = {
    'Sun': '☉',
    'Earth': '⊕',
    'NorthNode': '☊',
    'SouthNode': '☋',
    'Moon': '☽',
    'Mercury': '☿',
    'Venus': '♀︎',
    'Mars': '♂︎',
    'Jupiter': '♃',
    'Saturn': '♄',
    'Uranus': '♅',
    'Neptune': '♆',
    'Pluto': '♇',
  };

  @override
  Widget build(BuildContext context) {
    final byBody = {for (final a in activations) a.body: a};
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            child: Text(
              title,
              style: TextStyle(
                color: ink,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (final body in _order)
            if (byBody[body] case final a?)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                // Shrinks instead of overflowing at large text sizes.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text(
                          _glyphs[body] ?? '•',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ink, fontSize: 12, height: 1),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${a.gate}.${a.line}',
                        style: TextStyle(
                          color: ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Canonical geometry in a fixed 340 × 600 design space.
abstract final class _Layout {
  static const double width = 340;
  static const double height = 600;

  /// Center shapes as polygons (squares are 4 points).
  static const Map<String, List<Offset>> centers = {
    'Head': [Offset(170, 8), Offset(212, 78), Offset(128, 78)],
    'Ajna': [Offset(128, 100), Offset(212, 100), Offset(170, 170)],
    'Throat': [
      Offset(135, 200), Offset(205, 200), Offset(205, 268), Offset(135, 268), //
    ],
    'G': [
      Offset(170, 292),
      Offset(212, 334),
      Offset(170, 376),
      Offset(128, 334),
    ],
    'Heart': [Offset(236, 346), Offset(282, 368), Offset(234, 392)],
    'Spleen': [Offset(8, 392), Offset(88, 440), Offset(8, 488)],
    'SolarPlexus': [Offset(332, 392), Offset(252, 440), Offset(332, 488)],
    'Sacral': [
      Offset(135, 410), Offset(205, 410), Offset(205, 478), Offset(135, 478), //
    ],
    'Root': [
      Offset(135, 522), Offset(205, 522), Offset(205, 592), Offset(135, 592), //
    ],
  };

  /// Traditional center colors of the original chart.
  static const Map<String, Color> colors = {
    'Head': Color(0xFFF6D55C),
    'Ajna': Color(0xFF6DBB63),
    'Throat': Color(0xFFB88B5A),
    'G': Color(0xFFF6D55C),
    'Heart': Color(0xFFE3524F),
    'Spleen': Color(0xFFB88B5A),
    'SolarPlexus': Color(0xFFB88B5A),
    'Sacral': Color(0xFFE3524F),
    'Root': Color(0xFFB88B5A),
  };

  /// Every gate's anchor point (where its channel attaches).
  static const Map<int, Offset> gates = {
    // Head
    64: Offset(150, 70), 61: Offset(170, 70), 63: Offset(190, 70),
    // Ajna
    47: Offset(150, 108), 24: Offset(170, 108), 4: Offset(190, 108),
    17: Offset(155, 128), 11: Offset(185, 128), 43: Offset(170, 150),
    // Throat
    62: Offset(150, 208), 23: Offset(170, 208), 56: Offset(190, 208),
    16: Offset(143, 222), 20: Offset(143, 246),
    35: Offset(197, 218), 12: Offset(197, 234), 45: Offset(197, 250),
    31: Offset(150, 260), 8: Offset(170, 260), 33: Offset(190, 260),
    // G
    1: Offset(170, 304), 7: Offset(155, 320), 13: Offset(185, 320),
    10: Offset(140, 334), 25: Offset(200, 334),
    15: Offset(155, 348), 46: Offset(185, 348), 2: Offset(170, 364),
    // Heart
    21: Offset(243, 358), 51: Offset(242, 370), 26: Offset(243, 382),
    40: Offset(262, 372),
    // Spleen (upper edge from the base toward the point, then lower edge)
    48: Offset(16, 408), 57: Offset(32, 418), 44: Offset(48, 428),
    50: Offset(64, 438), 32: Offset(50, 456), 28: Offset(34, 466),
    18: Offset(18, 476),
    // Solar Plexus (mirror of the spleen)
    36: Offset(324, 408), 22: Offset(308, 418), 37: Offset(292, 428),
    6: Offset(276, 438), 49: Offset(290, 456), 55: Offset(306, 466),
    30: Offset(322, 476),
    // Sacral
    5: Offset(150, 418), 14: Offset(170, 418), 29: Offset(190, 418),
    34: Offset(143, 432), 27: Offset(143, 456), 59: Offset(197, 456),
    42: Offset(150, 470), 3: Offset(170, 470), 9: Offset(190, 470),
    // Root
    53: Offset(150, 530), 60: Offset(170, 530), 52: Offset(190, 530),
    54: Offset(143, 544), 38: Offset(143, 564), 58: Offset(143, 584),
    19: Offset(197, 544), 39: Offset(197, 564), 41: Offset(197, 584),
  };

  /// The 36 channels. The optional third value bends the path around the G center for the
  /// 20–34 integration channel, like the original drawing.
  static const List<(int, int, Offset?)> channels = [
    (64, 47, null),
    (61, 24, null),
    (63, 4, null),
    (17, 62, null),
    (43, 23, null),
    (11, 56, null),
    (31, 7, null),
    (8, 1, null),
    (33, 13, null),
    (20, 10, null),
    (20, 34, Offset(122, 334)),
    (20, 57, null),
    (10, 34, null),
    (10, 57, null),
    (34, 57, null),
    (16, 48, null),
    (35, 36, null),
    (12, 22, null),
    (45, 21, null),
    (25, 51, null),
    (26, 44, null),
    (40, 37, null),
    (15, 5, null),
    (2, 14, null),
    (46, 29, null),
    (27, 50, null),
    (59, 6, null),
    (42, 53, null),
    (3, 60, null),
    (9, 52, null),
    (54, 32, null),
    (38, 28, null),
    (58, 18, null),
    (19, 49, null),
    (39, 55, null),
    (41, 30, null),
  ];
}

class _BodyGraphPainter extends CustomPainter {
  _BodyGraphPainter(this.chart);

  final HumanDesignChart chart;

  static const _track = 7.0;
  static const _trackBorder = Color(0xFFB9B9B9);
  static const _openFill = Color(0xFFFFFFFF);
  static const _openStroke = Color(0xFF9A9A9A);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _Layout.width, size.height / _Layout.height);

    final personality = <int>{};
    final design = <int>{};
    for (final g in chart.gates) {
      (g.isPersonality ? personality : design).add(g.gate);
    }
    final defined = {for (final c in chart.centers) c.name: c.defined};

    // 1) Channel tracks: grey border, then white core.
    for (final ch in _Layout.channels) {
      final path = _channelPath(ch);
      if (path == null) continue;
      canvas
        ..drawPath(path, _stroke(_track + 2, _trackBorder))
        ..drawPath(path, _stroke(_track, _openFill));
    }

    // 2) Activated halves: each gate fills its half of the channel.
    for (final ch in _Layout.channels) {
      final halves = _halves(ch);
      if (halves == null) continue;
      for (final (gate, half) in halves) {
        final p = personality.contains(gate);
        final d = design.contains(gate);
        if (!p && !d) continue;
        if (p && d) {
          _drawStriped(canvas, half);
        } else {
          canvas.drawPath(
            half,
            _stroke(
              _track - 1.5,
              p ? BodyGraph.personalityInk : BodyGraph.designInk,
            ),
          );
        }
      }
    }

    // 3) Centers.
    for (final e in _Layout.centers.entries) {
      final isDefined = defined[e.key] ?? false;
      final path = _roundedPolygon(e.value, e.value.length == 4 ? 6 : 7);
      canvas
        ..drawPath(
          path,
          Paint()..color = isDefined ? _Layout.colors[e.key]! : _openFill,
        )
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = isDefined
                ? Color.lerp(_Layout.colors[e.key], Colors.black, 0.25)!
                : _openStroke,
        );
    }

    // 4) Gate numbers — activated gates get a filled badge.
    for (final e in _Layout.gates.entries) {
      final gate = e.key;
      final p = personality.contains(gate);
      final d = design.contains(gate);
      final active = p || d;
      if (active) {
        final badge = p && !d
            ? BodyGraph.personalityInk
            : d && !p
                ? BodyGraph.designInk
                : const Color(0xFF6B2B2A);
        canvas.drawCircle(e.value, 6.4, Paint()..color = badge);
      }
      _text(
        canvas,
        '$gate',
        e.value,
        color: active ? Colors.white : const Color(0xFF3A3A3A),
        weight: active ? FontWeight.w800 : FontWeight.w500,
      );
    }
  }

  // ===== Paths =====

  List<Offset>? _points((int, int, Offset?) ch) {
    final a = _Layout.gates[ch.$1];
    final b = _Layout.gates[ch.$2];
    if (a == null || b == null) return null;
    return [a, if (ch.$3 != null) ch.$3!, b];
  }

  Path? _channelPath((int, int, Offset?) ch) {
    final pts = _points(ch);
    if (pts == null) return null;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  /// Splits a channel at its arc-length midpoint into the half belonging
  /// to each gate.
  List<(int, Path)>? _halves((int, int, Offset?) ch) {
    final whole = _channelPath(ch);
    if (whole == null) return null;
    final metric = whole.computeMetrics().first;
    final mid = metric.length / 2;
    return [
      (ch.$1, metric.extractPath(0, mid)),
      (ch.$2, metric.extractPath(mid, metric.length)),
    ];
  }

  /// Red/black stripes for a gate activated on both sides.
  void _drawStriped(Canvas canvas, Path half) {
    const dash = 5.0;
    final metric = half.computeMetrics().first;
    var t = 0.0;
    var red = true;
    while (t < metric.length) {
      final end = (t + dash).clamp(0.0, metric.length);
      canvas.drawPath(
        metric.extractPath(t, end),
        _stroke(
          _track - 1.5,
          red ? BodyGraph.designInk : BodyGraph.personalityInk,
          cap: StrokeCap.butt,
        ),
      );
      t = end;
      red = !red;
    }
  }

  Paint _stroke(double w, Color c, {StrokeCap cap = StrokeCap.round}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = cap
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  Path _roundedPolygon(List<Offset> v, double r) {
    final path = Path();
    final n = v.length;
    for (var i = 0; i < n; i++) {
      final prev = v[(i - 1 + n) % n];
      final curr = v[i];
      final next = v[(i + 1) % n];
      final inDir = prev - curr;
      final outDir = next - curr;
      final rr = [r, inDir.distance / 2, outDir.distance / 2]
          .reduce((a, b) => a < b ? a : b);
      final inPt = curr + inDir / inDir.distance * rr;
      final outPt = curr + outDir / outDir.distance * rr;
      if (i == 0) {
        path.moveTo(inPt.dx, inPt.dy);
      } else {
        path.lineTo(inPt.dx, inPt.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, outPt.dx, outPt.dy);
    }
    return path..close();
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required FontWeight weight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 7.6,
          fontWeight: weight,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BodyGraphPainter old) => old.chart != chart;
}
