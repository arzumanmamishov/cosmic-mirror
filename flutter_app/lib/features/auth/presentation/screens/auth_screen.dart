import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/cosmic_button.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authActionProvider);
    final authNotifier = ref.read(authActionProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E27), Color(0xFF1A1040), Color(0xFF0A0E27)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                // Logo area
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: CosmicColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: CosmicColors.primary.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text('Lively', style: CosmicTypography.displayLarge),
                const SizedBox(height: 12),
                Text(
                  'Discover your cosmic blueprint.\nPersonalized astrology & daily guidance.',
                  style: CosmicTypography.bodyMedium.copyWith(
                    color: CosmicColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Error message
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CosmicColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CosmicColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: CosmicColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: CosmicTypography.bodySmall.copyWith(
                              color: CosmicColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Sign-in buttons
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  CosmicButton(
                    label: 'Continue with Apple',
                    icon: Icons.apple,
                    onPressed: authState.isLoading ? null : () => authNotifier.signInWithApple(),
                    isLoading: authState.activeMethod == AuthMethod.apple &&
                        authState.isLoading,
                    gradient: false,
                  ),
                  const SizedBox(height: 12),
                ],
                CosmicButton(
                  label: 'Continue with Google',
                  onPressed: authState.isLoading ? null : () => authNotifier.signInWithGoogle(),
                  isLoading: authState.activeMethod == AuthMethod.google &&
                      authState.isLoading,
                  gradient: false,
                ),
                const SizedBox(height: 12),
                CosmicButton(
                  label: 'Continue with Email',
                  onPressed: authState.isLoading
                      ? null
                      : () => _showEmailSignIn(context, ref),
                ),
                const SizedBox(height: 24),
                Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                  style: CosmicTypography.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  void _showEmailSignIn(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CosmicColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CosmicColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Sign in with Email', style: CosmicTypography.headlineMedium),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              CosmicButton(
                label: 'Sign In',
                onPressed: () {
                  ref.read(authActionProvider.notifier).signInWithEmail(
                        emailController.text.trim(),
                        passwordController.text,
                      );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Handle sign up or password reset
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
