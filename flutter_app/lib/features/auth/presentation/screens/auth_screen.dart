// Sign-in screen for the SMTP-OTP flow. Two panes on one screen (login /
// register) swap via a small segmented toggle so a returning user doesn't
// have to dig for the register link.

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/features/auth/presentation/screens/otp_screen.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
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
    if (_mode == _Mode.register && _name.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
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
              name: _name.text.trim(),
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
  Future<void> _forgotPassword() =>
      _requestCodeAndRoute(OtpPurpose.passwordReset);

  /// Shared path for the two "no password, send me a code" buttons. Only
  /// pushes to /otp when the backend confirms the address is registered —
  /// otherwise surfaces "no account" inline so the user can switch to
  /// Create account instead of chasing a code that will never arrive.
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
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lively',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() {
                  _mode = m;
                  _error = null;
                }),
              ),
              const SizedBox(height: 24),
              if (_mode == _Mode.register)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: p.error, fontSize: 13.5)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  _busy
                      ? 'Please wait…'
                      : (_mode == _Mode.login
                          ? 'Sign in'
                          : 'Create account'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _signInWithCode,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Sign in with a code instead'),
              ),
              const SizedBox(height: 8),
              if (_mode == _Mode.login)
                TextButton(
                  onPressed: _busy ? null : _forgotPassword,
                  child: const Text('Forgot your password?'),
                ),
            ],
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
