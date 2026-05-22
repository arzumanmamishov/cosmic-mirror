import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/features/auth/presentation/widgets/firebase_auth_error.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_field.dart';
import 'package:cosmic_mirror/shared/widgets/lively_logo.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth — the Lively first-impression screen. Cosmic backdrop, a serif
/// hero, and a bottom-anchored form. Toggles between sign-in and
/// create-account modes (the latter adds a confirm-password field).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthMode { signIn, signUp }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _localError;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final l10n = AppLocalizations.of(context);
    setState(() => _localError = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() => _localError = l10n.authEmailRequired);
      return;
    }
    if (_isSignUp && password != _confirm.text) {
      setState(() => _localError = l10n.authPasswordsDontMatch);
      return;
    }
    if (_isSignUp && password.length < 8) {
      setState(() => _localError = l10n.authPasswordTooShort);
      return;
    }

    final notifier = ref.read(authActionProvider.notifier);
    if (_isSignUp) {
      await notifier.signUpWithEmail(email, password);
    } else {
      await notifier.signInWithEmail(email, password);
    }
  }

  /// Forgot-password dialog: pre-fills the email already typed, sends a
  /// Firebase reset link, shows success as a snackbar and failure inline.
  Future<void> _openForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final emailController = TextEditingController(text: _email.text.trim());
    String? inlineError;
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                setDialogState(
                    () => inlineError = l10n.authResetPasswordEmailEmpty);
                return;
              }
              setDialogState(() {
                inlineError = null;
                sending = true;
              });
              final code = await ref
                  .read(authActionProvider.notifier)
                  .sendPasswordResetEmail(email);
              if (!dialogContext.mounted) return;
              if (code == null) {
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.authResetPasswordSent(email))),
                );
              } else {
                setDialogState(() {
                  sending = false;
                  inlineError = localizedFirebaseAuthError(l10n, code);
                });
              }
            }

            return AlertDialog(
              backgroundColor: p.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: p.glassBorder),
              ),
              title: Text(
                l10n.authResetPasswordTitle,
                style: LivelyType.h1(p.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.authResetPasswordBody,
                    style: LivelyType.small(p.textMuted),
                  ),
                  const SizedBox(height: 16),
                  LivelyField(
                    controller: emailController,
                    hint: l10n.authEmail,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (inlineError != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: inlineError!),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              actions: [
                TextButton(
                  onPressed:
                      sending ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    l10n.authCancel,
                    style: LivelyType.button(p.textMuted, size: 14),
                  ),
                ),
                GoldButton(
                  label: l10n.authResetPasswordSend,
                  small: true,
                  full: false,
                  loading: sending,
                  onPressed: sending ? null : submit,
                ),
              ],
            );
          },
        );
      },
    );
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authActionProvider);
    final notifier = ref.read(authActionProvider.notifier);
    final bootstrapError =
        ref.watch(currentUserProvider.select((s) => s.bootstrapError));

    // Error precedence: client validation → Firebase code → bootstrap.
    String? error = _localError;
    if (error == null && authState.error != null) {
      error = localizedFirebaseAuthError(l10n, authState.error);
    }
    if (error == null && bootstrapError != null) {
      final friendly = FriendlyError.from(context, bootstrapError);
      error = '${friendly.title} — ${friendly.body}';
    }

    final emailLoading =
        authState.isLoading && authState.activeMethod == AuthMethod.email;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LivelyBackdrop(
        seed: 11,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
            child: ConstrainedBox(
              // Clamp to >= 0: on the very first frame MediaQuery.size
              // can be zero, which made this go negative → "BoxConstraints
              // has a negative minimum height" → blank screen.
              constraints: BoxConstraints(
                minHeight: (MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical -
                        36)
                    .clamp(0.0, double.infinity),
              ),
              // IntrinsicHeight gives the Column a bounded height inside
              // the scroll view so the Spacer() between hero and form
              // has something to flex into. Without it the Spacer's
              // Expanded hits unbounded constraints → "RenderBox was not
              // laid out" → blank screen.
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: LivelyLogo(size: 48),
                  ),
                  const SizedBox(height: 76),

                  // hero
                  Text(
                    (_isSignUp ? l10n.authCreateAccount : l10n.authWelcome)
                        .toUpperCase(),
                    style: LivelyType.kicker(p.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSignUp ? l10n.authHeroSignUp : l10n.authHeroSignIn,
                    style: LivelyType.d2(p.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 290,
                    child: Text(
                      _isSignUp
                          ? l10n.authSignUpSubtitle
                          : l10n.authWelcomeSubtitle,
                      style: LivelyType.body(p.textMuted),
                    ),
                  ),

                  const Spacer(),

                  // form
                  const SizedBox(height: 32),
                  LivelyField(
                    controller: _email,
                    label: l10n.authEmail,
                    hint: l10n.authEmail,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  LivelyField(
                    controller: _password,
                    label: l10n.authPassword,
                    hint: l10n.authPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    trailing: _EyeToggle(
                      obscured: _obscure,
                      onTap: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 14),
                    LivelyField(
                      controller: _confirm,
                      label: l10n.authConfirmPassword,
                      hint: l10n.authConfirmPassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: _obscureConfirm,
                      trailing: _EyeToggle(
                        obscured: _obscureConfirm,
                        onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _openForgotPasswordDialog,
                        child: Text(
                          l10n.authForgotPassword,
                          style: LivelyType.small(p.primary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],

                  if (error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: error),
                  ],

                  const SizedBox(height: 22),
                  GoldButton(
                    label: _isSignUp
                        ? l10n.authCreateAccount
                        : l10n.authSignIn,
                    loading: emailLoading,
                    onPressed: authState.isLoading ? null : _submit,
                  ),

                  // divider
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: p.line, height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.authOrContinueWith.toUpperCase(),
                          style: LivelyType.caption(p.textMuted),
                        ),
                      ),
                      Expanded(child: Divider(color: p.line, height: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // socials
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: l10n.authContinueGoogle,
                          glyph: const _GoogleGlyph(),
                          loading: authState.isLoading &&
                              authState.activeMethod == AuthMethod.google,
                          onPressed: authState.isLoading
                              ? null
                              : notifier.signInWithGoogle,
                        ),
                      ),
                      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: l10n.authContinueApple,
                            icon: Icons.apple_rounded,
                            loading: authState.isLoading &&
                                authState.activeMethod == AuthMethod.apple,
                            onPressed: authState.isLoading
                                ? null
                                : notifier.signInWithApple,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _mode =
                            _isSignUp ? _AuthMode.signIn : _AuthMode.signUp;
                        _localError = null;
                        notifier.clearError();
                      }),
                      child: RichText(
                        text: TextSpan(
                          style: LivelyType.small(p.textMuted),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? l10n.authHaveAccount
                                  : l10n.authNoAccount,
                            ),
                            TextSpan(
                              text: _isSignUp
                                  ? l10n.authSignIn
                                  : l10n.authRegister,
                              style: LivelyType.small(p.primary)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Pieces
// ───────────────────────────────────────────────────────────────

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscured, required this.onTap});
  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        obscured
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        size: 19,
        color: context.palette.textMuted,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
    this.glyph,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? glyph;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? p.surfaceGlass : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.line),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(p.textPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, color: p.textPrimary, size: 20)
                  else if (glyph != null)
                    glyph!,
                  const SizedBox(width: 10),
                  Text(label, style: LivelyType.button(p.textPrimary, size: 14)),
                ],
              ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: p.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: LivelyType.small(p.error)),
          ),
        ],
      ),
    );
  }
}
