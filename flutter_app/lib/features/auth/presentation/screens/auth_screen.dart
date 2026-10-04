// Sign-in screen for the SMTP-OTP flow. Two panes on one screen (login /
// register) swap via a small segmented toggle so a returning user doesn't
// have to dig for the register link.

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/features/auth/presentation/screens/otp_screen.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_field.dart';
import 'package:cosmic_mirror/shared/widgets/lively_logo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _Mode { login, register }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _Mode _mode = _Mode.login;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = l.authInvalidEmail);
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = l.authPasswordTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_mode == _Mode.login) {
        await ref
            .read(authControllerProvider.notifier)
            .login(email: email, password: _password.text);
        await ref.read(currentUserProvider.notifier).bootstrapSession();
        if (mounted) context.go('/');
      } else {
        // Register: kick off OTP + push to /otp with the pending name +
        // password so the OTP verify creates the account.
        await ref
            .read(authControllerProvider.notifier)
            .requestOtp(email, OtpPurpose.register);
        if (!mounted) return;
        await context.push<void>(
          '/otp',
          extra: OtpRouteArgs(
            email: email,
            purpose: OtpPurpose.register,
            pending: PendingRegistration(
              name: '',
              password: _password.text,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = _prettyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithCode() => _requestCodeAndRoute(OtpPurpose.login);

  /// "Send me a code instead of a password" path. Only pushes to /otp when
  /// the backend confirms the address is registered — otherwise surfaces
  /// "no account" inline so the user can switch to Create account instead
  /// of chasing a code that will never arrive.
  Future<void> _requestCodeAndRoute(OtpPurpose purpose) async {
    final email = _email.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(
        () => _error = AppLocalizations.of(context).authResetPasswordEmailEmpty,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestOtp(email, purpose);
      if (!mounted) return;
      await context.push<void>(
        '/otp',
        extra: OtpRouteArgs(email: email, purpose: purpose),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _prettyOtpRequestError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _prettyOtpRequestError(Object e) {
    final l = AppLocalizations.of(context);
    final s = e.toString();
    if (s.contains('user_not_found') ||
        s.contains('No account with that email')) {
      return l.authNoAccountTapCreate;
    }
    if (e is RateLimitException || s.contains('rate_limit')) {
      return l.authTooManyCodeRequests;
    }
    return l.commonSomethingWentWrong;
  }

  bool _looksLikeEmail(String s) {
    final at = s.indexOf('@');
    return s.length >= 5 && at > 0 && s.substring(at + 1).contains('.');
  }

  String _prettyError(Object e) {
    final l = AppLocalizations.of(context);
    final s = e.toString();
    if (s.contains('invalid_credentials')) {
      return l.authErrorInvalidCredential;
    }
    // 429 — per-IP rate limit or the per-account login lockout.
    if (e is RateLimitException || s.contains('rate_limit')) {
      return l.authTooManyAttemptsShort;
    }
    return l.commonSomethingWentWrong;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final isLogin = _mode == _Mode.login;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: p.background,
      resizeToAvoidBottomInset: false,
      body: LivelyBackdrop(
        seed: 11,
        // Shrink only the scroll viewport by the keyboard height (the
        // backdrop stays full-size) so focused fields auto-scroll above it.
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            bottom: bottomInset == 0,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: LivelyLogo(size: 108)),
                  const SizedBox(height: 26),

                  // hero
                  Text(
                    isLogin
                        ? l.authKickerWelcomeBack
                        : l.authKickerCreateAccount,
                    style: LivelyType.kicker(p.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLogin ? l.authSignIn : l.authBeginJourney,
                    style: LivelyType.d2(p.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 290,
                    child: Text(
                      isLogin ? l.authSignInSubtitle : l.authRegisterSubtitle,
                      style: LivelyType.body(p.textMuted),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _ModeToggle(
                    mode: _mode,
                    onChanged: (m) => setState(() {
                      _mode = m;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Register no longer collects a name — the user picks a
                  // display name later during onboarding.
                  LivelyField(
                    controller: _email,
                    label: l.authEmail,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  LivelyField(
                    controller: _password,
                    label: l.authPassword,
                    hint: '••••••••',
                    obscure: true,
                    autofillHints: const [AutofillHints.password],
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: LivelyType.small(p.error)),
                  ],
                  const SizedBox(height: 22),

                  GoldButton(
                    label: isLogin ? l.authSignIn : l.authCreateAccount,
                    loading: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: 12),
                  GoldButton(
                    label: l.authSignInWithCode,
                    ghost: true,
                    onPressed: _busy ? null : _signInWithCode,
                  ),
                  if (isLogin) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => context.push('/forgot-password'),
                        child: Text(
                          l.authForgotYourPassword,
                          style: LivelyType.small(p.primary),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const _TermsNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "By continuing you agree to our Terms and Privacy Policy" with tappable
/// links to the public legal pages.
class _TermsNotice extends StatefulWidget {
  const _TermsNotice();

  @override
  State<_TermsNotice> createState() => _TermsNoticeState();
}

class _TermsNoticeState extends State<_TermsNotice> {
  static final _termsUrl = Uri.parse('https://livelyapp.co/terms');
  static final _privacyUrl = Uri.parse('https://livelyapp.co/privacy');

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => launchUrl(_termsUrl);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => launchUrl(_privacyUrl);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final link = LivelyType.small(p.primary).copyWith(
      decoration: TextDecoration.underline,
      decorationColor: p.primary,
    );
    return Text.rich(
      TextSpan(
        style: LivelyType.small(p.textMuted),
        children: [
          TextSpan(text: l.authTermsPrefix),
          TextSpan(text: l.authTerms, style: link, recognizer: _termsTap),
          TextSpan(text: l.authAnd),
          TextSpan(text: l.authPrivacy, style: link, recognizer: _privacyTap),
          TextSpan(text: l.authTermsSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Payload passed to /otp via GoRouter's `extra`. Public so the router
/// can unwrap it in one place.
class OtpRouteArgs {
  const OtpRouteArgs({
    required this.email,
    required this.purpose,
    this.pending,
  });
  final String email;
  final OtpPurpose purpose;
  final PendingRegistration? pending;
}

/// Segmented pill for login / register — mirrors the density toggle from
/// the Matrix screen so the app feels consistent.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    Widget seg(String label, {required _Mode target}) {
      final active = mode == target;
      return Expanded(
        child: GestureDetector(
          onTap: active ? null : () => onChanged(target),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color:
                  active ? p.gold.withValues(alpha: 0.85) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? p.background : p.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.textTertiary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          seg(l.authSignIn, target: _Mode.login),
          seg(l.authCreateAccount, target: _Mode.register),
        ],
      ),
    );
  }
}
