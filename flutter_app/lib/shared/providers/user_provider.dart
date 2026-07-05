// Fetches and holds the current user's profile + big-three chart summary.
// Rewritten off Firebase in the SMTP-OTP auth migration — bootstrapSession
// now calls GET /users/me instead of the old POST /auth/session that
// exchanged a Firebase UID for a local user row.
//
// The apiClientProvider lives in features/auth/presentation/providers/
// auth_provider.dart now; this file re-exports it for the many callers
// that already import from shared/providers.

import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart'
    show apiClientProvider;

final currentUserProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(apiClientProvider), ref);
});

class UserState {
  const UserState({
    this.id,
    this.name,
    this.email,
    this.sunSign,
    this.moonSign,
    this.risingSign,
    this.avatarUrl,
    this.hasCompletedOnboarding = false,
    this.isLoading = false,
    this.bootstrapError,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? sunSign;
  final String? moonSign;
  final String? risingSign;
  final String? avatarUrl;
  final bool hasCompletedOnboarding;
  final bool isLoading;

  /// If non-null, the last bootstrapSession() call failed. This is
  /// surfaced by the auth screen so users aren't silently stranded
  /// when the backend is unreachable.
  final Object? bootstrapError;

  bool get isAuthenticated => id != null;

  UserState copyWith({
    String? id,
    String? name,
    String? email,
    String? sunSign,
    String? moonSign,
    String? risingSign,
    String? avatarUrl,
    bool clearAvatar = false,
    bool? hasCompletedOnboarding,
    bool? isLoading,
    Object? bootstrapError,
    bool clearBootstrapError = false,
  }) {
    return UserState(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      sunSign: sunSign ?? this.sunSign,
      moonSign: moonSign ?? this.moonSign,
      risingSign: risingSign ?? this.risingSign,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isLoading: isLoading ?? this.isLoading,
      bootstrapError:
          clearBootstrapError ? null : (bootstrapError ?? this.bootstrapError),
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this._apiClient, this._ref) : super(const UserState());

  final ApiClient _apiClient;
  final Ref _ref;

  /// Fetches /users/me and populates the state. Only makes the network
  /// call when we have a token to authenticate with — otherwise the
  /// call would 401 and cascade into signed-out state.
  Future<void> bootstrapSession() async {
    state = state.copyWith(isLoading: true, clearBootstrapError: true);
    final tokens = await authStorage.read();
    if (tokens == null || tokens.refreshExpired) {
      // No signed-in session — leave the state cleared and don't call
      // the backend. Callers (main, welcome) should route to /auth.
      state = const UserState();
      return;
    }
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.me);
      final user = data['user'] as Map<String, dynamic>? ?? data;
      final chart = data['chart_summary'] as Map<String, dynamic>?;
      final rawAvatarUrl = user['avatar_url'] as String?;
      state = state.copyWith(
        id: user['id'] as String?,
        name: user['name'] as String?,
        email: user['email'] as String?,
        sunSign: chart?['sun_sign'] as String?,
        moonSign: chart?['moon_sign'] as String?,
        risingSign: chart?['rising_sign'] as String?,
        avatarUrl: rawAvatarUrl,
        clearAvatar: rawAvatarUrl == null,
        hasCompletedOnboarding:
            user['has_completed_onboarding'] as bool? ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, bootstrapError: e);
      rethrow;
    }
  }

  /// Called by the register/login screens right after a successful auth
  /// call — it seeds the state from the /auth/register envelope so the
  /// UI doesn't need to wait for a follow-up /users/me round-trip.
  void hydrateFromAuth({
    required String id,
    required String? name,
    required String? email,
    required String? avatarUrl,
    required bool hasCompletedOnboarding,
  }) {
    state = state.copyWith(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      clearAvatar: avatarUrl == null,
      hasCompletedOnboarding: hasCompletedOnboarding,
      isLoading: false,
      clearBootstrapError: true,
    );
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  /// Uploads [filePath] and stores the returned URL.
  Future<String?> setAvatar(String filePath) async {
    try {
      final data = await _apiClient.uploadFile<Map<String, dynamic>>(
        ApiEndpoints.avatar,
        filePath: filePath,
      );
      final url = data['avatar_url'] as String?;
      if (url == null) return null;
      final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      state = state.copyWith(avatarUrl: cacheBusted);
      return cacheBusted;
    } catch (e, stack) {
      debugPrint('[Avatar] upload failed: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  Future<void> clearAvatar() async {
    try {
      await _apiClient.delete(ApiEndpoints.avatar);
    } catch (_) {/* surface via UI if needed */}
    state = state.copyWith(clearAvatar: true);
  }

  void markOnboardingComplete({
    required String sunSign,
    required String moonSign,
    required String risingSign,
  }) {
    state = state.copyWith(
      hasCompletedOnboarding: true,
      sunSign: sunSign,
      moonSign: moonSign,
      risingSign: risingSign,
    );
  }

  /// Wipe local user state. Also asks the AuthController to sign out
  /// (revoke the refresh token) so the /auth redirect happens.
  Future<void> logout() async {
    await _ref.read(authControllerProvider.notifier).logout();
    state = const UserState();
  }

  /// Legacy — kept for the callers (main.dart auth-state listener, some
  /// screens) that still call .clear(). Delegates to logout() so the
  /// server-side session is revoked, then wipes local state.
  void clear() {
    unawaited(_ref.read(authControllerProvider.notifier).logout());
    state = const UserState();
  }
}

/// Local helper — Dart 3's `unawaited` lives in dart:async but the file
/// doesn't already import it and I don't want to touch the imports of
/// every caller.
void unawaited(Future<void> future) {
  // Silences the analyzer without pulling in dart:async.
  future.catchError((Object _) {});
}
