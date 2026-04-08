import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/cosmic_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/birth_date_picker.dart';
import '../widgets/birth_time_picker.dart';
import '../widgets/birthplace_search.dart';
import '../widgets/chart_reveal.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    ref.listen<OnboardingState>(onboardingProvider, (prev, next) {
      if (prev?.currentStep != next.currentStep) {
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E27), Color(0xFF1A1040), Color(0xFF0A0E27)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    if (state.currentStep > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: notifier.previousStep,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: _ProgressIndicator(
                        current: state.currentStep,
                        total: OnboardingState.totalSteps,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _BirthDateStep(notifier: notifier, state: state),
                    _BirthTimeStep(notifier: notifier, state: state),
                    _BirthPlaceStep(notifier: notifier, state: state),
                    _NameStep(notifier: notifier, state: state),
                    _FocusAreasStep(notifier: notifier, state: state),
                    ChartRevealWidget(state: state),
                  ],
                ),
              ),

              // Next button
              Padding(
                padding: const EdgeInsets.all(24),
                child: CosmicButton(
                  label: state.currentStep == OnboardingState.totalSteps - 1
                      ? 'Continue'
                      : 'Next',
                  isLoading: state.isLoading,
                  onPressed: state.canProceed
                      ? () => _handleNext(state, notifier)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNext(
    OnboardingState state,
    OnboardingNotifier notifier,
  ) async {
    switch (state.currentStep) {
      case 2:
        final success = await notifier.submitBirthProfile();
        if (success) notifier.nextStep();
      case 3:
        final success = await notifier.submitName();
        if (success) notifier.nextStep();
      case 4:
        await notifier.loadChartReveal();
        notifier.nextStep();
      case 5:
        if (mounted) context.go('/paywall');
      default:
        notifier.nextStep();
    }
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index <= current
                  ? CosmicColors.primary
                  : CosmicColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _BirthDateStep extends StatelessWidget {
  const _BirthDateStep({required this.notifier, required this.state});

  final OnboardingNotifier notifier;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("When were you born?", style: CosmicTypography.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Your birth date is the foundation of your cosmic profile.',
            style: CosmicTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BirthDatePicker(
              selectedDate: state.birthDate,
              onDateChanged: notifier.setBirthDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthTimeStep extends StatelessWidget {
  const _BirthTimeStep({required this.notifier, required this.state});

  final OnboardingNotifier notifier;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What time were you born?', style: CosmicTypography.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Your birth time determines your Rising sign and house placements.',
            style: CosmicTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BirthTimePicker(
              selectedTime: state.birthTime,
              birthTimeKnown: state.birthTimeKnown,
              onTimeChanged: notifier.setBirthTime,
              onKnownChanged: (known) =>
                  notifier.setBirthTimeKnown(known: known),
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthPlaceStep extends StatelessWidget {
  const _BirthPlaceStep({required this.notifier, required this.state});

  final OnboardingNotifier notifier;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where were you born?', style: CosmicTypography.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Your birthplace helps us calculate precise planetary positions.',
            style: CosmicTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          BirthplaceSearch(
            selectedPlace: state.birthPlace,
            onPlaceSelected: (place, lat, lng, tz) {
              notifier.setBirthPlace(
                place: place,
                lat: lat,
                lng: lng,
                tz: tz,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.notifier, required this.state});

  final OnboardingNotifier notifier;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your name?", style: CosmicTypography.displaySmall),
          const SizedBox(height: 8),
          Text(
            "We'll use this to personalize your daily guidance.",
            style: CosmicTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: notifier.setName,
            style: CosmicTypography.headlineLarge,
            decoration: const InputDecoration(
              hintText: 'First name',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusAreasStep extends StatelessWidget {
  const _FocusAreasStep({required this.notifier, required this.state});

  final OnboardingNotifier notifier;
  final OnboardingState state;

  static const _areas = [
    ('Love & Relationships', Icons.favorite_outline),
    ('Career & Purpose', Icons.work_outline),
    ('Personal Growth', Icons.psychology_outlined),
    ('Health & Wellness', Icons.spa_outlined),
    ('Creativity', Icons.palette_outlined),
    ('Spirituality', Icons.self_improvement),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What matters most to you?',
              style: CosmicTypography.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Select areas you want cosmic guidance on. (Optional)',
            style: CosmicTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _areas.length,
              itemBuilder: (context, index) {
                final (label, icon) = _areas[index];
                final isSelected = state.focusAreas.contains(label);
                return GestureDetector(
                  onTap: () => notifier.toggleFocusArea(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CosmicColors.primary.withOpacity(0.2)
                          : CosmicColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? CosmicColors.primary
                            : CosmicColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 20,
                            color: isSelected
                                ? CosmicColors.primary
                                : CosmicColors.textSecondary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            style: CosmicTypography.bodySmall.copyWith(
                              color: isSelected
                                  ? CosmicColors.textPrimary
                                  : CosmicColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
