class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode, this.code});

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
