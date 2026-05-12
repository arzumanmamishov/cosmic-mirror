import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The app's universal "something went wrong" widget. Pass it ANY
/// thrown error and it figures out the right title + body + icon by
/// running it through [FriendlyError.from]. Falls back to the legacy
/// raw-message API when callers haven't been migrated yet.
///
/// Typical usage from a Riverpod `.when(error: ...)` handler:
///
/// ```dart
/// error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(p)),
/// ```
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.error,
    this.message,
    this.onRetry,
    this.icon,
  });

  /// Preferred: pass the raw thrown error and let us localize it.
  final Object? error;

  /// Legacy: callers that already have a string (from older code paths).
  /// If both [error] and [message] are passed, [error] wins.
  final String? message;

  /// Called when the user taps "Try again". If null, the button is
  /// hidden. The friendly-error mapper may also hide it for
  /// non-retryable failures like auth expiry.
  final VoidCallback? onRetry;

  /// Legacy override — older call sites pass an icon directly. New
  /// code should let [FriendlyError] pick it based on the error type.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);

    // Resolve the friendly title/body/icon. If we only got a legacy
    // string, synthesize a generic-title body around it.
    final friendly = error != null
        ? FriendlyError.from(context, error)
        : FriendlyError(
            title: l.errGenericTitle,
            body: message ?? l.errGenericBody,
            icon: icon ?? Icons.error_outline_rounded,
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.gold.withValues(alpha: 0.18),
                    p.gold.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Icon(friendly.icon, size: 44, color: p.gold),
            ),
            const SizedBox(height: 18),
            Text(
              friendly.title,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              friendly.body,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null && friendly.retryable) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.errRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
