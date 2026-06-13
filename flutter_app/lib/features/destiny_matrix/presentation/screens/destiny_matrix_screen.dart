import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/providers/destiny_matrix_providers.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Subtract-22 reduction matching the backend's fold-into-1..22. Kept only
/// as a fallback in case an older API response is missing the new
/// inner-diamond / chakra keys.
int _reduce22(int n) => n <= 0 ? 1 : ((n - 1) % 22) + 1;

class DestinyMatrixScreen extends ConsumerStatefulWidget {
  const DestinyMatrixScreen({super.key});

  @override
  ConsumerState<DestinyMatrixScreen> createState() =>
      _DestinyMatrixScreenState();
}

class _DestinyMatrixScreenState extends ConsumerState<DestinyMatrixScreen> {
  /// When true, the octagram card collapses to a smaller height so the
  /// line cards below get more breathing room. Toggled by the app-bar
  /// expand/collapse button.
  bool _compact = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final readingAsync = ref.watch(destinyMatrixReadingProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Matrix of Destiny'),
        actions: [
          IconButton(
            tooltip: _compact ? 'Expand matrix' : 'Shrink matrix',
            onPressed: () => setState(() => _compact = !_compact),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                _compact
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                key: ValueKey(_compact),
              ),
            ),
          ),
        ],
      ),
      body: LivelyBackdrop(
        seed: 53,
        intensity: 0.6,
        child: readingAsync.when(
          loading: () => const ShimmerList(itemCount: 5),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(destinyMatrixReadingProvider),
          ),
          data: (reading) => _Body(reading: reading, compact: _compact),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reading, required this.compact});
  final DestinyMatrixReading reading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _Hero(reading: reading),
      const SizedBox(height: 20),
      const _SectionLabel('Your Octagram'),
      const SizedBox(height: 12),
      _Octagram(reading: reading, compact: compact),
      const SizedBox(height: 8),
      _OctagramHint(),
      const SizedBox(height: 24),
      const _SectionLabel('The Four Lines'),
      const SizedBox(height: 12),
      ...reading.lines.map((l) => _LineCard(line: l, reading: reading)),
      const SizedBox(height: 40),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
      itemCount: children.length,
      itemBuilder: (context, i) => _FadeIn(
        delayMs: 40 * i,
        child: children[i],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero.
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.reading});
  final DestinyMatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final core = reading.pointFor('E');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [p.primary, p.accent]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR CORE ARCANA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (reading.birthDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Birth date ${reading.birthDate}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${core?.arcana ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      core?.arcanaName ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      core?.title ?? 'Comfort / Core',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Octagram centerpiece.
// ---------------------------------------------------------------------------

/// Visual descriptor for one of the 8 outer corners: where it sits on the
/// octagram, what age label it carries, and which color family it belongs
/// to (the classical Matrix paints the cardinal "age" corners purple/red
/// and the diagonal intermediate corners as plain numbered tokens).
class _OuterSlot {
  const _OuterSlot({
    required this.key,
    required this.degrees,
    required this.age,
    required this.style,
  });
  final String key;
  final double degrees;
  final int age;
  final _CornerStyle style;
}

enum _CornerStyle { purple, red, plain }

/// Outer corners in their classical Matrix age layout. The angles are
/// screen-space (0° = right, clockwise) — matching the reference image
/// where left = age 0 and we walk clockwise: 0 → 10 → 20 → 30 → 40 → … .
const _outerSlots = <_OuterSlot>[
  _OuterSlot(key: 'A',  degrees: 180, age: 0,  style: _CornerStyle.purple),
  _OuterSlot(key: 'TL', degrees: 225, age: 10, style: _CornerStyle.plain),
  _OuterSlot(key: 'B',  degrees: 270, age: 20, style: _CornerStyle.purple),
  _OuterSlot(key: 'TR', degrees: 315, age: 30, style: _CornerStyle.plain),
  _OuterSlot(key: 'C',  degrees: 0,   age: 40, style: _CornerStyle.red),
  _OuterSlot(key: 'BR', degrees: 45,  age: 50, style: _CornerStyle.plain),
  _OuterSlot(key: 'D',  degrees: 90,  age: 60, style: _CornerStyle.red),
  _OuterSlot(key: 'BL', degrees: 135, age: 70, style: _CornerStyle.plain),
];

class _Octagram extends StatefulWidget {
  const _Octagram({required this.reading, this.compact = false});
  final DestinyMatrixReading reading;

  /// When true, the card animates down to a smaller square so the line
  /// cards below sit closer to the fold. Animated for a clean transition.
  final bool compact;

  @override
  State<_Octagram> createState() => _OctagramState();
}

class _OctagramState extends State<_Octagram> {
  /// Density of the perimeter age ladder. False = every 5th year only
  /// (16 rungs around the ring — the cleaner default). True = all 72
  /// non-corner rungs (full karmic perimeter).
  bool _everyYear = false;

  void _toggleDensity() => setState(() => _everyYear = !_everyYear);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.gold.withValues(alpha: 0.3)),
            ),
            child: FractionallySizedBox(
              widthFactor: widget.compact ? 0.66 : 1,
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return _OctagramBoard(
                      reading: widget.reading,
                      size: size,
                      everyYear: _everyYear,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _DensityToggle(everyYear: _everyYear, onToggle: _toggleDensity),
      ],
    );
  }
}

