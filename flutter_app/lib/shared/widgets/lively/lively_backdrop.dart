import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Full-bleed cosmic backdrop — a radial gradient ground plus a sparse,
/// deterministic starfield. On dark theme a faint gold aurora drifts near
/// the top; light theme gets only a whisper of dust.
///
/// The starfield is seeded, so a given [seed] always lays out the same way
/// (no shimmer-on-rebuild). About 30% of stars gently twinkle.
class LivelyBackdrop extends StatefulWidget {
  const LivelyBackdrop({
    required this.child,
    this.seed = 7,
    this.intensity = 1.0,
    super.key,
  });

  final Widget child;

  /// Deterministic layout seed — same seed → same star positions.
  final int seed;

  /// Scales the star count (0.6 = calmer, 1.4 = denser).
  final double intensity;

  @override
  State<LivelyBackdrop> createState() => _LivelyBackdropState();
}

class _LivelyBackdropState extends State<LivelyBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle;

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Radial cosmic ground — indigo core (dark) / warm cream (light) at the
    // top, fading down into the page background.
    final gradient = RadialGradient(
      center: const Alignment(0, -1.05),
      radius: 1.5,
      colors: isDark
          ? const [Color(0xFF1F2547), Color(0xFF11132A), Color(0xFF08080F)]
          : const [Color(0xFFF0E5CC), Color(0xFFF8F0DD), Color(0xFFFBF7EE)],
      stops: const [0.0, 0.38, 0.74],
    );

    final count = ((isDark ? 80 : 28) * widget.intensity).round();

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _twinkle,
                builder: (_, __) => CustomPaint(
                  painter: _StarfieldPainter(
                    seed: widget.seed,
                    count: count,
                    isDark: isDark,
                    starColor: isDark
                        ? const Color(0xFFFFF6E0)
                        : p.primary,
                    auroraColor: p.primary,
                    t: _twinkle.value,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _Star {
  _Star(this.dx, this.dy, this.r, this.a, this.twinkles, this.phase);
  final double dx; // 0..1
  final double dy; // 0..1
  final double r;
  final double a;
  final bool twinkles;
  final double phase;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({
    required this.seed,
    required this.count,
    required this.isDark,
    required this.starColor,
    required this.auroraColor,
    required this.t,
  });

  final int seed;
  final int count;
  final bool isDark;
  final Color starColor;
  final Color auroraColor;
  final double t;

  // Cache the generated layout per (seed,count) so it doesn't regenerate
  // on every twinkle frame.
  static final Map<String, List<_Star>> _cache = {};

  List<_Star> _stars() {
    final key = '$seed-$count';
    final cached = _cache[key];
    if (cached != null) return cached;
    // tiny LCG, matching the design's deterministic field.
    var s = seed & 0xFFFFFFFF;
    double rnd() {
      s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
      return s / 4294967296.0;
    }

    final out = <_Star>[];
    for (var i = 0; i < count; i++) {
      final big = rnd() < 0.08;
      out.add(_Star(
        rnd(),
        rnd(),
        big ? 1.6 + rnd() * 0.8 : 0.4 + rnd() * 0.8,
        big ? 0.55 + rnd() * 0.35 : 0.15 + rnd() * 0.4,
        rnd() < 0.3,
        rnd(),
      ));
    }
    _cache[key] = out;
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Aurora wash — dark only, a slow vertical drift.
    if (isDark) {
      final drift = math.sin(t * math.pi * 2) * 8;
      final auroraRect = Rect.fromCenter(
        center: Offset(size.width / 2, -40 + drift),
        width: size.width * 1.4,
        height: 360,
      );
      final auroraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            auroraColor.withValues(alpha: 0.10),
            auroraColor.withValues(alpha: 0.0),
          ],
        ).createShader(auroraRect);
      canvas.drawOval(auroraRect, auroraPaint);
    }

    final paint = Paint();
    for (final star in _stars()) {
      var alpha = star.a * (isDark ? 1.0 : 0.35);
      if (star.twinkles) {
        // Smooth 0..1..0 pulse, phase-offset per star.
        final pulse =
            (math.sin((t + star.phase) * math.pi * 2) + 1) / 2; // 0..1
        final lo = alpha * 0.4;
        final hi = math.min(1.0, alpha * 1.6);
        alpha = lo + (hi - lo) * pulse;
      }
      paint.color = starColor.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) =>
      old.t != t || old.seed != seed || old.count != count;
}
