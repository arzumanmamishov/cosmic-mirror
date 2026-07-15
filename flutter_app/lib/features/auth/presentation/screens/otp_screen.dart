// Unified OTP entry screen — handles register / login / password-reset via
// a single route parameterised by `purpose`. Shows a 6-cell code entry,
// a 30-second resend cooldown, and (for password reset) a new-password
// field that appears once the code is filled.

import 'dart:async';
import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Extra payload piggybacked on the /otp route for register — the name +
/// optional password entered on the register screen. Nothing PII goes
/// through the URL (the router uses `extra` for this).
class PendingRegistration {
  const PendingRegistration({
    required this.name,
    this.password,
  });
  final String name;
  final String? password;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    required this.email,
    required this.purpose,
    this.pendingRegistration,
    super.key,
  });

  final String email;
  final OtpPurpose purpose;
  final PendingRegistration? pendingRegistration;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _codeFocus = FocusNode();

  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // Kick off the initial code request in the next frame so the user
    // sees the screen render first — then the "resend in 30s" timer
    // appears with a clear sense of what just happened.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestCode());
    // Auto-verify once the code is 6 digits (except for password_reset,
    // which needs the new-password field filled first).
    _codeCtrl.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeCtrl
      ..removeListener(_onCodeChanged)
      ..dispose();
    _newPasswordCtrl.dispose();
    _codeFocus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
    if (_codeCtrl.text.length == 6 &&
        widget.purpose != OtpPurpose.passwordReset &&
        !_busy) {
      _verify();
    }
  }

  Future<void> _requestCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestOtp(widget.email, widget.purpose);
      _startCooldown();
    } catch (_) {
      // Silent: even if the email doesn't exist we don't tell the user
      // via a hard error here (backend already handles that decision).
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text;
    if (code.length != 6) return;
    if (widget.purpose == OtpPurpose.passwordReset &&
        _newPasswordCtrl.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ctrl = ref.read(authControllerProvider.notifier);
      switch (widget.purpose) {
        case OtpPurpose.register:
          await ctrl.register(
            email: widget.email,
            code: code,
            name: widget.pendingRegistration?.name ?? '',
            password: widget.pendingRegistration?.password,
          );
        case OtpPurpose.login:
          await ctrl.loginWithOtp(email: widget.email, code: code);
        case OtpPurpose.passwordReset:
          await ctrl.resetPassword(
            email: widget.email,
            code: code,
            newPassword: _newPasswordCtrl.text,
          );
      }
      if (!mounted) return;
      if (widget.purpose == OtpPurpose.passwordReset) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated. Please sign in.')),
        );
        context.go('/auth');
      } else {
        // register / login: AuthController.register/login already seeded
        // currentUserProvider synchronously, so the router redirect fired
        // by the state change will move us off /otp on its own. We still
        // call context.go as a belt-and-braces so the transition is
        // deterministic even if the router debounces its refresh pulse.
        context.go(
          widget.purpose == OtpPurpose.register ? '/onboarding' : '/',
        );
        if (widget.purpose == OtpPurpose.login) {
          // Kick a full bootstrap for the chart summary fields, but
          // don't block navigation on it — the router already moved.
          unawaited(ref.read(currentUserProvider.notifier).bootstrapSession());
        }
      }
    } catch (e) {
      // Guard: user may have tapped Back while _verify awaited; the
      // widget (and _shake controller) are then disposed and touching
      // them throws.
      if (!mounted) return;
      unawaited(HapticFeedback.heavyImpact());
      _shake.reset();
      unawaited(_shake.forward());
      setState(() {
        _error = _prettyError(e);
        _codeCtrl.clear();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('invalid_code') ||
        s.contains('Invalid or expired code')) {
      return "That code didn't work. Try again or resend.";
    }
    if (s.contains('rate_limited')) {
      return 'Too many attempts. Please wait a minute.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final headline = switch (widget.purpose) {
      OtpPurpose.register => 'Confirm your email',
      OtpPurpose.login => 'Sign in',
      OtpPurpose.passwordReset => 'Reset your password',
    };

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
                  headline.toUpperCase(),
                  style: LivelyType.kicker(p.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Check your email',
                  style: LivelyType.d2(p.textPrimary),
                ),
                const SizedBox(height: 14),
                Text(
                  'We sent a 6-digit code to ${widget.email}.',
                  style: LivelyType.body(p.textMuted),
                ),
                const SizedBox(height: 28),
                _CodeCells(
                  controller: _codeCtrl,
                  focus: _codeFocus,
                  shake: _shake,
                  errored: _error != null,
                ),
                if (widget.purpose == OtpPurpose.passwordReset) ...[
                  const SizedBox(height: 20),
                  LivelyField(
                    controller: _newPasswordCtrl,
                    label: 'New password',
                    hint: '••••••••',
                    obscure: true,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: LivelyType.small(p.error)),
                ],
                const SizedBox(height: 20),
                if (widget.purpose == OtpPurpose.passwordReset)
                  GoldButton(
                    label: 'Reset password',
                    loading: _busy,
                    onPressed: _busy ? null : _verify,
                  ),
                const SizedBox(height: 12),
                Center(
                  child: _cooldown > 0
                      ? Text(
                          'Resend code in 0:${_cooldown.toString().padLeft(2, '0')}',
                          style: LivelyType.small(p.textDim),
                        )
                      : TextButton(
                          onPressed: _busy ? null : _requestCode,
                          child: Text(
                            'Resend code',
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

class _CodeCells extends StatelessWidget {
  const _CodeCells({
    required this.controller,
    required this.focus,
    required this.shake,
    required this.errored,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final AnimationController shake;
  final bool errored;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: shake,
      builder: (ctx, child) {
        final t = shake.value;
        // A short damped sine wave — 4 cycles, fading out.
        final dx = t == 0 ? 0.0 : math.sin(t * 4 * math.pi) * (1 - t) * 12;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Stack(
        children: [
          // Invisible text field owns the real input; the visible cells
          // just mirror its state.
          Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) {},
            ),
          ),
          GestureDetector(
            onTap: focus.requestFocus,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(6, (i) {
                final text = i < controller.text.length ? controller.text[i] : '';
                final current = i == controller.text.length;
                Color border;
                if (errored) {
                  border = p.error;
                } else if (current) {
                  border = p.primary;
                } else if (text.isNotEmpty) {
                  border = p.primary.withValues(alpha: 0.55);
                } else {
                  border = p.textTertiary.withValues(alpha: 0.3);
                }
                return Container(
                  width: 44,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: text.isNotEmpty
                        ? p.primary.withValues(alpha: 0.10)
                        : p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 1.6),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
