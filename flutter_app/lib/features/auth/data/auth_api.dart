// AuthApi is the thin Dart mirror of the backend /auth/* endpoints.
// Every method returns the deserialised response or throws — the
// providers layer wraps the throws into typed states so the UI can
// render friendly messages.

import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/features/auth/data/models/auth_tokens.dart';
import 'package:cosmic_mirror/features/auth/domain/entities/user.dart';

/// OtpPurpose maps 1:1 to the backend `otp_purpose` enum. Passed as the
/// `purpose` query param when requesting a code.
enum OtpPurpose {
  register('register'),
  login('login'),
  passwordReset('password_reset');

  const OtpPurpose(this.wire);
  final String wire;
}

/// AuthResult is what the sign-in paths return: the freshly minted
/// user + the tokens the caller needs to persist. Wraps the backend's
/// `{ data: { user, tokens } }` envelope so the UI layer never touches
/// the transport shape.
class AuthResult {
  const AuthResult({required this.user, required this.tokens});

  factory AuthResult.fromEnvelope(Map<String, dynamic> data) {
    final userJson = data['user'] as Map<String, dynamic>;
    return AuthResult(
      user: AppUser(
        id: userJson['id'] as String? ?? '',
        email: userJson['email'] as String? ?? '',
        name: userJson['name'] as String?,
        avatarUrl: userJson['avatar_url'] as String?,
        hasCompletedOnboarding:
            userJson['has_completed_onboarding'] as bool? ?? false,
      ),
      tokens: AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>),
    );
  }

  final AppUser user;
  final AuthTokens tokens;
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<void> requestOtp(String email, OtpPurpose purpose) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/otp/request',
      data: {'email': email, 'purpose': purpose.wire},
    );
  }

  Future<AuthResult> register({
    required String email,
    required String code,
    required String name,
    String? password,
  }) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {
        'email': email,
        'code': code,
        'name': name,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
    return AuthResult.fromEnvelope(resp['data'] as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResult.fromEnvelope(resp['data'] as Map<String, dynamic>);
  }

  Future<AuthResult> loginWithOtp({
    required String email,
    required String code,
  }) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/login/otp',
      data: {'email': email, 'code': code},
    );
    return AuthResult.fromEnvelope(resp['data'] as Map<String, dynamic>);
  }

  Future<void> passwordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/password/reset',
      data: {'email': email, 'code': code, 'new_password': newPassword},
    );
  }

  Future<void> logout(String refreshToken) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/logout',
      data: {'refresh_token': refreshToken},
    );
  }
}
