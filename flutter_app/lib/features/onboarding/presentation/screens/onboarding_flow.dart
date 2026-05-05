import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/birth_date_picker.dart';
import '../widgets/birth_time_picker.dart';
import '../widgets/birthplace_search.dart';
import '../widgets/chart_reveal.dart';

// Brand gold — matches the auth screen + LIVELY logo.
const _kGold = Color(0xFFD4B16A);
const _kGoldLight = Color(0xFFE9D49A);
const _kGoldDark = Color(0xFF9F7637);
const _kGoldGradient = LinearGradient(
  colors: [_kGoldLight, _kGold, _kGoldDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _kBackground = Color(0xFF1A1F2E);
const _kSurface = Color(0xFF1A1F2E);
const _kBorder = Color(0xFF2A2F3E);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFFB6BAC4);
const _kTextTertiary = Color(0xFF7E8290);

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
      backgroundColor: _kBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        if (state.currentStep > 0)
                          _BackButton(onTap: notifier.previousStep)
                        else
                          const SizedBox(width: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProgressIndicator(
                            current: state.currentStep,
                            total: OnboardingState.totalSteps,
                          ),
                        ),
                        const SizedBox(width: 52),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: _GoldPrimaryButton(
                      label: state.currentStep ==
                              OnboardingState.totalSteps - 1
                          ? 'Continue'
                          : 'Next',
                      loading: state.isLoading,
                      onPressed: state.canProceed && !state.isLoading
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
        if (state.chartReveal == null && mounted) {
          context.go('/welcome');
        }
      case 5:
        if (mounted) context.go('/welcome');
      default:
        notifier.nextStep();
    }
  }
}

// ============================================================================
// Shared chrome — back button, progress bar, primary CTA, step header.
// ============================================================================

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kSurface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _kTextPrimary,
            size: 20,
          ),
        ),
      ),
    );
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
        final filled = index <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: filled ? _kGoldGradient : null,
              color: filled ? null : _kBorder,
              borderRadius: BorderRadius.circular(3),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: _kGold.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _GoldPrimaryButton extends StatelessWidget {
  const _GoldPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: disabled ? _kGoldDark.withValues(alpha: 0.5) : _kGoldDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: _kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: _kTextSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Steps.
// ============================================================================

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
          const _StepHeader(
            title: 'When were you born?',
            subtitle:
                'Your birth date is the foundation of your cosmic profile.',
          ),
          const SizedBox(height: 28),
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
          const _StepHeader(
            title: 'What time were you born?',
            subtitle:
                'Your birth time determines your Rising sign and house placements.',
          ),
          const SizedBox(height: 28),
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
          const _StepHeader(
            title: 'Where were you born?',
            subtitle:
                'Your birthplace helps us calculate precise planetary positions.',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: BirthplaceSearch(
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
          const _StepHeader(
            title: "What's your name?",
            subtitle: "We'll use this to personalize your daily guidance.",
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: notifier.setName,
              cursorColor: _kGold,
              style: GoogleFonts.poppins(
                color: _kTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'First name',
                hintStyle: GoogleFonts.poppins(
                  color: _kTextTertiary,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
          const _StepHeader(
            title: 'What matters most to you?',
            subtitle: 'Select areas you want cosmic guidance on. (Optional)',
          ),
          const SizedBox(height: 28),
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
                          ? _kGold.withValues(alpha: 0.12)
                          : _kSurface.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _kGold : _kBorder,
                        width: isSelected ? 1.4 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _kGold.withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isSelected ? _kGold : _kTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? _kTextPrimary
                                  : _kTextSecondary,
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