/// Tiny segmented pill that flips the perimeter density. Tap either side
/// to switch; the active option fills, the inactive one stays outlined.
class _DensityToggle extends StatelessWidget {
  const _DensityToggle({required this.everyYear, required this.onToggle});
  final bool everyYear;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget seg(String label, {required bool active}) {
      return GestureDetector(
        onTap: active ? null : onToggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? p.gold.withValues(alpha: 0.85) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? p.background : p.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.textTertiary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Every 5 years', active: !everyYear),
          seg('Every year', active: everyYear),
        ],
      ),
    );
  }
}

/// Lays out every node and overlay element on top of the painted frame.
/// Kept as a separate widget so the geometry math lives in one place.
class _OctagramBoard extends StatelessWidget {
  const _OctagramBoard({
    required this.reading,
    required this.size,
    required this.everyYear,
  });
  final DestinyMatrixReading reading;
  final Size size;

  /// Perimeter density: true = all 72 non-corner rungs, false = every 5th
  /// year only. Drives both the filter and visual weight inside
  /// _buildPerimeterRungs.
  final bool everyYear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shortest = size.shortestSide;
    // Geometry tuned against the reference: outer corners hug the card
    // edge (with breathing room for age labels), inner diamond about
    // halfway in, center sized large enough to anchor the eye.
    final outerR = shortest * 0.40;
    final innerR = shortest * 0.22;
    final outerRadius = (shortest * 0.085).clamp(22.0, 38.0);
    final innerRadius = (shortest * 0.05).clamp(16.0, 24.0);
    final centerRadius = (shortest * 0.09).clamp(26.0, 42.0);
    final center = Offset(size.width / 2, size.height / 2);

    // Pull the backend's authentic inner / chakra values; if an older API
    // is still serving (no ITL/ITR/.../Heart/Money keys), fall back to the
    // same reductions the Go side does so the screen always renders.
    final centerArcana = reading.pointFor('E')?.arcana ?? 0;
    int innerFor(String outerKey, String innerKey) {
      final fromApi = reading.pointFor(innerKey)?.arcana ?? 0;
      if (fromApi > 0) return fromApi;
      return _reduce22(
        (reading.pointFor(outerKey)?.arcana ?? 0) + centerArcana,
      );
    }

    final inner = <String, int>{
      'TL': innerFor('TL', 'ITL'),
      'TR': innerFor('TR', 'ITR'),
      'BR': innerFor('BR', 'IBR'),
      'BL': innerFor('BL', 'IBL'),
    };

