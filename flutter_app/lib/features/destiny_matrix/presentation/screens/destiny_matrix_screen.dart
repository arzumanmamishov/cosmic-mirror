import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/providers/destiny_matrix_providers.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Palette constants for the octagram (independent of the gold app theme so the
// chakra spectrum reads the same in light and dark).
// ---------------------------------------------------------------------------

const _violet = Color(0xFF8E5BD6); // diamond top/left, chakra crown
const _violetDeep = Color(0xFF6A3FB0);
const _red = Color(0xFFE0524E); // diamond right/bottom, root chakra
const _redDeep = Color(0xFFB83C38);
const _gold = Color(0xFFF2C84B); // center / heart chakra
const _male = Color(0xFF7B61FF); // paternal generation diagonal
const _female = Color(0xFFE0524E); // maternal generation diagonal
const _money = Color(0xFF5BB97A); // money line accent

/// Seven chakra spectrum colors (crown -> root) used for the inner arm nodes.
const _chakraSpectrum = <Color>[
  Color(0xFF8E5BD6), // crown   - violet
  Color(0xFF5C6BD6), // third eye - indigo
  Color(0xFF4FA3E0), // throat  - blue
  Color(0xFF5BB97A), // heart   - green
  Color(0xFFF2C84B), // solar   - yellow
  Color(0xFFE08A3C), // sacral  - orange
  Color(0xFFE0524E), // root    - red
];

class DestinyMatrixScreen extends ConsumerWidget {
  const DestinyMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          data: (reading) => _Body(reading: reading),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reading});
  final DestinyMatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _Hero(reading: reading),
      const SizedBox(height: 20),
      const _SectionLabel('Your Octagram'),
      const SizedBox(height: 12),
      _OctagramCard(reading: reading),
      const SizedBox(height: 8),
      const _OctagramHint(),
      const SizedBox(height: 24),
      const _SectionLabel('Purpose'),
      const SizedBox(height: 12),
      _PurposeCard(reading: reading),
      const SizedBox(height: 24),
      const _SectionLabel('The Lines'),
      const SizedBox(height: 12),
      ...reading.lines.map((l) => _LineCard(line: l, reading: reading)),
      const SizedBox(height: 40),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 0),
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
    final core = reading.pointFor('center');
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
// Octagram card.
// ---------------------------------------------------------------------------

class _OctagramCard extends StatelessWidget {
  const _OctagramCard({required this.reading});
  final DestinyMatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.gold.withValues(alpha: 0.3)),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return _OctagramBoard(reading: reading, size: size);
          },
        ),
      ),
    );
  }
}

/// Geometry + node layout for the full octagram. Screen-space angles: 0° =
/// right, 90° = down, measured clockwise. The diamond cardinals sit on the
/// cardinal axes (Day=180° left, Month=270° up, Year=0° right, Sum=90° down);
/// the square corners sit on the diagonals (TL=225°, TR=315°, BR=45°, BL=135°).
class _OctagramBoard extends StatelessWidget {
  const _OctagramBoard({required this.reading, required this.size});
  final DestinyMatrixReading reading;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shortest = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    // Radii. The outer ring (cardinals + corners) hugs the edge with room for
    // age labels; arm/diagonal nodes step inward from there to the center.
    final outerR = shortest * 0.40;
    final cardinalRadius = (shortest * 0.072).clamp(20.0, 34.0);
    final cornerRadius = (shortest * 0.066).clamp(18.0, 30.0);
    final centerRadius = (shortest * 0.078).clamp(24.0, 38.0);
    final innerRadius = (shortest * 0.045).clamp(13.0, 20.0);

    // Fractions along an edge for the 3 inner nodes, ordered [nearP, mid,
    // nearCenter]. 0 = at the outer point, 1 = at the center.
    const innerFractions = <double>[0.28, 0.52, 0.76];

    Offset polar(double r, double deg) => _polar(center, r, deg);

