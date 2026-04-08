import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';

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
    Widget card;

    if (glassmorphism) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: CosmicColors.glassBackground,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: CosmicColors.glassBorder),
            ),
            child: child,
          ),
        ),
      );
    } else if (showGradientBorder) {
      card = Container(
        decoration: BoxDecoration(
          gradient: CosmicColors.primaryGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: CosmicColors.surface,
            borderRadius: BorderRadius.circular(borderRadius - 1.5),
          ),
          child: child,
        ),
      );
    } else {
      card = Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient ?? CosmicColors.cardGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: CosmicColors.glassBorder),
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