    final heartArcana = reading.pointFor('Heart')?.arcana ??
        _reduce22(
          (reading.pointFor('BL')?.arcana ?? 0) +
              (reading.pointFor('TR')?.arcana ?? 0),
        );
    final moneyArcana = reading.pointFor('Money')?.arcana ??
        _reduce22(
          (reading.pointFor('TL')?.arcana ?? 0) +
              (reading.pointFor('BR')?.arcana ?? 0),
        );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Painted frame: octagon outline + two diagonal generation lines.
        Positioned.fill(
          child: CustomPaint(
            painter: _MatrixFramePainter(
              center: center,
              outerR: outerR,
              innerR: innerR,
              frameColor: p.textTertiary.withValues(alpha: 0.45),
              diamondColor: p.textTertiary.withValues(alpha: 0.35),
              maleColor: const Color(0xFF7B61FF),
              femaleColor: const Color(0xFFF07C82),
            ),
          ),
        ),

        // Generation-line labels along the two diagonals.
        _DiagonalLabel(
          text: 'male generation line',
          center: center,
          radius: outerR * 0.55,
          angleDeg: 225,
          color: const Color(0xFF7B61FF),
        ),
        _DiagonalLabel(
          text: 'female generation line',
          center: center,
          radius: outerR * 0.55,
          angleDeg: 315,
          color: const Color(0xFFF07C82),
        ),

        // Heart + money inline markers (visual chakras).
        _ChakraMarker(
          icon: Icons.favorite,
          color: const Color(0xFFF07C82),
          arcana: heartArcana,
          position: Offset(center.dx, center.dy + innerR * 0.95),
        ),
        _ChakraMarker(
          icon: Icons.attach_money,
          color: const Color(0xFF8BC34A),
          arcana: moneyArcana,
          position: Offset(center.dx + innerR * 0.95, center.dy - innerR * 0.30),
        ),

        // Inner diamond nodes (4 small numbered circles). Prefer the real
        // backend point — its title / arcanaName / meaning power the tap
        // sheet — and only fall back to a virtual one if the API didn't
        // include the inner key.
        for (final slot
            in _outerSlots.where((s) => s.style == _CornerStyle.plain))
          () {
            final innerKey = 'I${slot.key}';
            final backendPoint = reading.pointFor(innerKey);
            return _placeNode(
              point: backendPoint ??
                  _virtual('${slot.key}i', inner[slot.key] ?? 0),
              position: _polar(center, innerR, slot.degrees),
              radius: innerRadius,
              kind: _NodeKind.inner,
            );
          }(),

        // Outer corner nodes (8 large circles, color-coded by classical age).
        for (final slot in _outerSlots)
          _placeNode(
            point: reading.pointFor(slot.key),
            position: _polar(center, outerR, slot.degrees),
            radius: outerRadius,
            kind: switch (slot.style) {
              _CornerStyle.purple => _NodeKind.purpleCorner,
              _CornerStyle.red => _NodeKind.redCorner,
              _CornerStyle.plain => _NodeKind.plainCorner,
            },
          ),

        // Outer age labels sit just past each corner along its outward
        // radial — keeps "0 years old" to the left of the left corner,
        // "60 years old" below the bottom corner, and so on.
        for (final slot in _outerSlots)
          _AgeLabel(
            center: center,
            radius: outerR + outerRadius + 14,
            angleDeg: slot.degrees,
            age: slot.age,
          ),

        // Perimeter age-ladder rungs. Density follows the toggle: every
        // year (dense) or every 5th (cleaner). Bumped well past the outer
        // corner ring with a larger font so the values read at a glance.
        ..._buildPerimeterRungs(
          ladder: reading.ageLadder,
          center: center,
          radius: outerR + outerRadius * 0.85,
          everyYear: everyYear,
        ),

