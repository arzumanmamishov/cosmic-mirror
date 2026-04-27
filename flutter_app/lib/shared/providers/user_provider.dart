import 'package:firebase_auth/firebase_auth.dart' as fb;
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
    this.hasCompletedOnboarding = false,
    this.isLoading = false,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? sunSign;
  final String? moonSign;
  final String? risingSign;
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

      state = state.copyWith(
        id: user['id'] as String,
        name: user['name'] as String?,
        email: user['email'] as String?,
        sunSign: chart?['sun_sign'] as String?,
        moonSign: chart?['moon_sign'] as String?,
        risingSign: chart?['rising_sign'] as String?,
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
