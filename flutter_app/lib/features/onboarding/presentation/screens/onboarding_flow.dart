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
    // Start on the provider's current step: the notifier outlives this
    // widget, so a remount (e.g. bounced back here from /welcome) must not
    // show page 0 while the header/CTA act on a later step.
    _pageController = PageController(
      initialPage: ref.read(onboardingProvider).currentStep,
    );
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
        // Dismiss any lingering keyboard from a previous text-input step
        // — otherwise steps that don't need input (focus areas, chart
        // reveal) end up with the keyboard still overlaying their layout
        // and their Column overflows.
        FocusManager.instance.primaryFocus?.unfocus();
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final isLast = state.currentStep == OnboardingState.totalSteps - 1;

    // Android back / iOS edge-swipe steps back through the flow instead of
    // leaving the onboarding route (which would exit the app).
    return PopScope(
      canPop: state.currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !state.isLoading) notifier.previousStep();
      },
      child: Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(18, 6, 24, 0),
                  child: Row(
                    children: [
                      _BackChip(
                        enabled: state.currentStep > 0 && !state.isLoading,
                        onTap: notifier.previousStep,
                      ),
                      const SizedBox(width: 8),
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
                          onPlaceCleared: notifier.clearBirthPlace,
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
                      _NameStep(notifier: notifier, initialName: state.name),
                      _FocusAreasStep(notifier: notifier, state: state),
                      _Step(
                        title: null,
                        subtitle: null,
                        child: ChartRevealWidget(state: state),
                      ),
                    ],
                  ),
                ),

                // ── save error ──────────────────────────────────────
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      l10n.oaphOnboardingSaveError,
                      textAlign: TextAlign.center,
                      style: LivelyType.small(p.error),
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
        // Persist the chosen focus areas (optional step — a failure here
        // shouldn't block the reveal, so the result is ignored).
        if (state.focusAreas.isNotEmpty) {
          await notifier.submitFocusAreas();
          if (!mounted) return;
        }
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
      child: Semantics(
        button: true,
        enabled: enabled,
        label: MaterialLocalizations.of(context).backButtonTooltip,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          // 44×44 hit area around the 32px visual chip.
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? p.surfaceGlass : p.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.line),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: p.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
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

class _NameStep extends StatefulWidget {
  const _NameStep({required this.notifier, required this.initialName});
  final OnboardingNotifier notifier;
  final String initialName;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  // Seeded from the provider: PageView disposes off-screen pages, so
  // without this, coming back to this step showed an empty field while
  // the notifier still held (and would submit) the earlier name.
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return _Step(
      title: l10n.onboardingNameTitle,
      subtitle: l10n.onboardingNameSubtitle,
      // Scrollable so the field + note stay reachable above the keyboard
      // on short screens / large text.
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LivelyField(
            controller: _controller,
            hint: l10n.onboardingNameHint,
            large: true,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            onChanged: widget.notifier.setName,
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
      // The child of _Step gets an Expanded box, so wrapping in a
      // SingleChildScrollView here keeps the whole grid+counter block
      // reachable when a residual soft-keyboard or a shorter screen
      // eats vertical space — otherwise the last row of chips renders
      // into a bottom-overflow debug banner.
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Fixed row height sized for a two-line, text-scaled chip
              // label — an aspect ratio squeezed the chips on narrow
              // phones and clipped wrapped labels ("Love & Relationships").
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent:
                    30 + 2 * MediaQuery.textScalerOf(context).scale(14) * 22 / 15,
              ),
              itemCount: _areaKeys.length,
              itemBuilder: (context, i) {
                final key = _areaKeys[i];
                final selected = state.focusAreas.contains(key);
                final full = state.focusAreas.length >=
                    OnboardingNotifier.maxFocusAreas;
                return Opacity(
                  // Dim the unselected chips once the limit is reached.
                  opacity: !selected && full ? 0.5 : 1,
                  child: LivelyChip(
                    label: _label(i, l10n),
                    icon: _areaIcons[i],
                    selected: selected,
                    onTap: () => notifier.toggleFocusArea(key),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingFocusCount(state.focusAreas.length),
              style: LivelyType.small(p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
