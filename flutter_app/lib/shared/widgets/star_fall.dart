import 'dart:math';

import 'package:flutter/material.dart';

/// StarFall — a synchronized cycle of shooting stars that traverse the
/// full screen diagonally, fading in just past the upper-left edge and
/// fading out as they exit the lower-right edge.
///
/// Stars overlap by exactly half of their duration: as soon as one
/// reaches the midpoint of its run, the next one starts, so the screen
/// always has at least one streak in flight.
class StarFall extends StatefulWidget {
  const StarFall({
    super.key,
    this.starCount = 3,
    this.color = Colors.white,
    this.seed = 7,
    this.starDuration = const Duration(seconds: 22),
  });

  final int starCount;
  final Color color;
  final int seed;

  /// How long each individual star is visible (entry + drift + exit).
  final Duration starDuration;

  @override
  State<StarFall> createState() => _StarFallState();
}

class _StarFallState extends State<StarFall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_ShootingStar> _stars;
  late final List<double> _phases;
  late final double _starDurSeconds;

  /// Offset between successive stars — half the per-star duration so the
  /// next star kicks off exactly as the previous one hits its midpoint.
  late final double _gap;

  /// One full rotation of all stars before star 0 returns.
  late final double _cycle;

  double _masterTime = 0;

  @override
  void initState() {
    super.initState();
    _starDurSeconds = widget.starDuration.inMilliseconds / 1000;
    _gap = _starDurSeconds / 2;
    _cycle = _gap * widget.starCount;

    final rng = Random(widget.seed);

    // Each star starts above the upper-left edge and drifts diagonally
    // through the entire screen, exiting bottom-right. We stagger
    // their entry points and randomize per-star speed, angle, length and
    // thickness so the cycle feels organic rather than identical streaks.
    _stars = List.generate(widget.starCount, (i) {
      // Spread entry points across the top edge with jitter so they
      // never look perfectly evenly spaced.
      final slot = (i + 0.5) / widget.starCount * 0.9;
      final jitter = (rng.nextDouble() - 0.5) * 0.10;
      final startX = (-0.15 + slot + jitter).clamp(-0.2, 0.7);

      // Speed varies per star — some drift slower than others, but all
      // slow enough that the screen still feels calm. Each star covers
      // roughly 1.4–1.7 screen fractions over its lifetime.
      final travelDistance = 1.4 + rng.nextDouble() * 0.3;

      // Angle varies more widely (35°–55°) so streaks aren't parallel.
      final angle = (pi / 4) + (rng.nextDouble() - 0.5) * pi / 9;

      return _ShootingStar(
        startX: startX,
        startY: -0.18 - rng.nextDouble() * 0.18,
        angle: angle,
        speed: travelDistance / _starDurSeconds,
        length: 0.045 + rng.nextDouble() * 0.06,
        thickness: 0.9 + rng.nextDouble() * 1.0,
        flickerSeed: rng.nextDouble() * 100,
      );
    });

    // Initial phase per star: 0, gap, 2*gap, ... Each phase will be
    // bumped by `_cycle` whenever its star finishes, so the stars
    // perpetually loop without ever resetting masterTime.
    _phases = List<double>.generate(widget.starCount, (i) => i * _gap);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
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
          _masterTime += 1 / 60;
          // Bump each star's phase forward by one full cycle whenever it
          // finishes its run, so it'll re-appear later in its same slot.
          for (var i = 0; i < _phases.length; i++) {
            if (_masterTime > _phases[i] + _starDurSeconds) {
              _phases[i] += _cycle;
            }
          }
          return CustomPaint(
            painter: _StarFallPainter(
              stars: _stars,
              phases: _phases,
              masterTime: _masterTime,
              starDuration: _starDurSeconds,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ShootingStar {
  const _ShootingStar({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.length,
    required this.thickness,
    required this.flickerSeed,
  });

  final double startX;
  final double startY;
  final double angle;
  final double speed;
  final double length;
  final double thickness;

  /// Per-star phase offset that shifts the subtle brightness flicker so
  /// no two stars pulse in lockstep — makes the cycle look natural.
  final double flickerSeed;
}

class _StarFallPainter extends CustomPainter {
  _StarFallPainter({
    required this.stars,
    required this.phases,
    required this.masterTime,
    required this.starDuration,
    required this.color,
  });

  final List<_ShootingStar> stars;
  final List<double> phases;
  final double masterTime;
  final double starDuration;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      final life = masterTime - phases[i];
      if (life < 0 || life > starDuration) continue;
      final t = (life / starDuration).clamp(0.0, 1.0);

      final dx = cos(s.angle) * s.speed * life;
      final dy = sin(s.angle) * s.speed * life;
      final headX = (s.startX + dx) * size.width;
      final headY = (s.startY + dy) * size.height;

      final tailX = headX - cos(s.angle) * s.length * size.width;
      final tailY = headY - sin(s.angle) * s.length * size.width;

      // Smoother organic envelope — sin curve so the brightness eases in
      // and out instead of abruptly hitting full opacity. A gentle flicker
      // (per-star phase) modulates the brightness slightly throughout the
      // streak so it reads as a real twinkling star, not a sliding dot.
      final envelope = sin(t * pi).clamp(0.0, 1.0);
      final flicker = 0.92 +
          0.08 * sin(life * 1.4 + s.flickerSeed) * 0.5 -
          0.02 * sin(life * 3.7 + s.flickerSeed * 1.3);
      final alpha = (envelope * flicker).clamp(0.0, 1.0) * 0.88;

      final shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: alpha),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
        Rect.fromPoints(Offset(tailX, tailY), Offset(headX, headY)),
      );
      final trailPaint = Paint()
        ..shader = shader
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s.thickness;
      canvas
        ..drawLine(Offset(tailX, tailY), Offset(headX, headY), trailPaint)
        ..drawCircle(
          Offset(headX, headY),
          s.thickness * 1.3,
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFallPainter old) =>
      old.masterTime != masterTime;
}
