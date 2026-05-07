import 'package:flutter/material.dart';

/// Background placeholder. Originally rendered an animated starfield;
/// kept as a no-op widget so the dozens of existing call sites still
/// compile while every screen now falls through to the solid
/// AppPalette.background (matching the onboarding flow).
///
/// The constructor signature is intentionally preserved — older code
/// still passes `starCount`, `color`, `seed`, `intensity`. None of
/// those are read anymore.
class CosmicStarfield extends StatelessWidget {
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
  final double intensity;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
