import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Full-screen error page — used by the router as a fallback for
/// unknown routes AND as the `ErrorWidget.builder` for any uncaught
/// widget-build exception. Same visual language as the in-screen
/// [ErrorView] but with a Scaffold + "go home" CTA so users always
/// have a way out.
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.error, this.stackTrace});

  /// The underlying error/exception. Routed through [FriendlyError] for
  /// the user-facing copy. Can be null when this page is used as a
  /// generic 404.
  final Object? error;

  /// Only included for `flutter_logs` debug dump — never shown to the user.
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);

    final friendly = error != null
        ? FriendlyError.from(context, error)
        : FriendlyError(
            title: l.errNotFoundTitle,
            body: l.errNotFoundBody,
            icon: Icons.search_off_rounded,
            retryable: false,
          );

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      p.gold.withValues(alpha: 0.22),
                      p.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Icon(friendly.icon, size: 56, color: p.gold),
              ),
              const SizedBox(height: 24),
              Text(
                friendly.title,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                friendly.body,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 14.5,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              // Debug-only: surface the raw exception so dev builds can
              // copy/paste it to the team. Hidden in release.
              if (kDebugMode && error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.glassBorder),
                  ),
                  child: Text(
                    error.toString(),
                    style: TextStyle(
                      color: p.textTertiary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: Text(l.errGoHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `ErrorWidget.builder` replacement — Flutter normally shows a red
/// box on widget-build crashes; we replace it with our cosmic-themed
/// crash card so the user sees something graceful even when something
/// went very wrong inside a widget tree.
Widget cosmicErrorWidgetBuilder(FlutterErrorDetails details) {
  return Material(
    color: const Color(0xFF1A1F2E),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFD4B16A),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'The cosmos hiccuped',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Something unexpected happened.\nRestart the app — if it keeps happening, let us know.',
              style: TextStyle(color: Color(0xFFB6BAC4), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(
                  color: Color(0xFF7E8290),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
