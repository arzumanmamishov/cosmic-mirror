import '../../../../core/utils/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signInWithApple();
  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInWithEmail(String email, String password);
  Future<Result<AppUser>> signUpWithEmail(String email, String password);
  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccount();
  Stream<AppUser?> get authStateChanges;
}
