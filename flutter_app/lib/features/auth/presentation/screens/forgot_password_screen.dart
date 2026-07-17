// Dedicated "forgot password" screen. The user enters the email for the
// account they can't get into, we confirm it's registered + send a reset
// code, then push to /otp (purpose: passwordReset) where they enter the
// code and choose a new password.

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/features/auth/presentation/screens/auth_screen.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String s) {
    final at = s.indexOf('@');
    return s.length >= 5 && at > 0 && s.substring(at + 1).contains('.');
  }

  /// Only routes to /otp when the backend confirms the address is
  /// registered — otherwise surfaces "no account" inline so the user
  /// isn't left waiting for a code that will never arrive.
  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestOtp(email, OtpPurpose.passwordReset);
      if (!mounted) return;
      await context.push<void>(
        '/otp',
        extra: OtpRouteArgs(email: email, purpose: OtpPurpose.passwordReset),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _prettyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('user_not_found') ||
        s.contains('No account with that email')) {
      return 'No account with that email. Check the address or create one.';
    }
    if (s.contains('rate_limited')) {
      return 'Too many code requests. Please wait a minute.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: LivelyBackdrop(
        seed: 11,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESET PASSWORD',
                  style: LivelyType.kicker(p.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Forgot your password?',
                  style: LivelyType.d2(p.textPrimary),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 300,
                  child: Text(
                    "Enter your email and we'll send you a code to set a new "
                    'password.',
                    style: LivelyType.body(p.textMuted),
                  ),
                ),
                const SizedBox(height: 28),
                LivelyField(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _busy ? null : _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: LivelyType.small(p.error)),
                ],
                const SizedBox(height: 22),
                GoldButton(
                  label: 'Send reset code',
                  loading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => context.pop(),
                    child: Text(
                      'Back to sign in',
                      style: LivelyType.small(p.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
