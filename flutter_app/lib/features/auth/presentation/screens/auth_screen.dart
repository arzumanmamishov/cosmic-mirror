import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/features/auth/presentation/widgets/firebase_auth_error.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/lively_logo.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Solid dark-gold accent — matches the LIVELY brand bronze tone.
const _kGold = Color(0xFFD4B16A);
const _kGoldDark = Color(0xFF9F7637);

/// Auth screen — clean, minimal layout matching the reference design:
/// LIVELY logo at the top, sans-serif Welcome hero, dark inputs with
/// leading icons, Remember me + Forgot password inline, gold-gradient
/// Sign in button, and a Register link at the bottom that toggles between
/// sign-in and create-account modes (same visual layout, only label and
/// extra confirm-password field differ).
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
  bool _remember = true;
  String? _localError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _isSignUp => _mode == _AuthMode.signUp;

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

  /// Opens the "forgot password" dialog. Pre-fills the email field if the
  /// user has already typed one above. Sends a Firebase password-reset
  /// link on confirm and shows the outcome inline (success → success
  /// snackbar, failure → localized error in the dialog).
  Future<void> _openForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController(text: _email.text.trim());
    String? inlineError;
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                setDialogState(() => inlineError = l10n.authResetPasswordEmailEmpty);
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
                  SnackBar(
                    content: Text(l10n.authResetPasswordSent(email)),
                  ),
                );
              } else {
                setDialogState(() {
                  sending = false;
                  inlineError = localizedFirebaseAuthError(l10n, code);
                });
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF222637),
              title: Text(
                l10n.authResetPasswordTitle,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.authResetPasswordBody,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB6BAC4),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DarkField(
                    controller: emailController,
                    hint: l10n.authEmail,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (inlineError != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: inlineError!),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    l10n.authCancel,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB6BAC4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: sending ? null : submit,
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_kGold),
                          ),
                        )
                      : Text(
                          l10n.authResetPasswordSend,
                          style: GoogleFonts.poppins(
                            color: _kGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
    final authState = ref.watch(authActionProvider);
    final notifier = ref.read(authActionProvider.notifier);
    final l10n = AppLocalizations.of(context);
    // Firebase error codes from authState.error need localization at
    // render-time; client-side validation messages in _localError are
    // already localized at construction. We prefer _localError when set
    // so a fresh validation message immediately replaces a stale
    // server-side error.
    final error = _localError ??
        (authState.error != null
            ? localizedFirebaseAuthError(l10n, authState.error)
            : null);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F2E),
      // Don't resize the body when the keyboard opens — keeps the form
      // surface stable; we pad the bottom by the keyboard height instead.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  const SizedBox(height: 12),
                  const Center(child: _AnimatedLivelyLogo(size: 220)),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _isSignUp ? l10n.authCreateAccount : l10n.authWelcome,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _isSignUp
                          ? l10n.authSignUpSubtitle
                          : l10n.authWelcomeSubtitle,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB6BAC4),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _DarkField(
                    controller: _email,
                    hint: l10n.authEmail,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _DarkField(
                    controller: _password,
                    hint: l10n.authPassword,
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    trailing: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF7E8290),
                      ),
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 14),
                    _DarkField(
                      controller: _confirm,
                      hint: l10n.authConfirmPassword,
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscureConfirm,
                      trailing: GestureDetector(
                        onTap: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                        child: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFF7E8290),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _RememberMe(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                        ),
                        TextButton(
                          onPressed: () => _openForgotPasswordDialog(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.authForgotPassword,
                            style: GoogleFonts.poppins(
                              color: _kGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: error),
                  ],
                  const SizedBox(height: 22),
                  _PrimaryButton(
                    label: _isSignUp ? l10n.authCreateAccount : l10n.authSignIn,
                    loading: authState.isLoading &&
                        authState.activeMethod == AuthMethod.email,
                    onPressed: authState.isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _mode = _isSignUp ? _AuthMode.signIn : _AuthMode.signUp;
                        _localError = null;
                        notifier.clearError();
                      }),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFB6BAC4),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? l10n.authHaveAccount
                                  : l10n.authNoAccount,
                            ),
                            TextSpan(
                              text: _isSignUp ? l10n.authSignIn : l10n.authRegister,
                              style: GoogleFonts.poppins(
                                color: _kGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SocialDivider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: l10n.authContinueGoogle,
                          iconWidget: const _GoogleGlyph(),
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ),
    );
  }
}

// ============================================================================
// Dark field — same color as the page background (no fill), thin outline,
// leading icon, optional trailing icon.
// ============================================================================

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E), // identical to page background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3E)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7E8290), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              cursorColor: _kGold,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF7E8290),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Remember-me checkbox — flat square box + label.
// ============================================================================

class _RememberMe extends StatelessWidget {
  const _RememberMe({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? _kGold : const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: value ? _kGold : const Color(0xFF4A5066),
                width: 1.4,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).authRememberMe,
            style: GoogleFonts.poppins(
              color: const Color(0xFFB6BAC4),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Solid primary button — flat purple, rounded, with ripple feedback.
// ============================================================================

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

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
            color: disabled ? _kGoldDark.withValues(alpha: 0.5) : _kGoldDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Lightweight "or continue with" divider for the social row.
// ============================================================================

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xFF323849);
    return Row(
      children: [
        const Expanded(child: Divider(color: lineColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppLocalizations.of(context).authOrContinueWith.toUpperCase(),
            style: GoogleFonts.poppins(
              color: const Color(0xFF7E8290),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: lineColor, height: 1)),
      ],
    );
  }
}

// ============================================================================
// Social button — outlined dark surface, icon + label.
// ============================================================================

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
    this.iconWidget,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF323849)),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null)
                        Icon(icon, color: Colors.white, size: 20)
                      else if (iconWidget != null)
                        iconWidget!,
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          color:
                              disabled ? const Color(0xFF7E8290) : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
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
      child: Text(
        'G',
        style: GoogleFonts.poppins(
          color: const Color(0xFF4285F4),
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
    const errorColor = Color(0xFFF87171);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: errorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: errorColor,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Animated LIVELY logo — gentle scale pulse + breathing radial gold halo
// + slow rotating light rays behind the mark.
// ============================================================================

class _AnimatedLivelyLogo extends StatefulWidget {
  const _AnimatedLivelyLogo({required this.size});

  final double size;

  @override
  State<_AnimatedLivelyLogo> createState() => _AnimatedLivelyLogoState();
}

class _AnimatedLivelyLogoState extends State<_AnimatedLivelyLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final scale = 1.0 + 0.04 * t;
        return Transform.scale(
          scale: scale,
          child: LivelyLogo(size: widget.size),
        );
      },
    );
  }
}
