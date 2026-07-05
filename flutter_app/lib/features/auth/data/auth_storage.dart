// Encrypted storage for the auth tokens. Refresh tokens are long-lived
// bearer credentials — they belong in the platform keychain
// (`flutter_secure_storage`), NOT `shared_preferences`, so a jailbroken
// device or plaintext backup can't lift them out of a plist / xml.
//
// The access token is short-lived and would be fine in shared prefs, but
// we keep both together so the API interceptor has one place to reach for.

import 'dart:convert';

import 'package:cosmic_mirror/features/auth/data/models/auth_tokens.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokensKey = 'auth.tokens.v1';

  final FlutterSecureStorage _storage;

  /// Reads the persisted tokens, or null when the user has never signed
  /// in (or logged out). Returns null instead of throwing when the JSON
  /// is corrupt so a bad write doesn't lock the user out — the caller
  /// falls back to the sign-in screen.
  Future<AuthTokens?> read() async {
    final raw = await _storage.read(key: _tokensKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _storage.delete(key: _tokensKey);
      return null;
    }
  }

  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _tokensKey, value: jsonEncode(tokens.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokensKey);
  }
}
