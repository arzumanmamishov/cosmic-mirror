import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<AppUser>> signInWithApple() async {
    try {
      final credential = await _remote.signInWithApple();
      final user = credential.user!;
      return Success(
        UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName,
        ),
      );
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      final credential = await _remote.signInWithGoogle();
      final user = credential.user!;
      return Success(
        UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName,
        ),
      );
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signInWithEmail(String email, String password) async {
    try {
      final credential = await _remote.signInWithEmail(email, password);
      final user = credential.user!;
      return Success(
        UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName,
        ),
      );
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _remote.signUpWithEmail(email, password);
      final user = credential.user!;
      return Success(
        UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName,
        ),
      );
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remote.signOut();
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _remote.deleteAccount();
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _remote.authStateChanges.map((user) {
      if (user == null) return null;
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName,
      );
    });
  }
}
