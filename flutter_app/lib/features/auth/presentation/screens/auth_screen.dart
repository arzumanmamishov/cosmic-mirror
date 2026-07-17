// Sign-in screen for the SMTP-OTP flow. Two panes on one screen (login /
// register) swap via a small segmented toggle so a returning user doesn't
// have to dig for the register link.

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/features/auth/presentation/screens/otp_screen.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_field.dart';
import 'package:cosmic_mirror/shared/widgets/lively_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final email = _email.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
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
      setState(() => _error = 'Enter your email first');
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
    final s = e.toString();
    if (s.contains('user_not_found') ||
        s.contains('No account with that email')) {
      return 'No account with that email. Tap Create account to sign up.';
    }
    if (s.contains('rate_limited')) {
      return 'Too many code requests. Please wait a minute.';
    }
    return 'Something went wrong. Please try again.';
  }

  bool _looksLikeEmail(String s) {
    final at = s.indexOf('@');
    return s.length >= 5 && at > 0 && s.substring(at + 1).contains('.');
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('invalid_credentials')) {
      return 'Email or password is incorrect.';
    }
    if (s.contains('rate_limited')) {
      return 'Too many attempts. Try again shortly.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLogin = _mode == _Mode.login;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: p.background,
      body: LivelyBackdrop(
        seed: 11,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Center(child: LivelyLogo(size: 108)),
                const SizedBox(height: 26),

                // hero
                Text(
                  (isLogin ? 'Welcome back' : 'Create account').toUpperCase(),
                  style: LivelyType.kicker(p.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  isLogin ? 'Sign in' : 'Begin your journey',
                  style: LivelyType.d2(p.textPrimary),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 290,
                  child: Text(
                    isLogin
                        ? 'Your cosmic mirror is waiting. Sign in to continue.'
                        : 'A few details and the stars are yours to explore.',
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
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 14),
                LivelyField(
                  controller: _password,
                  label: 'Password',
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
                  label: isLogin ? 'Sign in' : 'Create account',
                  loading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 12),
                GoldButton(
                  label: 'Sign in with a code instead',
                  ghost: true,
                  onPressed: _busy ? null : _signInWithCode,
                ),
                if (isLogin) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed:
                          _busy ? null : () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot your password?',
                        style: LivelyType.small(p.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
          seg('Sign in', target: _Mode.login),
          seg('Create account', target: _Mode.register),
        ],
      ),
    );
  }
}
