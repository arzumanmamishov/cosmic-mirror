// Local-auth Riverpod surface. Replaces the Firebase-driven providers.
// UI screens watch [authControllerProvider] for the signed-in AppUser?
// and call methods on the controller for every /auth/* endpoint.

import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/auth/data/auth_api.dart';
import 'package:cosmic_mirror/features/auth/data/models/auth_tokens.dart';
import 'package:cosmic_mirror/features/auth/domain/entities/user.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/life_timeline/data/life_timeline_storage.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Re-export so screens can reference OtpPurpose without importing the data
// layer directly.
export 'package:cosmic_mirror/features/auth/data/auth_api.dart' show OtpPurpose;

/// The API client. Its callbacks ask the AuthController to flip to
/// signed-out when the session dies (refresh rejected) or the account is
/// banned — the router redirect picks it up on the next frame.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    // Both may fire once per failing request; ending an already-ended
    // session is a no-op.
    onSessionExpired: () =>
        ref.read(authControllerProvider.notifier).sessionExpired(),
    onAccountSuspended: () =>
        ref.read(authControllerProvider.notifier).accountSuspended(),
  );
});

/// Why the app signed the user out on its own, shown on the sign-in
/// screen. Cleared on the next successful sign-in.
enum SignOutReason { accountSuspended }

final signOutReasonProvider = StateProvider<SignOutReason?>((ref) => null);

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
      // A brand-new account has no chart yet: nothing more to fetch.
      return _startSession(result);
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
      return _startSession(result);
    });
    _rethrowOnError();
    _loadFullProfile();
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
      return _startSession(result);
    });
    _rethrowOnError();
    _loadFullProfile();
  }

  /// Persists the new session and seeds the profile from the sign-in
  /// response.
  Future<AppUser> _startSession(AuthResult result) async {
    await authStorage.write(result.tokens);
    ref.read(signOutReasonProvider.notifier).state = null;
    _hydrateUserProvider(result.user);
    return result.user;
  }

  /// Fills in the rest of the profile (sun / moon / rising) after a
  /// sign-in, without holding up navigation. A failure is harmless: the
  /// sign-in response already has what the router needs.
  void _loadFullProfile() {
    if (state.valueOrNull == null) return;
    // user_provider's unawaited() swallows the error.
    unawaited(ref.read(currentUserProvider.notifier).bootstrapSession());
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

  /// Signs out: revokes the refresh token on the server (best-effort) and
  /// wipes the session from this device. The router then shows /auth.
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
    _endSession();
  }

  /// Deletes the account (DELETE /users/me), then wipes it from this
  /// device. The server cancels a web subscription, revokes every session
  /// and erases the data after 30 days. Throws — leaving the user signed
  /// in — when the server refuses, so the caller can show the error.
  Future<void> deleteAccount() async {
    final userId = ref.read(currentUserProvider).id;
    await ref.read(apiClientProvider).delete(ApiEndpoints.me);
    // On-device data the server doesn't have.
    if (userId != null) await LifeTimelineStorage(userId).clear();
    // Every refresh token is already revoked server-side; no /auth/logout.
    await authStorage.clear();
    _endSession();
  }

  /// Called by the API interceptor when a refresh terminally fails. The
  /// interceptor has already wiped the stored tokens.
  void sessionExpired() => _endSession();

  /// Called by the API interceptor when the server answers
  /// `account_banned`. The sign-in screen explains why.
  void accountSuspended() {
    ref.read(signOutReasonProvider.notifier).state =
        SignOutReason.accountSuspended;
    _endSession();
  }

  /// Drops everything tied to the signed-in account, so the next account
  /// on this device starts clean: the profile (which also logs RevenueCat
  /// out, see bindRevenueCatIdentity), the onboarding draft (not
  /// autoDispose — the next sign-up would otherwise resume the previous
  /// user's birth data) and the community list filters. Data screens use
  /// autoDispose providers and are dropped when the router leaves them.
  void _endSession() {
    ref
      ..invalidate(onboardingProvider)
      ..invalidate(spaceFilterProvider)
      ..invalidate(spaceSearchQueryProvider)
      ..invalidate(selectedCategoryIdProvider);
    ref.read(currentUserProvider.notifier).reset();
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
