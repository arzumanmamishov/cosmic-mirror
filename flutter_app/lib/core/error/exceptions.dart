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
  });

  final String message;
  final Duration? retryAfter;

  @override
  String toString() => 'RateLimitException: $message';
}
