import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively_logo.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGold = Color(0xFFD4B16A);
const _kGoldLight = Color(0xFFE9D49A);
const _kGoldDark = Color(0xFF9F7637);
const _kGoldGradient = LinearGradient(
  colors: [_kGoldLight, _kGold, _kGoldDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _kBackground = Color(0xFF1A1F2E);
const _kTextSecondary = Color(0xFFB6BAC4);

/// Post-onboarding welcome screen — gold LIVELY logo, staggered welcome
/// copy that fades and slides in line by line, then a gold CTA at the
/// bottom that refreshes the user session and drops the user into /home.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _enteringCosmos = false;

  Future<void> _enterCosmos() async {
    if (_enteringCosmos) return;
    setState(() => _enteringCosmos = true);
    // Re-bootstrap so the backend's updated has_completed_onboarding flag
    // (set when the birth profile was saved) is reflected in our user
    // state. Without this refresh the router redirect would bounce the
    // user back to /onboarding when they try to enter /home.
    try {
      await ref.read(currentUserProvider.notifier).bootstrapSession();
    } catch (_) {
      // Even if the refresh fails, fall through — the next /home request
      // will hit the backend and either succeed or surface its own error.
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    final name = (user.name?.trim().isNotEmpty ?? false)
        ? user.name!.trim().split(' ').first
        : l10n.stargazer;

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const FadeSlideIn(
                duration: Duration(milliseconds: 800),
                offset: 16,
                child: Center(child: LivelyLogo(size: 140)),
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 700),
                duration: const Duration(milliseconds: 700),
                child: Text(
                  l10n.welcomeHello,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeSlideIn(
                delay: const Duration(milliseconds: 1100),
                duration: const Duration(milliseconds: 800),
                offset: 30,
                child: ShaderMask(
                  shaderCallback: (rect) => _kGoldGradient.createShader(rect),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              FadeSlideIn(
                delay: const Duration(milliseconds: 1900),
                duration: const Duration(milliseconds: 700),
                child: Text(
                  l10n.welcomeJourneyBegins,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 2400),
                duration: const Duration(milliseconds: 700),
                child: Text(
                  l10n.welcomeStarsAligned,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _kTextSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 3000),
                duration: const Duration(milliseconds: 700),
                child: SizedBox(
                  width: double.infinity,
                  child: _GoldCta(
                    label: _enteringCosmos
                        ? l10n.welcomeAligning
                        : l10n.welcomeEnter,
                    onPressed: _enteringCosmos ? null : () => _enterCosmos(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldCta extends StatelessWidget {
  const _GoldCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

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
            color: disabled ? _kGoldDark.withValues(alpha: 0.6) : _kGoldDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
