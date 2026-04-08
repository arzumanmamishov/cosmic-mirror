import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

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
        state = AuthActionState(error: failure.message);
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
        state = AuthActionState(error: failure.message);
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
        state = AuthActionState(error: failure.message);
        return false;
      },
    );
  }

  void clearError() {
    state = const AuthActionState();
  }
}
