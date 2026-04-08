import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';
import 'cosmic_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: CosmicColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              style: CosmicTypography.bodyMedium.copyWith(
                color: CosmicColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CosmicButton(
                label: 'Try Again',
                onPressed: onRetry,
                fullWidth: false,
                gradient: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
