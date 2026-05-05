import 'dart:math';

import 'package:flutter/material.dart';

/// KenBurnsImage — wraps a background image with a slow pan + zoom so the
/// scene never sits perfectly still. Motion is driven by a single
/// AnimationController set to repeat with reverse, so the image gently
/// drifts back and forth between two endpoints over the configured period.
///
/// Defaults are tuned to feel alive without ever being noticed: ~5%
/// max zoom and ~3% pan in each direction over 40 seconds round-trip.
/// Pair with `BoxFit.cover` so the over-scan never reveals the page
/// background underneath.
class KenBurnsImage extends StatefulWidget {
  const KenBurnsImage({
    required this.image,
    super.key,
    this.duration = const Duration(seconds: 40),
    this.maxZoom = 1.05,
    this.panAmount = 0.03,
    this.fit = BoxFit.cover,
  });

  final ImageProvider image;
  final Duration duration;

  /// Peak scale at the far end of the cycle. Values just above 1.0 work
  /// best; anything beyond ~1.10 starts feeling like a zoom effect.
  final double maxZoom;

  /// How far the image drifts as a fraction of its size, in each axis.
  final double panAmount;

  final BoxFit fit;

  @override
  State<KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          // Eased value 0..1, so motion accelerates and decelerates
          // naturally rather than ticking linearly.
          final t = Curves.easeInOutSine.transform(_ctrl.value);

          // Two motions are 90° out of phase so the pan direction shifts
          // through the cycle (drifting up-left, then down-right, etc.)
          // instead of moving along a single straight line.
          final phase = t * pi;
          final dx = sin(phase) * widget.panAmount;
          final dy = cos(phase) * widget.panAmount;
          final scale = 1 + (widget.maxZoom - 1) * t;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Transform.translate(
                offset: Offset(
                  dx * constraints.maxWidth,
                  dy * constraints.maxHeight,
                ),
                child: Transform.scale(
                  scale: scale,
                  child: Image(
                    image: widget.image,
                    fit: widget.fit,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