        // Center node (the yellow "destiny core" arcana).
        _placeNode(
          point: reading.pointFor('E'),
          position: center,
          radius: centerRadius,
          kind: _NodeKind.center,
        ),
      ],
    );
  }

  /// Builds a Positioned[_Node] centered on [position].
  Widget _placeNode({
    required DestinyPoint? point,
    required Offset position,
    required double radius,
    required _NodeKind kind,
  }) {
    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      child: _Node(point: point, radius: radius, kind: kind),
    );
  }

  /// Fabricates a tappable point for the inner-diamond/chakra circles we
  /// don't yet get from the backend. The sheet will show just the arcana
  /// number + name (meaning blank until the backend grows these fields).
  DestinyPoint _virtual(String key, int arcana) => DestinyPoint(
        key: key,
        position: '',
        title: '',
        arcana: arcana,
        arcanaName: '',
        meaning: '',
      );

  /// Lays the per-year ladder out around the octagram perimeter. Age N sits
  /// at angle (N/80)*360° on a circle of [radius], measured the same way
  /// the corners are placed so the rungs land between their corner anchors.
  /// Corner rungs (10/20/.../80) are skipped — the corner bubble already
  /// shows them, and overlapping the two reads as visual noise.
  ///
  /// Density: when [everyYear] is true every non-corner rung shows; when
  /// false only every 5th year (5,15,25,…) is drawn — quieter and easier
  /// to read at a glance. The in-between rungs are emitted with a hidden
  /// opacity in the cleaner mode and crossfade in when the toggle flips,
  /// so the transition animates smoothly instead of snapping.
  ///
  /// Color: each rung picks up the color of the closest age-decade arc.
  /// The 0→20 arc (purple corners on both ends) is painted purple, the
  /// 40→60 arc (red on both ends) is red, and the transitional arcs
  /// (20→40, 60→80) stay neutral so the karmic-year colors echo the
  /// corner bubbles without muddying the in-between segments.
  List<Widget> _buildPerimeterRungs({
    required List<AgeArcana> ladder,
    required Offset center,
    required double radius,
    required bool everyYear,
  }) {
    if (ladder.isEmpty) return const [];
    // Match the corner traversal: A is at 180°, the next corner TL is at
    // 225°, so the ladder walks clockwise starting from 180°. Each step
    // along the ladder advances 360° / 80 = 4.5°.
    const startDeg = 180.0;
    const stepDeg = 360.0 / 80;
    final neutralColor = Colors.white.withValues(alpha: 0.55);
    const purpleColor = Color(0xFFBA68C8);
    const redColor = Color(0xFFFF7043);
    final out = <Widget>[];
    for (final rung in ladder) {
      // Don't double-print the eight corner ages — they have full nodes.
      if (rung.age % 10 == 0) continue;
      final isAnchor = rung.age % 5 == 0;
      // In the cleaner mode the non-anchor rungs are still in the tree
      // (just transparent) so AnimatedOpacity has a stable child to
      // crossfade against when the toggle flips.
      final visible = everyYear || isAnchor;
      final angle = startDeg + rung.age * stepDeg;
      final pos = _polar(center, radius, angle);
      final color = _decadeColor(
        rung.age,
        purple: purpleColor,
        red: redColor,
        neutral: neutralColor,
      );
      // Stagger the fade slightly by age — the closer you are to an
      // anchor the sooner you appear, which makes the ring "fill in"
      // outward from each 5-year mark instead of all 56 rungs popping at
      // once. Anchor rungs are instant since they were already visible.
      final distanceFromAnchor = (rung.age % 5).clamp(0, 4);
      final duration = isAnchor
          ? Duration.zero
          : Duration(milliseconds: 180 + distanceFromAnchor * 60);
      out.add(
        Positioned(
          left: pos.dx - 14,
          top: pos.dy - 9,
          width: 28,
          height: 18,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1.0 : 0.0,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: Center(
                child: Text(
                  '${rung.arcana}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  /// Picks a perimeter color for [age] based on which arc it belongs to.
  /// 1-19 → purple (A/B corners both purple), 41-59 → red (C/D corners
  /// both red), everything else → neutral.
  Color _decadeColor(
    int age, {
    required Color purple,
    required Color red,
    required Color neutral,
  }) {
    if (age >= 1 && age <= 19) return purple;
    if (age >= 41 && age <= 59) return red;
    return neutral;
  }
}

Offset _polar(Offset center, double r, double degrees) {
  final rad = degrees * math.pi / 180;
  return Offset(
    center.dx + r * math.cos(rad),
    center.dy + r * math.sin(rad),
  );
}

/// Octagonal frame + two diagonal generation lines (purple male, red female).
class _MatrixFramePainter extends CustomPainter {
  _MatrixFramePainter({
    required this.center,
    required this.outerR,
    required this.innerR,
    required this.frameColor,
    required this.diamondColor,
    required this.maleColor,
    required this.femaleColor,
  });

  final Offset center;
  final double outerR;
  final double innerR;
  final Color frameColor;
  final Color diamondColor;
  final Color maleColor;
  final Color femaleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // Outer octagon: upright square + 45° diamond — together their corners
    // form the 8 octagram points.
    final upright = Path()
      ..addPolygon(
        [
          _polar(center, outerR, 225),
          _polar(center, outerR, 315),
          _polar(center, outerR, 45),
          _polar(center, outerR, 135),
        ],
        true,
      );
    final diamond = Path()
      ..addPolygon(
        [
          _polar(center, outerR, 270),
          _polar(center, outerR, 0),
          _polar(center, outerR, 90),
          _polar(center, outerR, 180),
        ],
        true,
      );
    canvas
      ..drawPath(upright, framePaint)
      ..drawPath(diamond, framePaint);

    // Inner diamond connecting the 4 small inner nodes.
    final innerPaint = Paint()
      ..color = diamondColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final innerDiamond = Path()
      ..addPolygon(
        [
          _polar(center, innerR, 225),
          _polar(center, innerR, 315),
          _polar(center, innerR, 45),
          _polar(center, innerR, 135),
        ],
        true,
      );
    canvas.drawPath(innerDiamond, innerPaint);

    // Generation lines: TL ↘ BR (male) and TR ↙ BL (female), each drawn
    // from the inner-diamond corner to the opposite inner-diamond corner
    // through the center, with arrowheads at both ends.
    _drawDiagonal(canvas, 225, 45, maleColor);
    _drawDiagonal(canvas, 315, 135, femaleColor);
  }

  void _drawDiagonal(Canvas canvas, double fromDeg, double toDeg, Color color) {
    // Anchor on the inner-diamond corners (not the outer ones) so the
    // arrowheads sit visually inside the octagram, matching the reference.
    final from = _polar(center, innerR, fromDeg);
    final to = _polar(center, innerR, toDeg);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas
      ..drawLine(from, to, paint)
      ..drawPath(_arrowhead(from, to, color), Paint()..color = color)
      ..drawPath(_arrowhead(to, from, color), Paint()..color = color);
  }

  Path _arrowhead(Offset tip, Offset from, Color color) {
    final v = tip - from;
    final len = v.distance;
    if (len == 0) return Path();
    final dir = v / len;
    final perp = Offset(-dir.dy, dir.dx);
    const headLen = 10.0;
    const headWidth = 6.0;
    final base = tip - dir * headLen;
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx * headWidth, base.dy + perp.dy * headWidth)
      ..lineTo(base.dx - perp.dx * headWidth, base.dy - perp.dy * headWidth)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _MatrixFramePainter old) =>
      old.center != center ||
      old.outerR != outerR ||
      old.innerR != innerR ||
      old.frameColor != frameColor ||
      old.diamondColor != diamondColor ||
      old.maleColor != maleColor ||
      old.femaleColor != femaleColor;
}

/// A short generation-line label drawn rotated along its diagonal.
class _DiagonalLabel extends StatelessWidget {
  const _DiagonalLabel({
    required this.text,
    required this.center,
    required this.radius,
    required this.angleDeg,
    required this.color,
  });
  final String text;
  final Offset center;
  final double radius;
  final double angleDeg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pos = _polar(center, radius, angleDeg);
    // Rotate so text reads along the diagonal: 45° for ↘/↖, -45° for ↙/↗.
    final isMain = angleDeg == 225 || angleDeg == 45;
    final rotation = (isMain ? -math.pi / 4 : math.pi / 4);
    return Positioned(
      left: pos.dx - 70,
      top: pos.dy - 8,
      width: 140,
      child: Transform.rotate(
        angle: rotation,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// A small "X\nyears old" caption laid out along the radial of a corner so
/// the top corner gets it above, the bottom corner gets it below, etc.
class _AgeLabel extends StatelessWidget {
  const _AgeLabel({
    required this.center,
    required this.radius,
    required this.angleDeg,
    required this.age,
  });
  final Offset center;
  final double radius;
  final double angleDeg;
  final int age;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pos = _polar(center, radius, angleDeg);
    const w = 60.0;
    const h = 26.0;
    return Positioned(
      left: pos.dx - w / 2,
      top: pos.dy - h / 2,
      width: w,
      height: h,
      child: Center(
        child: Text(
          '$age\nyears old',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 9,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Inline ❤ / $ marker — a small icon on top of a small numbered circle.
class _ChakraMarker extends StatelessWidget {
  const _ChakraMarker({
    required this.icon,
    required this.color,
    required this.arcana,
    required this.position,
  });
  final IconData icon;
  final Color color;
  final int arcana;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          Text(
            '$arcana',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual styles for the different node tiers — controls fill, border,
/// and number color.
enum _NodeKind { center, purpleCorner, redCorner, plainCorner, inner }

class _Node extends StatelessWidget {
  const _Node({
    required this.point,
    required this.radius,
    required this.kind,
  });
  final DestinyPoint? point;
  final double radius;
  final _NodeKind kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = point?.arcana ?? 0;
    final filled = switch (kind) {
      _NodeKind.center => true,
      _NodeKind.purpleCorner => true,
      _NodeKind.redCorner => true,
      _NodeKind.plainCorner => false,
      _NodeKind.inner => false,
    };
    final fillColor = switch (kind) {
      _NodeKind.center => const Color(0xFFFFD54F),
      _NodeKind.purpleCorner => const Color(0xFF7B3FA0),
      _NodeKind.redCorner => const Color(0xFFE53935),
      _NodeKind.plainCorner => p.surface,
      _NodeKind.inner => p.surface,
    };
    final borderColor = switch (kind) {
      _NodeKind.center => const Color(0xFFFFE082),
      _NodeKind.purpleCorner => const Color(0xFFBA68C8),
      _NodeKind.redCorner => const Color(0xFFFF7043),
      _NodeKind.plainCorner => p.textPrimary.withValues(alpha: 0.85),
      _NodeKind.inner => p.textSecondary.withValues(alpha: 0.6),
    };
    final textColor = filled ? Colors.white : p.textPrimary;
    final glowAlpha = switch (kind) {
      _NodeKind.center => 0.45,
      _NodeKind.purpleCorner => 0.30,
      _NodeKind.redCorner => 0.30,
      _NodeKind.plainCorner => 0.0,
      _NodeKind.inner => 0.0,
    };

    return GestureDetector(
      onTap: point == null ? null : () => _showPointSheet(context, point!),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor,
          border: Border.all(color: borderColor, width: filled ? 1.6 : 1.4),
          boxShadow: glowAlpha == 0
              ? null
              : [
                  BoxShadow(
                    color: fillColor.withValues(alpha: glowAlpha),
                    blurRadius: 14,
                  ),
                ],
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$value',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OctagramHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      'Tap any node to read its arcana.',
      textAlign: TextAlign.center,
      style: TextStyle(color: p.textTertiary, fontSize: 12),
    );
  }
}

void _showPointSheet(BuildContext context, DestinyPoint point) {
  final p = context.palette;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${point.arcana}',
                      style: TextStyle(
                        color: p.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.arcanaName,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          point.title,
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                point.meaning,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Lines.
// ---------------------------------------------------------------------------

/// Collapsible Line card. The header (title + arcana names + chevron) is
/// always visible; tapping anywhere on the header expands or shrinks the
/// theme paragraph below. Animates between states for visual feedback.
class _LineCard extends StatefulWidget {
  const _LineCard({required this.line, required this.reading});
  final DestinyLine line;
  final DestinyMatrixReading reading;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final names = <String>[
      for (final key in widget.line.pointKeys)
        if ((widget.reading.pointFor(key)?.arcanaName ?? '').isNotEmpty)
          widget.reading.pointFor(key)!.arcanaName,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.textTertiary.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.line.title,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: p.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                if (names.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    names.join('  ·  '),
                    style: TextStyle(
                      color: p.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      widget.line.theme,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chrome helpers.
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      text,
      style: TextStyle(
        color: p.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Simple entry fade+slide used to stagger the body children.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, required this.delayMs});
  final Widget child;
  final int delayMs;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
