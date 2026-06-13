import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A single shimmering placeholder block. Theme-aware: it reads
/// [AppPalette] so the placeholder + sweep colors are light in light
/// mode and dark in dark mode (previously it used dark-only constants
/// and rendered near-black on the light theme).
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
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // base = the resting placeholder block; highlight = the sweep.
    final base = isDark ? p.surfaceElevated : p.bgDeep;
    final highlight = isDark
        ? Color.lerp(p.surfaceElevated, p.textPrimary, 0.08)!
        : p.surface;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A small stack of skeleton placeholder cards shown while a screen
/// loads.
///
/// Built as a **shrink-wrapping, non-scrolling** ListView so it's safe
/// in every context:
///  - inside another scrollable → shrinkWrap means it sizes to its
///    content instead of demanding unbounded height (no "Vertical
///    viewport was given unbounded height" crash);
///  - as a full-screen loader where the content is taller than the
///    viewport → the ListView simply clips, so no RenderFlex overflow.
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding.add(const EdgeInsets.symmetric(vertical: 20)),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
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
    );
  }
}
