import 'package:flutter/material.dart';

/// CosmicPulse softly scales and fades the surrounding glow of its child to
/// suggest a cosmic, breathing-light effect. Used behind heroes, the central
/// nav button, or premium CTAs.
class CosmicPulse extends StatefulWidget {
  const CosmicPulse({
    required this.child,
    super.key,
    this.color,
    this.maxRadius = 60,
    this.duration = const Duration(seconds: 3),
  });

  final Widget child;

  /// If null, falls back to Theme primary.
  final Color? color;
  final double maxRadius;
  final Duration duration;

  @override
  State<CosmicPulse> createState() => _CosmicPulseState();
}

class _CosmicPulseState extends State<CosmicPulse>
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
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Eased breathing curve: 0.7 .. 1.0 .. 0.7
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Container(
                width: widget.maxRadius * 2,
                height: widget.maxRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.18 + t * 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
