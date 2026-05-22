import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/shared/widgets/lively/mini_wheel.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/loading_shimmer.dart';
import '../providers/onboarding_provider.dart';

/// The in-onboarding "Big Three" reveal — Sun / Moon / Rising cards that
/// fade-and-rise in sequence, styled with the Lively design system.
class ChartRevealWidget extends StatefulWidget {
  const ChartRevealWidget({required this.state, super.key});

  final OnboardingState state;

  @override
  State<ChartRevealWidget> createState() => _ChartRevealWidgetState();
}

class _ChartRevealWidgetState extends State<ChartRevealWidget>
    with TickerProviderStateMixin {
  late final AnimationController _sunController;
  late final AnimationController _moonController;
  late final AnimationController _risingController;

  @override
  void initState() {
    super.initState();
    _sunController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _moonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _risingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) _sunController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) _moonController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) _risingController.forward();
  }

  @override
  void dispose() {
    _sunController.dispose();
    _moonController.dispose();
    _risingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chart = widget.state.chartReveal;

    if (widget.state.isLoading || chart == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingShimmer(height: 84, borderRadius: 16),
            SizedBox(height: 16),
            LoadingShimmer(height: 84, borderRadius: 16),
            SizedBox(height: 16),
            LoadingShimmer(height: 84, borderRadius: 16),
          ],
        ),
      );
    }

    final sunSign = chart['sun_sign'] as String? ?? 'Unknown';
    final moonSign = chart['moon_sign'] as String? ?? 'Unknown';
    final risingSign = chart['rising_sign'] as String? ?? 'Unknown';
    final sunDesc = chart['sun_description'] as String? ?? '';
    final moonDesc = chart['moon_description'] as String? ?? '';
    final risingDesc = chart['rising_description'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Your cosmic blueprint',
            style: LivelyType.d3(p.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Here are your Big Three.',
            style: LivelyType.body(p.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _RevealCard(
            controller: _sunController,
            icon: Icons.wb_sunny_rounded,
            label: 'Sun Sign',
            sign: sunSign,
            description: sunDesc,
          ),
          const SizedBox(height: 12),
          _RevealCard(
            controller: _moonController,
            icon: Icons.nightlight_round,
            label: 'Moon Sign',
            sign: moonSign,
            description: moonDesc,
          ),
          const SizedBox(height: 12),
          _RevealCard(
            controller: _risingController,
            icon: Icons.arrow_upward_rounded,
            label: 'Rising Sign',
            sign: risingSign,
            description: risingDesc,
          ),
        ],
      ),
    );
  }
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({
    required this.controller,
    required this.icon,
    required this.label,
    required this.sign,
    required this.description,
  });

  final AnimationController controller;
  final IconData icon;
  final String label;
  final String sign;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? p.surfaceGlass : p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.glassBorder),
          ),
          child: Row(
            children: [
              // glyph medallion
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: p.glassBorder),
                ),
                child: Text(
                  glyphForSign(sign),
                  style: TextStyle(fontSize: 22, color: p.primary, height: 1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: p.primary, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          label.toUpperCase(),
                          style: LivelyType.caption(p.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(sign, style: LivelyType.d3(p.textPrimary).copyWith(fontSize: 22)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: LivelyType.small(p.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
