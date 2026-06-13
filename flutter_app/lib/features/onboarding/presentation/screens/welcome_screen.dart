import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/lively/mini_wheel.dart';
import 'package:cosmic_mirror/shared/widgets/lively_logo.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Post-onboarding payoff — the chart reveal. The whole screen builds
/// itself in front of the user: kicker, title, the spinning-up mini
/// wheel, then the three luminary cards, an opening line, and the CTA,
/// each fading up on a staggered delay.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _entering = false;

  Future<void> _enter() async {
    if (_entering) return;
    setState(() => _entering = true);
    // Re-bootstrap so the backend's updated has_completed_onboarding flag
    // is reflected — otherwise the router bounces the user to /onboarding.
    try {
      await ref.read(currentUserProvider.notifier).bootstrapSession();
    } catch (_) {/* fall through — /home will surface its own error */}
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final onb = ref.watch(onboardingProvider);

    final name = (user.name?.trim().isNotEmpty ?? false)
        ? user.name!.trim().split(' ').first
        : l10n.stargazer;

    final sun = user.sunSign;
    final moon = user.moonSign;
    final rising = user.risingSign;

    final dateLine = _dateLine(onb);

    return Scaffold(
      body: LivelyBackdrop(
        seed: 42,
        intensity: 1.4,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 4),

                // logo + kicker + date
                FadeSlideIn(
                  duration: const Duration(milliseconds: 700),
                  child: Column(
                    children: [
                      const LivelyLogo(size: 64),
                      const SizedBox(height: 14),
                      Text(
                        '✨  ${l10n.welcomeKicker(name)}'.toUpperCase(),
                        style: LivelyType.kicker(p.primary)
                            .copyWith(letterSpacing: 2.4),
                      ),
                      if (dateLine != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          dateLine,
                          style: LivelyType.mono(p.textMuted, size: 11),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // title
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  duration: const Duration(milliseconds: 700),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l10n.welcomeChartReady}\n'),
                        TextSpan(
                          text: l10n.welcomeChartReady2,
                          style: LivelyType.d2(p.primary),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: LivelyType.d2(p.textPrimary),
                  ),
                ),

                const SizedBox(height: 26),

                // wheel — scales in
                FadeSlideIn(
                  delay: const Duration(milliseconds: 350),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: MiniWheel(
                      sun: sun ?? 'leo',
                      moon: moon ?? 'pisces',
                      rising: rising ?? 'scorpio',
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // luminary cards
                Row(
                  children: [
                    Expanded(
                      child: _LuminaryCard(
                        kind: l10n.welcomeSun,
                        sign: sun,
                        delayMs: 900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LuminaryCard(
                        kind: l10n.welcomeMoon,
                        sign: moon,
                        delayMs: 1050,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LuminaryCard(
                        kind: l10n.welcomeRising,
                        sign: rising,
                        delayMs: 1200,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // opening line
                FadeSlideIn(
                  delay: const Duration(milliseconds: 1400),
                  duration: const Duration(milliseconds: 700),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.welcomeStarsAligned,
                      textAlign: TextAlign.center,
                      style: LivelyType.d3(p.textMuted).copyWith(fontSize: 17),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CTA
                FadeSlideIn(
                  delay: const Duration(milliseconds: 1600),
                  duration: const Duration(milliseconds: 700),
                  child: GoldButton(
                    label: _entering ? l10n.welcomeAligning : l10n.welcomeEnter,
                    loading: _entering,
                    trailingArrow: !_entering,
                    onPressed: _entering ? null : _enter,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "JULY 28, 1996 · 10:31 AM · ISTANBUL" — pieces are omitted when the
  /// onboarding state doesn't have them.
  String? _dateLine(OnboardingState onb) {
    final parts = <String>[];
    final d = onb.birthDate;
    if (d != null) {
      const months = [
        'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
        'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
      ];
      parts.add('${months[d.month - 1]} ${d.day}, ${d.year}');
    }
    final t = onb.birthTime;
    if (t != null && onb.birthTimeKnown) {
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      final ap = t.hour < 12 ? 'AM' : 'PM';
      parts.add('$h:$m $ap');
    }
    final place = onb.birthPlace;
    if (place != null && place.trim().isNotEmpty) {
      parts.add(place.split(',').first.trim().toUpperCase());
    }
    return parts.isEmpty ? null : parts.join('  ·  ');
  }
}

class _LuminaryCard extends StatelessWidget {
  const _LuminaryCard({
    required this.kind,
    required this.sign,
    required this.delayMs,
  });

  final String kind;
  final String? sign;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signLabel = (sign != null && sign!.trim().isNotEmpty)
        ? '${sign![0].toUpperCase()}${sign!.substring(1).toLowerCase()}'
        : '—';
    return FadeSlideIn(
      delay: Duration(milliseconds: delayMs),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? p.surfaceGlass : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.glassBorder),
        ),
        child: Column(
          children: [
            Text(
              kind.toUpperCase(),
              style: LivelyType.caption(p.textMuted)
                  .copyWith(fontSize: 9, letterSpacing: 1.3),
            ),
            const SizedBox(height: 6),
            Text(
              glyphForSign(sign),
              style: TextStyle(fontSize: 24, color: p.primary, height: 1),
            ),
            const SizedBox(height: 4),
            Text(
              signLabel,
              style: LivelyType.d3(p.textPrimary).copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