    // Outer point screen positions, keyed.
    final outerPos = <String, Offset>{
      'day': polar(outerR, 180),
      'month': polar(outerR, 270),
      'year': polar(outerR, 0),
      'sum': polar(outerR, 90),
      'tl': polar(outerR, 225),
      'tr': polar(outerR, 315),
      'br': polar(outerR, 45),
      'bl': polar(outerR, 135),
    };

    final children = <Widget>[
      // Painted frame: square + diamond + octagram edges + generation lines.
      Positioned.fill(
        child: CustomPaint(
          painter: _OctagramPainter(
            center: center,
            outerR: outerR,
            frameColor: p.textTertiary.withValues(alpha: 0.45),
            edgeColor: p.textTertiary.withValues(alpha: 0.28),
            maleColor: _male,
            femaleColor: _female,
          ),
        ),
      ),

      // Generation-line labels.
      _DiagonalLabel(
        text: 'male generation line',
        center: center,
        radius: outerR * 0.62,
        angleDeg: 225,
        color: _male,
      ),
      _DiagonalLabel(
        text: 'female generation line',
        center: center,
        radius: outerR * 0.62,
        angleDeg: 315,
        color: _female,
      ),

      // Perimeter age ladder (tiny numbers + corner age labels).
      ..._buildPerimeter(center: center, outerR: outerR),
    ];

    // Inner cross-arm nodes (chakra spectrum), each running cardinal -> center.
    const armSpecs = <(String, List<String>)>[
      ('day', ['arm_left_1', 'arm_left_2', 'arm_left_3']),
      ('month', ['arm_top_1', 'arm_top_2', 'arm_top_3']),
      ('year', ['arm_right_1', 'arm_right_2', 'arm_right_3']),
      ('sum', ['arm_bottom_1', 'arm_bottom_2', 'arm_bottom_3']),
    ];
    for (final spec in armSpecs) {
      children.addAll(
        _edgeNodes(
          reading: reading,
          keys: spec.$2,
          from: outerPos[spec.$1]!,
          center: center,
          fractions: innerFractions,
          radius: innerRadius,
          chakra: true,
        ),
      );
    }

    // Inner diagonal nodes (generation lines), each running corner -> center.
    const diagSpecs = <(String, List<String>, Color)>[
      ('tl', ['diag_tl_1', 'diag_tl_2', 'diag_tl_3'], _male),
      ('tr', ['diag_tr_1', 'diag_tr_2', 'diag_tr_3'], _female),
      ('br', ['diag_br_1', 'diag_br_2', 'diag_br_3'], _male),
      ('bl', ['diag_bl_1', 'diag_bl_2', 'diag_bl_3'], _female),
    ];
    for (final spec in diagSpecs) {
      children.addAll(
        _edgeNodes(
          reading: reading,
          keys: spec.$2,
          from: outerPos[spec.$1]!,
          center: center,
          fractions: innerFractions,
          radius: innerRadius,
          chakra: false,
          diagColor: spec.$3,
        ),
      );
    }

    children.addAll([
      // Heart marker (lower-center) and money marker (lower-right).
      _GlyphMarker(
        icon: Icons.favorite,
        color: _female,
        position: polar(outerR * 0.30, 90),
      ),
      _GlyphMarker(
        icon: Icons.attach_money,
        color: _money,
        position: polar(outerR * 0.40, 55),
      ),
      // Outer cardinal nodes (diamond) — filled, tinted.
      _placeNode(
        point: reading.pointFor('day'),
        position: outerPos['day']!,
        radius: cardinalRadius,
        kind: _NodeKind.violet,
      ),
      _placeNode(
        point: reading.pointFor('month'),
        position: outerPos['month']!,
        radius: cardinalRadius,
        kind: _NodeKind.violet,
      ),
      _placeNode(
        point: reading.pointFor('year'),
        position: outerPos['year']!,
        radius: cardinalRadius,
        kind: _NodeKind.red,
      ),
      _placeNode(
        point: reading.pointFor('sum'),
        position: outerPos['sum']!,
        radius: cardinalRadius,
        kind: _NodeKind.red,
      ),
      // Outer corner nodes (square) — outlined.
      for (final key in const ['tl', 'tr', 'br', 'bl'])
        _placeNode(
          point: reading.pointFor(key),
          position: outerPos[key]!,
          radius: cornerRadius,
          kind: _NodeKind.corner,
        ),
      // Center node (destiny core, gold).
      _placeNode(
        point: reading.pointFor('center'),
        position: center,
        radius: centerRadius,
        kind: _NodeKind.center,
      ),
    ]);

