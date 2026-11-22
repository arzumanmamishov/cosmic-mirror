import 'dart:ui';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

class CosmicCard extends StatelessWidget {
  const CosmicCard({
    required this.child,
    super.key,
    this.gradient,
    this.showGradientBorder = false,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.borderRadius = 16,
    this.glassmorphism = false,
  });

  final Widget child;
  final Gradient? gradient;
  final bool showGradientBorder;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool glassmorphism;

  @override
  Widget build(BuildContext context) {
    // Palette-driven so the card reads in both themes (the old
    // CosmicColors constants were dark-only).
    final p = context.palette;
    Widget card;

    if (glassmorphism) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: p.surfaceGlass,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: p.glassBorder),
            ),
            child: child,
          ),
        ),
      );
    } else if (showGradientBorder) {
      card = Container(
        decoration: BoxDecoration(
          gradient: p.primaryGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(borderRadius - 1.5),
          ),
          child: child,
        ),
      );
    } else {
      card = Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient ?? p.cardGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: p.glassBorder),
        ),
        child: child,
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
