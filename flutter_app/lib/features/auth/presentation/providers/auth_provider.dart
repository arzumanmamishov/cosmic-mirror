import 'package:cosmic_mirror/core/error/failures.dart';
import 'package:cosmic_mirror/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cosmic_mirror/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cosmic_mirror/features/auth/domain/entities/user.dart';
import 'package:cosmic_mirror/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
  );
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authActionProvider =
    StateNotifierProvider<AuthActionNotifier, AuthActionState>((ref) {
  return AuthActionNotifier(ref.read(authRepositoryProvider));
});

enum AuthMethod { apple, google, email }

class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.error,
    this.activeMethod,
  });

  final bool isLoading;
  final String? error;
  final AuthMethod? activeMethod;

  AuthActionState copyWith({
    bool? isLoading,
    String? error,
    AuthMethod? activeMethod,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeMethod: activeMethod,
    );
  }
}

class AuthActionNotifier extends StateNotifier<AuthActionState> {
  AuthActionNotifier(this._repository) : super(const AuthActionState());

  final AuthRepository _repository;

  Future<bool> signInWithApple() async {
    state = const AuthActionState(
      isLoading: true,
      activeMethod: AuthMethod.apple,
    );
    final result = await _repository.signInWithApple();
    return result.when(
      success: (_) {
        state = const AuthActionState();
        return true;
      },
      failure: (failure) {
        // We carry the Firebase error CODE in `error` (not the English
        // message). The screen looks the code up via
        // localizedFirebaseAuthError to render a properly localized
        // string. Falling back to the raw message keeps non-Firebase
        // server errors visible during dev.
        state = AuthActionState(error: failure.code ?? failure.message);
        return false;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthActionState(
      isLoading: true,
      activeMethod: AuthMethod.google,
    );
    final result = await _repository.signInWithGoogle();
    return result.when(
      success: (_) {
        state = const AuthActionState();
        return true;
      },
      failure: (failure) {
        // We carry the Firebase error CODE in `error` (not the English
        // message). The screen looks the code up via
        // localizedFirebaseAuthError to render a properly localized
        // string. Falling back to the raw message keeps non-Firebase
        // server errors visible during dev.
        state = AuthActionState(error: failure.code ?? failure.message);
        return false;
      },
    );
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AuthActionState(
      isLoading: true,
      activeMethod: AuthMethod.email,
    );
    final result = await _repository.signInWithEmail(email, password);
    return result.when(
      success: (_) {
        state = const AuthActionState();
        return true;
      },
      failure: (failure) {
        // We carry the Firebase error CODE in `error` (not the English
        // message). The screen looks the code up via
        // localizedFirebaseAuthError to render a properly localized
        // string. Falling back to the raw message keeps non-Firebase
        // server errors visible during dev.
        state = AuthActionState(error: failure.code ?? failure.message);
        return false;
      },
    );
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    state = const AuthActionState(
      isLoading: true,
      activeMethod: AuthMethod.email,
    );
    final result = await _repository.signUpWithEmail(email, password);
    return result.when(
      success: (_) {
        state = const AuthActionState();
        return true;
      },
      failure: (failure) {
        // We carry the Firebase error CODE in `error` (not the English
        // message). The screen looks the code up via
        // localizedFirebaseAuthError to render a properly localized
        // string. Falling back to the raw message keeps non-Firebase
        // server errors visible during dev.
        state = AuthActionState(error: failure.code ?? failure.message);
        return false;
      },
    );
  }

  /// Sends a password-reset email via Firebase. Returns the Firebase error
  /// code on failure (e.g. `user-not-found`, `invalid-email`,
  /// `network-request-failed`) so the screen can localize it; returns null
  /// on success. We surface this through a return value rather than the
  /// AuthActionState because the dialog displays its own banner inline.
  Future<String?> sendPasswordResetEmail(String email) async {
    final result = await _repository.sendPasswordResetEmail(email);
    return result.when(
      success: (_) => null,
      failure: (failure) =>
          failure is AuthFailure ? (failure.code ?? 'unknown') : 'unknown',
    );
  }

  void clearError() {
    state = const AuthActionState();
  }
}
