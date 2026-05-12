import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Maps any thrown error/exception to a friendly, localized message
/// the user can actually act on. Every ErrorView in the app should run
/// the raw exception through this so we stop showing stack traces or
/// raw `DioException [unknown]: null` to people.
///
/// Returns both a headline + body so callers can render two-line errors
/// (the headline is short + scannable; the body explains what to do).
class FriendlyError {
  const FriendlyError({
    required this.title,
    required this.body,
    required this.icon,
    this.retryable = true,
  });

  factory FriendlyError.from(BuildContext context, Object? error) {
    final l = AppLocalizations.of(context);

    if (error is NetworkException) {
      return FriendlyError(
        title: l.errOfflineTitle,
        body: l.errOfflineBody,
        icon: Icons.wifi_off_rounded,
      );
    }
    if (error is AuthException) {
      return FriendlyError(
        title: l.errAuthTitle,
        body: l.errAuthBody,
        icon: Icons.lock_outline_rounded,
        retryable: false,
      );
    }
    if (error is RateLimitException) {
      final body = error.code == 'chat_limit_reached'
          ? l.errChatLimitBody
          : l.errRateLimitBody;
      return FriendlyError(
        title: l.errRateLimitTitle,
        body: body,
        icon: Icons.hourglass_bottom_rounded,
        retryable: false,
      );
    }
    if (error is ServerException) {
      final sc = error.statusCode ?? 0;
      if (sc == 404) {
        return FriendlyError(
          title: l.errNotFoundTitle,
          body: l.errNotFoundBody,
          icon: Icons.search_off_rounded,
          retryable: false,
        );
      }
      if (sc >= 500) {
        return FriendlyError(
          title: l.errServerTitle,
          body: l.errServerBody,
          icon: Icons.cloud_off_rounded,
        );
      }
      // Anything else (400, 403, 422…) — show the server's own message
      // if it's safe, fall back to a generic line.
      return FriendlyError(
        title: l.errGenericTitle,
        body: error.message.isNotEmpty ? error.message : l.errGenericBody,
        icon: Icons.error_outline_rounded,
      );
    }
    if (error is CacheException) {
      return FriendlyError(
        title: l.errGenericTitle,
        body: l.errCacheBody,
        icon: Icons.storage_rounded,
      );
    }
    // Fallback for anything else (Dart errors, third-party exceptions).
    return FriendlyError(
      title: l.errGenericTitle,
      body: l.errGenericBody,
      icon: Icons.error_outline_rounded,
    );
  }

  final String title;
  final String body;
  final IconData icon;

  /// True if a "Try again" button makes sense (network/server errors).
  /// False for permanent failures (auth expired, rate limit) where
  /// retrying without intervention won't help.
  final bool retryable;
}
