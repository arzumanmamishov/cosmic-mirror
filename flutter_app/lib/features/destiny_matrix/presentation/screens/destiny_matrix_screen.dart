import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/providers/destiny_matrix_providers.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The eight outer point keys (excluding center "E"), in octagram order.
const _outerKeys = ['A', 'B', 'C', 'D', 'TL', 'TR', 'BR', 'BL'];

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
      _Octagram(reading: reading),
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

class _Octagram extends StatelessWidget {
  const _Octagram({required this.reading});
  final DestinyMatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
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
            final nodeRadius = (size.shortestSide * 0.11).clamp(20.0, 40.0);
            return Stack(
              children: [
                // The two overlapping squares forming the 8-pointed star.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OctagramPainter(
                      lineColor: p.gold.withValues(alpha: 0.55),
                      diamondColor: p.accent.withValues(alpha: 0.55),
                      spokeColor: p.textTertiary.withValues(alpha: 0.25),
                      inset: nodeRadius,
                    ),
                  ),
                ),
                // The nine nodes.
                ..._buildNodes(context, size, nodeRadius),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildNodes(
    BuildContext context,
    Size size,
    double nodeRadius,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    // Outer points sit on a circle inset by the node radius so they don't
    // clip the card edges.
    final r = size.shortestSide / 2 - nodeRadius;
    final positions = <String, Offset>{
      'E': center,
      'B': Offset(center.dx, center.dy - r), // top
      'D': Offset(center.dx, center.dy + r), // bottom
      'A': Offset(center.dx - r, center.dy), // left
      'C': Offset(center.dx + r, center.dy), // right
      'TL': _diag(center, r, 225), // top-left
      'TR': _diag(center, r, 315), // top-right
      'BR': _diag(center, r, 45), // bottom-right
      'BL': _diag(center, r, 135), // bottom-left
    };

    final keys = ['E', ..._outerKeys];
    return [
      for (final key in keys)
        if (positions[key] != null)
          Positioned(
            left: positions[key]!.dx - nodeRadius,
            top: positions[key]!.dy - nodeRadius,
            child: _Node(
              point: reading.pointFor(key),
              radius: nodeRadius,
              isCenter: key == 'E',
            ),
          ),
    ];
  }

  /// Point on a circle of radius [r] around [center] at [degrees]
  /// (0 = +x axis, clockwise in screen coordinates where +y is down).
  Offset _diag(Offset center, double r, double degrees) {
    final rad = degrees * math.pi / 180;
    return Offset(
      center.dx + r * math.cos(rad),
      center.dy + r * math.sin(rad),
    );
  }
}

class _OctagramPainter extends CustomPainter {
  _OctagramPainter({
    required this.lineColor,
    required this.diamondColor,
    required this.spokeColor,
    required this.inset,
  });

  final Color lineColor;
  final Color diamondColor;
  final Color spokeColor;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - inset;

    // Faint spokes from center to each outer node.
    final spoke = Paint()
      ..color = spokeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var deg = 0; deg < 360; deg += 45) {
      final rad = deg * math.pi / 180;
      canvas.drawLine(
        center,
        Offset(center.dx + r * math.cos(rad), center.dy + r * math.sin(rad)),
        spoke,
      );
    }

    // Upright square (corners at the diagonals: TL,TR,BR,BL).
    final square = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final squarePath = Path()
      ..addPolygon(
        [
          _pt(center, r, 225),
          _pt(center, r, 315),
          _pt(center, r, 45),
          _pt(center, r, 135),
        ],
        true,
      );
    canvas.drawPath(squarePath, square);

    // 45-degree diamond (corners at the orthogonals: A,B,C,D).
    final diamond = Paint()
      ..color = diamondColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final diamondPath = Path()
      ..addPolygon(
        [
          _pt(center, r, 270), // top (B)
          _pt(center, r, 0), // right (C)
          _pt(center, r, 90), // bottom (D)
          _pt(center, r, 180), // left (A)
        ],
        true,
      );
    canvas.drawPath(diamondPath, diamond);
  }

  Offset _pt(Offset center, double r, double degrees) {
    final rad = degrees * math.pi / 180;
    return Offset(
      center.dx + r * math.cos(rad),
      center.dy + r * math.sin(rad),
    );
  }

  @override
  bool shouldRepaint(covariant _OctagramPainter old) =>
      old.lineColor != lineColor ||
      old.diamondColor != diamondColor ||
      old.spokeColor != spokeColor ||
      old.inset != inset;
}

class _Node extends StatelessWidget {
  const _Node({
    required this.point,
    required this.radius,
    required this.isCenter,
  });
  final DestinyPoint? point;
  final double radius;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = point?.arcana ?? 0;
    final color = isCenter ? p.primary : p.gold;
    return GestureDetector(
      onTap: point == null ? null : () => _showPointSheet(context, point!),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: isCenter ? 0.35 : 0.22),
              color.withValues(alpha: isCenter ? 0.18 : 0.10),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: isCenter ? 0.9 : 0.6),
            width: isCenter ? 2.4 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 10,
            ),
          ],
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              '$value',
              style: TextStyle(
                color: color,
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

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line, required this.reading});
  final DestinyLine line;
  final DestinyMatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final names = <String>[
      for (final key in line.pointKeys)
        if ((reading.pointFor(key)?.arcanaName ?? '').isNotEmpty)
          reading.pointFor(key)!.arcanaName,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.textTertiary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.title,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
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
          const SizedBox(height: 8),
          Text(
            line.theme,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
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
