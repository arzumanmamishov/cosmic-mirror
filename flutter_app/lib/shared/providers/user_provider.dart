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

  /// Bumped on every [reset] and [hydrateFromAuth], so a /users/me
  /// response that arrives after the session changed (signed out, or
  /// another account signed in) is dropped instead of bringing the old
  /// user back.
  int _session = 0;

  /// Fetches /users/me and populates the state. Only makes the network
  /// call when we have a token to authenticate with — otherwise the
  /// call would 401 and cascade into signed-out state.
  Future<void> bootstrapSession() async {
    final session = _session;
    state = state.copyWith(isLoading: true, clearBootstrapError: true);
    final tokens = await authStorage.read();
    if (session != _session) return;
    if (tokens == null || tokens.refreshExpired) {
      // No signed-in session — leave the state cleared and don't call
      // the backend. Callers (main, welcome) should route to /auth.
      state = const UserState();
      return;
    }
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.me);
      if (session != _session) return;
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
      if (session != _session) return;
      state = state.copyWith(isLoading: false, bootstrapError: e);
      rethrow;
    }
  }

  /// Called by the AuthController right after a successful sign-in /
  /// registration — it seeds the state from the auth response so the UI
  /// doesn't need to wait for a follow-up /users/me round-trip.
  ///
  /// Builds a fresh state rather than merging into the old one: merging
  /// kept the previous account's sun / moon / rising (and name, when the
  /// new one is blank) when a second account signed in on this device.
  void hydrateFromAuth({
    required String id,
    required String? name,
    required String? email,
    required String? avatarUrl,
    required bool hasCompletedOnboarding,
  }) {
    _session++;
    state = UserState(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  /// Forgets the signed-in user (sign-out, account deletion, expired or
  /// suspended session). Called by the AuthController.
  void reset() {
    _session++;
    state = const UserState();
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

  /// Deletes the avatar on the server. Returns true on success; on failure
  /// the local avatar is left untouched (it still exists server-side, so
  /// clearing it here would just reappear on the next /users/me) and false
  /// is returned so the caller can show an error.
  Future<bool> clearAvatar() async {
    try {
      await _apiClient.delete(ApiEndpoints.avatar);
    } catch (e) {
      debugPrint('[Avatar] delete failed: $e');
      return false;
    }
    state = state.copyWith(clearAvatar: true);
    return true;
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

  /// Signs out. The AuthController revokes the refresh token, wipes the
  /// stored session and resets this state.
  Future<void> logout() =>
      _ref.read(authControllerProvider.notifier).logout();
}

/// Local helper — Dart 3's `unawaited` lives in dart:async but the file
/// doesn't already import it and I don't want to touch the imports of
/// every caller.
void unawaited(Future<void> future) {
  // Silences the analyzer without pulling in dart:async.
  future.catchError((Object _) {});
}
