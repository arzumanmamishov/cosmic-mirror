import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme/colors.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  const LoadingShimmer.card({super.key})
      : width = double.infinity,
        height = 160,
        borderRadius = 16;

  const LoadingShimmer.circle({super.key, this.width = 48})
      : height = 48,
        borderRadius = 24;

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CosmicColors.surfaceLight,
      highlightColor: CosmicColors.surface.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: CosmicColors.surfaceLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingShimmer(height: 120, borderRadius: 16),
                const SizedBox(height: 12),
                LoadingShimmer(
                  width: MediaQuery.sizeOf(context).width * 0.6,
                ),
                const SizedBox(height: 8),
                const LoadingShimmer(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
