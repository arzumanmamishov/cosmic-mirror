/// The (access, refresh) pair issued by every successful auth endpoint.
/// Access is a short-lived HS256 JWT the API interceptor sends as a
/// bearer; refresh is opaque server-issued and only used against
/// POST /auth/refresh.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      accessExpiresAt: DateTime.tryParse(json['access_expires_at'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
      refreshToken: json['refresh_token'] as String? ?? '',
      refreshExpiresAt: DateTime.tryParse(json['refresh_expires_at'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'access_expires_at': accessExpiresAt.toIso8601String(),
        'refresh_token': refreshToken,
        'refresh_expires_at': refreshExpiresAt.toIso8601String(),
      };

  /// True when the access token has ≤ 30 s of life left — the API
  /// interceptor uses this to preemptively refresh, so a request in
  /// flight doesn't get a 401 mid-parse.
  bool get accessNearExpiry =>
      DateTime.now().toUtc().isAfter(accessExpiresAt.subtract(const Duration(seconds: 30)));

  /// True when the refresh token itself has expired — the session is
  /// dead and the user must sign in again.
  bool get refreshExpired => DateTime.now().toUtc().isAfter(refreshExpiresAt);
}
