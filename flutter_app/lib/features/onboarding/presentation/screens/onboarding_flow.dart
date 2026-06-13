import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birth_date_picker.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birth_time_picker.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birthplace_search.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/chart_reveal.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_chip.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_field.dart';
import 'package:cosmic_mirror/shared/widgets/lively/step_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Lively onboarding flow — a cosmic backdrop with a shared shell
/// (back chip · step rail · counter · hero heading · gold CTA) wrapping
/// the six birth-data steps.
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
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<OnboardingState>(onboardingProvider, (prev, next) {
      if (prev?.currentStep != next.currentStep) {
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final isLast = state.currentStep == OnboardingState.totalSteps - 1;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LivelyBackdrop(
        seed: 5 + state.currentStep,
        intensity: 0.65,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                // ── header: back · progress · counter ──────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      _BackChip(
                        enabled: state.currentStep > 0,
                        onTap: notifier.previousStep,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: StepProgress(
                          step: state.currentStep,
                          total: OnboardingState.totalSteps,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '${state.currentStep + 1} / ${OnboardingState.totalSteps}',
                        style: LivelyType.mono(p.textMuted, size: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── step body ──────────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _Step(
                        title: l10n.onboardingBirthDateTitle,
                        subtitle: l10n.onboardingBirthDateSubtitle,
                        child: BirthDatePicker(
                          selectedDate: state.birthDate,
                          onDateChanged: notifier.setBirthDate,
                        ),
                      ),
                      _Step(
                        title: l10n.onboardingBirthTimeTitle,
                        subtitle: l10n.onboardingBirthTimeSubtitle,
                        child: BirthTimePicker(
                          selectedTime: state.birthTime,
                          birthTimeKnown: state.birthTimeKnown,
                          onTimeChanged: notifier.setBirthTime,
                          onKnownChanged: (known) =>
                              notifier.setBirthTimeKnown(known: known),
                        ),
                      ),
                      _Step(
                        title: l10n.onboardingBirthPlaceTitle,
                        subtitle: l10n.onboardingBirthPlaceSubtitle,
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
                      _NameStep(notifier: notifier),
                      _FocusAreasStep(notifier: notifier, state: state),
                      _Step(
                        title: null,
                        subtitle: null,
                        child: ChartRevealWidget(state: state),
                      ),
                    ],
                  ),
                ),

                // ── CTA ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: GoldButton(
                    label: isLast
                        ? l10n.onboardingContinue
                        : l10n.onboardingNext,
                    loading: state.isLoading,
                    trailingArrow: !state.isLoading,
                    onPressed: state.canProceed && !state.isLoading
                        ? () => _handleNext(state, notifier)
                        : null,
                  ),
                ),
              ],
            ),
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
        // Use the returned success flag, not state.chartReveal — `state`
        // is the snapshot captured before the await, so it never reflects
        // the chart we just loaded. Reading it here always looked "null"
        // and bounced the user past the reveal step to /welcome.
        final loaded = await notifier.loadChartReveal();
        if (!mounted) return;
        if (loaded) {
          notifier.nextStep();
        } else {
          context.go('/welcome');
        }
      case 5:
        if (mounted) context.go('/welcome');
      default:
        notifier.nextStep();
    }
  }
}

// ───────────────────────────────────────────────────────────────
// Shared chrome
// ───────────────────────────────────────────────────────────────

/// 32×32 round back chip with a hairline border.
class _BackChip extends StatelessWidget {
  const _BackChip({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: enabled ? 1 : 0,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? p.surfaceGlass : p.surface,
            shape: BoxShape.circle,
            border: Border.all(color: p.line),
          ),
          child: Icon(Icons.chevron_left_rounded, color: p.textPrimary, size: 20),
        ),
      ),
    );
  }
}

/// One onboarding step: an optional hero heading (title + subtitle) above
/// a body that fills the remaining height.
class _Step extends StatelessWidget {
  const _Step({required this.title, required this.subtitle, required this.child});

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            const SizedBox(height: 36),
            Text(title!, style: LivelyType.d3(p.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: LivelyType.body(p.textMuted),
              ),
            ],
            const SizedBox(height: 24),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Step 4 · Name
// ───────────────────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  const _NameStep({required this.notifier});
  final OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return _Step(
      title: l10n.onboardingNameTitle,
      subtitle: l10n.onboardingNameSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LivelyField(
            hint: l10n.onboardingNameHint,
            large: true,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: notifier.setName,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              l10n.onboardingNameReassure,
              style: LivelyType.small(p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Step 5 · Focus areas
// ───────────────────────────────────────────────────────────────

class _FocusAreasStep extends StatelessWidget {
  const _FocusAreasStep({required this.notifier, required this.state});

  final OnboardingNotifier notifier;
  final OnboardingState state;

  // Stable English keys — stored on the profile + shipped to the backend.
  static const _areaKeys = [
    'Love & Relationships',
    'Career & Purpose',
    'Personal Growth',
    'Health & Wellness',
    'Creativity',
    'Spirituality',
  ];
  static const _areaIcons = [
    Icons.favorite_outline_rounded,
    Icons.work_outline_rounded,
    Icons.psychology_outlined,
    Icons.spa_outlined,
    Icons.palette_outlined,
    Icons.auto_awesome_outlined,
  ];

  String _label(int i, AppLocalizations l10n) {
    switch (i) {
      case 0:
        return l10n.focusLove;
      case 1:
        return l10n.focusCareer;
      case 2:
        return l10n.focusGrowth;
      case 3:
        return l10n.focusHealth;
      case 4:
        return l10n.focusCreativity;
      default:
        return l10n.focusSpirituality;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return _Step(
      title: l10n.onboardingFocusTitle,
      subtitle: l10n.onboardingFocusSubtitle,
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
            ),
            itemCount: _areaKeys.length,
            itemBuilder: (context, i) {
              final key = _areaKeys[i];
              return LivelyChip(
                label: _label(i, l10n),
                icon: _areaIcons[i],
                selected: state.focusAreas.contains(key),
                onTap: () => notifier.toggleFocusArea(key),
              );
            },
          ),
          const Spacer(),
          Text(
            l10n.onboardingFocusCount(state.focusAreas.length),
            style: LivelyType.small(p.textMuted),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
