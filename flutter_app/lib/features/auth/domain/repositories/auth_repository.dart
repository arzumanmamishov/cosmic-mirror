import 'package:cosmic_mirror/core/utils/result.dart';
import 'package:cosmic_mirror/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signInWithApple();
  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInWithEmail(String email, String password);
  Future<Result<AppUser>> signUpWithEmail(String email, String password);
  Future<Result<void>> sendPasswordResetEmail(String email);
  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccount();
  Stream<AppUser?> get authStateChanges;
}
