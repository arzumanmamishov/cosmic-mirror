import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/error/exceptions.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email'],
              signInOption: SignInOption.standard,
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      if (appleCredential.givenName != null) {
        await userCredential.user?.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
              .trim(),
        );
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthException(message: e.message, code: 'apple_auth_error');
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Apple sign-in failed.',
        code: e.code,
      );
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(
          message: 'Sign-in cancelled.',
          code: 'cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Google sign-in failed.',
        code: e.code,
      );
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // The code is the user-facing identifier here — the UI looks it up
      // against AppLocalizations so errors stay localized. We still pass
      // Firebase's English message through as a fallback in case the UI
      // hits an unmapped code (new Firebase rev, exotic config issue).
      throw AuthException(
        message: e.message ?? e.code,
        code: e.code,
      );
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? e.code,
        code: e.code,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? e.code,
        code: e.code,
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> deleteAccount() async {
    await _firebaseAuth.currentUser?.delete();
  }
}
