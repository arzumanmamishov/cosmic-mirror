import 'package:flutter/material.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../providers/onboarding_provider.dart';

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
    final chart = widget.state.chartReveal;

    if (widget.state.isLoading || chart == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingShimmer(height: 80, borderRadius: 16),
            SizedBox(height: 16),
            LoadingShimmer(height: 80, borderRadius: 16),
            SizedBox(height: 16),
            LoadingShimmer(height: 80, borderRadius: 16),
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
          Text('Your Cosmic Blueprint', style: CosmicTypography.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Here are your Big Three',
            style: CosmicTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          _RevealCard(
            controller: _sunController,
            icon: Icons.wb_sunny,
            iconColor: CosmicColors.gold,
            label: 'Sun Sign',
            sign: sunSign,
            description: sunDesc,
          ),
          const SizedBox(height: 16),
          _RevealCard(
            controller: _moonController,
            icon: Icons.nightlight_round,
            iconColor: CosmicColors.primaryLight,
            label: 'Moon Sign',
            sign: moonSign,
            description: moonDesc,
          ),
          const SizedBox(height: 16),
          _RevealCard(
            controller: _risingController,
            icon: Icons.arrow_upward_rounded,
            iconColor: CosmicColors.accent,
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
    required this.iconColor,
    required this.label,
    required this.sign,
    required this.description,
  });

  final AnimationController controller;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sign;
  final String description;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withOpacity(0.1),
                CosmicColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: CosmicTypography.caption.copyWith(
                        color: iconColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(sign, style: CosmicTypography.headlineMedium),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: CosmicTypography.bodySmall,
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
