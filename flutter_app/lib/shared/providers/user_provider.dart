import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final currentUserProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(apiClientProvider));
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
  });

  final String? id;
  final String? name;
  final String? email;
  final String? sunSign;
  final String? moonSign;
  final String? risingSign;

  /// Public URL of the user's avatar served by the backend
  /// (e.g. `/uploads/avatars/{id}_{ts}.jpg`). `null` means use the
  /// initial-letter fallback in the UI. The backend is the source of
  /// truth — uploads are POSTed to /users/me/avatar.
  final String? avatarUrl;

  final bool hasCompletedOnboarding;
  final bool isLoading;

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
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this._apiClient) : super(const UserState());

  final ApiClient _apiClient;

  Future<void> bootstrapSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;
      final data = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.session,
        data: {
          'firebase_uid': firebaseUser?.uid ?? '',
          'email': firebaseUser?.email ?? '',
          'name': firebaseUser?.displayName ?? '',
        },
      );
      final user = data['user'] as Map<String, dynamic>;
      final chart = data['chart_summary'] as Map<String, dynamic>?;
      final rawAvatarUrl = user['avatar_url'] as String?;

      state = state.copyWith(
        id: user['id'] as String,
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
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  /// Uploads [filePath] to the backend and stores the returned URL.
  /// Returns the new URL or `null` on failure. Errors are logged so
  /// the dev console shows the actual cause (multipart parse error,
  /// 401, 413 too-large, etc) instead of being silently swallowed.
  Future<String?> setAvatar(String filePath) async {
    try {
      final data = await _apiClient.uploadFile<Map<String, dynamic>>(
        ApiEndpoints.avatar,
        filePath: filePath,
      );
      final url = data['avatar_url'] as String?;
      if (url == null) return null;
      // Bust any previously-cached image at the same URL by appending a
      // tiny query string. The backend already changes the filename per
      // upload, so this is just belt-and-braces.
      final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      state = state.copyWith(avatarUrl: cacheBusted);
      return cacheBusted;
    } catch (e, stack) {
      // Log instead of silently dropping — the previous catch made
      // every avatar failure look identical in the UI even when the
      // backend was returning a real, fixable error.
      debugPrint('[Avatar] upload failed: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  /// Deletes the user's avatar on the backend and clears local state.
  Future<void> clearAvatar() async {
    try {
      await _apiClient.delete(ApiEndpoints.avatar);
    } catch (_) {/* surface to the user via UI if needed */}
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

  void clear() {
    state = const UserState();
  }
}
