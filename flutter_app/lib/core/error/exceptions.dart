class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode, this.code});

  /// Placeholder message used when the server didn't supply one. UI code
  /// should treat this as "no message" and show a localized fallback.
  static const fallbackMessage = 'An unexpected error occurred.';

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  const NetworkException({
    this.message = 'No internet connection.',
  });

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  const CacheException({this.message = 'Cache error occurred.'});

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  const AuthException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException: $message';
}

class RateLimitException implements Exception {
  const RateLimitException({
    this.message = 'Rate limit exceeded.',
    this.retryAfter,
    this.code,
    this.used,
    this.limit,
    this.resetAt,
  });

  final String message;
  final Duration? retryAfter;

  /// Stable error code from the backend (e.g. `chat_limit_reached`) so
  /// callers can match against specific limits without parsing strings.
  final String? code;

  /// How many actions the user has consumed today.
  final int? used;

  /// Daily cap that triggered the limit.
  final int? limit;

  /// Server-provided UTC timestamp when the counter resets.
  final DateTime? resetAt;

  @override
  String toString() => 'RateLimitException: $message';
}

/// The backend's machine-readable error code (`{"error": {"code": …}}`)
/// carried by an API exception, or null. Match on this rather than on
/// `toString()`: the exceptions' string forms only include the message.
String? apiErrorCode(Object error) => switch (error) {
      ServerException(:final code) => code,
      AuthException(:final code) => code,
      RateLimitException(:final code) => code,
      _ => null,
    };

/// The backend refused because a moderator banned the account.
bool isAccountBanned(Object error) => apiErrorCode(error) == 'account_banned';