    return Stack(clipBehavior: Clip.none, children: children);
  }

  /// Returns 3 nodes laid along the edge from [from] to [center] at the given
  /// [fractions] (0 = at the outer point, 1 = at the center). Defensive: skips
  /// any index past the shorter of [keys]/[fractions].
  List<Widget> _edgeNodes({
    required DestinyMatrixReading reading,
    required List<String> keys,
    required Offset from,
    required Offset center,
    required List<double> fractions,
    required double radius,
    required bool chakra,
    Color? diagColor,
  }) {
    final out = <Widget>[];
    final count = math.min(keys.length, fractions.length);
    for (var i = 0; i < count; i++) {
      final t = fractions[i];
      final pos = Offset.lerp(from, center, t)!;
      final Color color;
      if (chakra) {
        // Map the node's fractional distance from center onto the spectrum:
        // closer to the outer cardinal = crown end, closer to center = warm.
        final idx = (t * (_chakraSpectrum.length - 1))
            .round()
            .clamp(0, _chakraSpectrum.length - 1);
        color = _chakraSpectrum[idx];
      } else {
        color = diagColor ?? const Color(0xFF9E9E9E);
      }
      out.add(
        _placeNode(
          point: reading.pointFor(keys[i]),
          position: pos,
          radius: radius,
          kind: _NodeKind.inner,
          innerColor: color,
        ),
      );
    }
    return out;
  }

  Widget _placeNode({
    required DestinyPoint? point,
    required Offset position,
    required double radius,
    required _NodeKind kind,
    Color? innerColor,
  }) {
    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      child: _Node(
        point: point,
        radius: radius,
        kind: kind,
        innerColor: innerColor,
      ),
    );
  }

  /// Builds the perimeter age ring: the 8 corner age labels just outside their
  /// corner, plus the 7 small tick numbers per edge laid along the octagon.
  List<Widget> _buildPerimeter({
    required Offset center,
    required double outerR,
  }) {
    final ladder = reading.ageLadder;
    if (ladder.isEmpty) return const [];

    // Angle (screen degrees) for each decade corner, clockwise from Day(0°age)
    // at 180°. Ages 0,10,20,... -> 180,225,270,315,0,45,90,135.
    const cornerAngles = <double>[180, 225, 270, 315, 0, 45, 90, 135];

    final ringR = outerR * 1.06;
    final labelR = outerR * 1.20;

    final out = <Widget>[];
    for (final rung in ladder) {
      final edge = (rung.age / 10).floor().clamp(0, 7);
      final startDeg = cornerAngles[edge];
      // Each edge spans +45° of screen angle over 10 years.
      final frac = (rung.age - edge * 10) / 10.0;
      final deg = startDeg + 45.0 * frac;

      if (rung.isCorner) {
        // Corner age label, just outside the corner.
        final pos = _polar(center, labelR, deg);
        out.add(_AgeLabel(position: pos, label: rung.label));
      } else {
        // Tiny tick number on the ring.
        final pos = _polar(center, ringR, deg);
        out.add(
          Positioned(
            left: pos.dx - 11,
            top: pos.dy - 8,
            width: 22,
            height: 16,
            child: Center(
              child: Text(
                '${rung.arcana}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _edgeColor(rung.age).withValues(alpha: 0.85),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      }
    }
    return out;
  }

  /// Perimeter tint by life arc: youth (purple), midlife (red), else neutral.
  Color _edgeColor(double age) {
    if (age < 20) return _violet;
    if (age >= 40 && age < 60) return _red;
    return const Color(0xFF9E9E9E);
  }
}

Offset _polar(Offset center, double r, double degrees) {
  final rad = degrees * math.pi / 180;
  return Offset(
    center.dx + r * math.cos(rad),
    center.dy + r * math.sin(rad),
  );
}

// ---------------------------------------------------------------------------
// Painter: square + diamond + octagram edges + generation diagonals.
// ---------------------------------------------------------------------------

class _OctagramPainter extends CustomPainter {
  _OctagramPainter({
    required this.center,
    required this.outerR,
    required this.frameColor,
    required this.edgeColor,
    required this.maleColor,
    required this.femaleColor,
  });

  final Offset center;
  final double outerR;
  final Color frameColor;
  final Color edgeColor;
  final Color maleColor;
  final Color femaleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    Offset at(double deg) => _polar(center, outerR, deg);

    // Upright square through the four corners (225/315/45/135).
    final square = Path()
      ..addPolygon([at(225), at(315), at(45), at(135)], true);
    // 45° diamond through the four cardinals (270/0/90/180).
    final diamond = Path()..addPolygon([at(270), at(0), at(90), at(180)], true);
    canvas
      ..drawPath(square, framePaint)
      ..drawPath(diamond, framePaint);

    // Octagram outline edges connecting adjacent outer points (cardinal ->
    // corner -> cardinal) so the 8-point star reads cleanly.
    final edgePaint = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const order = <double>[180, 225, 270, 315, 0, 45, 90, 135];
    final octagon = Path()..addPolygon([for (final d in order) at(d)], true);
    canvas.drawPath(octagon, edgePaint);

    // Cross arms (faint guide lines cardinal -> center).
    final armPaint = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final d in const [180.0, 270.0, 0.0, 90.0]) {
      canvas.drawLine(at(d), center, armPaint);
    }

    // Generation diagonals: TL(225) <-> BR(45) male, TR(315) <-> BL(135)
    // female. Drawn corner-to-corner through the center with arrowheads.
    _drawDiagonal(canvas, 225, 45, maleColor);
    _drawDiagonal(canvas, 315, 135, femaleColor);
  }

  void _drawDiagonal(Canvas canvas, double fromDeg, double toDeg, Color color) {
    final from = _polar(center, outerR * 0.82, fromDeg);
    final to = _polar(center, outerR * 0.82, toDeg);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fill = Paint()..color = color;
    canvas
      ..drawLine(from, to, paint)
      ..drawPath(_arrowhead(from, to), fill)
      ..drawPath(_arrowhead(to, from), fill);
  }

  Path _arrowhead(Offset tip, Offset from) {
    final v = tip - from;
    final len = v.distance;
    if (len == 0) return Path();
    final dir = v / len;
    final perp = Offset(-dir.dy, dir.dx);
    const headLen = 11.0;
    const headWidth = 6.0;
    final base = tip - dir * headLen;
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx * headWidth, base.dy + perp.dy * headWidth)
      ..lineTo(base.dx - perp.dx * headWidth, base.dy - perp.dy * headWidth)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _OctagramPainter old) =>
      old.center != center ||
      old.outerR != outerR ||
      old.frameColor != frameColor ||
      old.edgeColor != edgeColor ||
      old.maleColor != maleColor ||
      old.femaleColor != femaleColor;
}

// ---------------------------------------------------------------------------
// Overlays.
// ---------------------------------------------------------------------------

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
    final isMain = angleDeg == 225 || angleDeg == 45;
    final rotation = isMain ? -math.pi / 4 : math.pi / 4;
    return Positioned(
      left: pos.dx - 64,
      top: pos.dy - 7,
      width: 128,
      child: Transform.rotate(
        angle: rotation,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _AgeLabel extends StatelessWidget {
  const _AgeLabel({required this.position, required this.label});
  final Offset position;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const w = 40.0;
    const h = 16.0;
    return Positioned(
      left: position.dx - w / 2,
      top: position.dy - h / 2,
      width: w,
      height: h,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// A small ❤ / $ glyph marker.
class _GlyphMarker extends StatelessWidget {
  const _GlyphMarker({
    required this.icon,
    required this.color,
    required this.position,
  });
  final IconData icon;
  final Color color;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: Icon(icon, color: color.withValues(alpha: 0.9), size: size),
    );
  }
}

// ---------------------------------------------------------------------------
// Nodes.
// ---------------------------------------------------------------------------

enum _NodeKind { center, violet, red, corner, inner }

class _Node extends StatelessWidget {
  const _Node({
    required this.point,
    required this.radius,
    required this.kind,
    this.innerColor,
  });
  final DestinyPoint? point;
  final double radius;
  final _NodeKind kind;
  final Color? innerColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = point?.arcana ?? 0;

    final bool filled;
    final Color fillColor;
    final Color borderColor;
    final double glowAlpha;
    switch (kind) {
      case _NodeKind.center:
        filled = true;
        fillColor = _gold;
        borderColor = const Color(0xFFFFE08A);
        glowAlpha = 0.45;
      case _NodeKind.violet:
        filled = true;
        fillColor = _violet;
        borderColor = _violetDeep;
        glowAlpha = 0.30;
      case _NodeKind.red:
        filled = true;
        fillColor = _red;
        borderColor = _redDeep;
        glowAlpha = 0.30;
      case _NodeKind.corner:
        filled = false;
        fillColor = p.surface;
        borderColor = p.textPrimary.withValues(alpha: 0.85);
        glowAlpha = 0;
      case _NodeKind.inner:
        filled = true;
        fillColor = innerColor ?? p.surface;
        borderColor = (innerColor ?? p.textSecondary).withValues(alpha: 0.9);
        glowAlpha = 0;
    }

    final textColor = filled ? _onColor(fillColor) : p.textPrimary;

    return GestureDetector(
      onTap: point == null ? null : () => _showPointSheet(context, point!),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor,
          border: Border.all(color: borderColor, width: filled ? 1.4 : 1.4),
          boxShadow: glowAlpha == 0
              ? null
              : [
                  BoxShadow(
                    color: fillColor.withValues(alpha: glowAlpha),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              '$value',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Picks a readable text color (dark or white) for a filled node.
  Color _onColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.55 ? const Color(0xFF1A1408) : Colors.white;
  }
}

class _OctagramHint extends StatelessWidget {
  const _OctagramHint();

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
      final hasName = point.arcanaName.isNotEmpty;
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
                          hasName ? point.arcanaName : 'Arcana ${point.arcana}',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (point.title.isNotEmpty) ...[
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
                      ],
                    ),
                  ),
                ],
              ),
              if (point.meaning.isNotEmpty) ...[
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
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Purpose card (Heaven / Earth / Personal).
// ---------------------------------------------------------------------------

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({required this.reading});
  final DestinyMatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <(String, String)>[
      ('Sky', 'heaven'),
      ('Earth', 'earth'),
      ('Personal', 'personal'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.textTertiary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 18,
                color: p.textTertiary.withValues(alpha: 0.15),
              ),
            _purposeRow(context, label: rows[i].$1, key: rows[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _purposeRow(
    BuildContext context, {
    required String label,
    required String key,
  }) {
    final p = context.palette;
    final point = reading.pointFor(key);
    return InkWell(
      onTap: point == null ? null : () => _showPointSheet(context, point),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.gold.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${point?.arcana ?? 0}',
                style: TextStyle(
                  color: p.gold,
                  fontSize: 17,
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
                    '$label Purpose',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    point?.arcanaName ?? '',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Line cards.
// ---------------------------------------------------------------------------

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

  Color _accent(BuildContext context) {
    switch (widget.line.key) {
      case 'maleGeneration':
        return _male;
      case 'femaleGeneration':
        return _female;
      case 'money':
        return _money;
      case 'love':
        return _female;
      default:
        return context.palette.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Sequence of arcana numbers along the line (defensive: skip missing).
    final values = <int>[
      for (final key in widget.line.pointKeys)
        if ((widget.reading.pointFor(key)?.arcana ?? 0) > 0)
          widget.reading.pointFor(key)!.arcana,
    ];
    final accent = _accent(context);
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
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
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
                if (values.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    values.join('  ›  '),
                    style: TextStyle(
                      color: accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
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

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, required this.delayMs});
  final Widget child;
  final int delayMs;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
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
