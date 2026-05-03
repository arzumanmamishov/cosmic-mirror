import 'dart:math';

import 'package:flutter/material.dart';

/// CosmicStarfield paints a generated field of stars with subtle twinkling.
/// Use it as a background overlay behind any cosmic page.
///
/// Performance notes:
/// - Stars are generated once with a fixed seed (so the layout is stable
///   across rebuilds and looks intentional, not chaotic).
/// - The animation only repaints opacity, not geometry, so it stays cheap
///   even on web.
class CosmicStarfield extends StatefulWidget {
  const CosmicStarfield({
    super.key,
    this.starCount = 60,
    this.color = Colors.white,
    this.seed = 42,
    this.intensity = 1.0,
  });

  final int starCount;
  final Color color;
  final int seed;

  /// 0.0 disables twinkling, 1.0 is the default subtle effect.
  final double intensity;

  @override
  State<CosmicStarfield> createState() => _CosmicStarfieldState();
}

class _CosmicStarfieldState extends State<CosmicStarfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    final rng = Random(widget.seed);
    _stars = List.generate(widget.starCount, (_) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.5 + rng.nextDouble() * 1.6,
        baseOpacity: 0.25 + rng.nextDouble() * 0.6,
        phase: rng.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _StarfieldPainter(
              stars: _stars,
              t: _ctrl.value,
              color: widget.color,
              intensity: widget.intensity,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final double baseOpacity;
  final double phase;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({
    required this.stars,
    required this.t,
    required this.color,
    required this.intensity,
  });

  final List<_Star> stars;
  final double t;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      // Subtle twinkle: oscillate opacity by up to ±35% around base.
      final wave = sin(t * 2 * pi + s.phase);
      final opacity =
          (s.baseOpacity + wave * 0.18 * intensity).clamp(0.05, 1.0);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) =>
      old.t != t || old.color != color;
}
