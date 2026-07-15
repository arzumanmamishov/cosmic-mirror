// Local-auth Riverpod surface. Replaces the Firebase-driven providers.
// UI screens watch [authControllerProvider] for the signed-in AppUser?
// and call methods on the controller for every /auth/* endpoint.

import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/features/auth/data/auth_api.dart';
import 'package:cosmic_mirror/features/auth/data/models/auth_tokens.dart';
import 'package:cosmic_mirror/features/auth/domain/entities/user.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Re-export so screens can reference OtpPurpose without importing the data
// layer directly.
export 'package:cosmic_mirror/features/auth/data/auth_api.dart'
    show OtpPurpose;

/// The API client. Constructed with an `onSessionExpired` callback that
/// asks the AuthController to flip to signed-out — the router redirect
/// picks it up on the next frame.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    onSessionExpired: () {
      // Best-effort: also called from ApiClient's own catch block, so a
      // no-op when the controller was already reset is fine.
      ref.read(authControllerProvider.notifier).sessionExpired();
    },
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(apiClientProvider));
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

/// Owns the "who is signed in right now" state and every mutation of it.
/// AsyncValue<AppUser?> lets the router treat 'loading', 'signed in',
/// and 'signed out' as three distinct states without a separate flag.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // Cold start: if we have a non-expired refresh, the user is
    // considered signed in until proven otherwise. The next protected
    // fetch will refresh the access token on-demand.
    final tokens = await authStorage.read();
    if (tokens == null || tokens.refreshExpired) return null;
    return _stubUserFromTokens(tokens);
  }

  Future<void> requestOtp(String email, OtpPurpose purpose) async {
    await ref.read(authApiProvider).requestOtp(email, purpose);
  }

  Future<void> register({
    required String email,
    required String code,
    required String name,
    String? password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authApiProvider).register(
            email: email,
            code: code,
            name: name,
            password: password,
          );
      await authStorage.write(result.tokens);
      _hydrateUserProvider(result.user);
      return result.user;
    });
    _rethrowOnError();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authApiProvider).login(
            email: email,
            password: password,
          );
      await authStorage.write(result.tokens);
      _hydrateUserProvider(result.user);
      return result.user;
    });
    _rethrowOnError();
  }

  Future<void> loginWithOtp({
    required String email,
    required String code,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authApiProvider).loginWithOtp(
            email: email,
            code: code,
          );
      await authStorage.write(result.tokens);
      _hydrateUserProvider(result.user);
      return result.user;
    });
    _rethrowOnError();
  }

  /// Populate currentUserProvider from the AuthResult synchronously so the
  /// router's `sessionReady` check flips true the moment auth succeeds —
  /// otherwise the redirect stays parked on /auth waiting for
  /// bootstrapSession, and if the OTP screen unmounts (user swipes back,
  /// hardware back, etc.) the follow-up context.go('/onboarding') never
  /// fires. Doing the hydrate here means we don't depend on any screen
  /// still being alive.
  void _hydrateUserProvider(AppUser user) {
    ref.read(currentUserProvider.notifier).hydrateFromAuth(
          id: user.id,
          name: user.name,
          email: user.email,
          avatarUrl: user.avatarUrl,
          hasCompletedOnboarding: user.hasCompletedOnboarding,
        );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await ref.read(authApiProvider).passwordReset(
          email: email,
          code: code,
          newPassword: newPassword,
        );
  }

  Future<void> logout() async {
    final tokens = await authStorage.read();
    if (tokens != null) {
      // Best-effort — a network hiccup at logout time shouldn't strand
      // the user still "signed in" on device.
      try {
        await ref.read(authApiProvider).logout(tokens.refreshToken);
      } catch (_) {
        // Swallow.
      }
    }
    await authStorage.clear();
    state = const AsyncValue.data(null);
  }

  /// Called by the API interceptor when a refresh terminally fails.
  void sessionExpired() {
    state = const AsyncValue.data(null);
  }

  void _rethrowOnError() {
    final s = state;
    if (s is AsyncError) {
      final err = s.error;
      if (err != null) {
        // ignore: only_throw_errors
        throw err;
      }
    }
  }

  /// Builds a placeholder AppUser from the persisted tokens' claims. The
  /// router only needs `id` non-empty to consider the user signed in;
  /// the next /users/me fetch backfills the real name / avatar.
  AppUser _stubUserFromTokens(AuthTokens tokens) {
    try {
      final parts = tokens.accessToken.split('.');
      if (parts.length < 2) return const AppUser(id: '', email: '');
      final payload = _base64UrlDecode(parts[1]);
      final uid = _stringFromJson(payload, '"uid":"', '"');
      final sub = _stringFromJson(payload, '"sub":"', '"');
      return AppUser(id: uid ?? sub ?? '', email: '');
    } catch (_) {
      return const AppUser(id: '', email: '');
    }
  }

  String _base64UrlDecode(String seg) {
    final pad = 4 - seg.length % 4;
    final padded = pad == 4 ? seg : seg + ('=' * pad);
    final normalized = padded.replaceAll('-', '+').replaceAll('_', '/');
    // Deliberately lax — we only read the uid string out of the JSON;
    // the router does not trust these bytes for anything sensitive.
    return String.fromCharCodes(
      normalized.runes.where((c) => c > 0x1F && c < 0x7F),
    );
  }

  String? _stringFromJson(String s, String needle, String terminator) {
    final start = s.indexOf(needle);
    if (start == -1) return null;
    final end = s.indexOf(terminator, start + needle.length);
    if (end == -1) return null;
    return s.substring(start + needle.length, end);
  }
}
