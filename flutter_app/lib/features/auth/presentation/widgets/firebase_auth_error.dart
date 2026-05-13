import 'package:cosmic_mirror/l10n/app_localizations.dart';

/// Maps a Firebase Auth error code to a localized, user-facing string.
///
/// Lives in the UI layer (not in the datasource) because it needs a
/// BuildContext to look up AppLocalizations — the datasource has no
/// concept of locale and used to return hardcoded English, which leaked
/// untranslated text into Turkish builds.
///
/// Codes covered here are the ones the Firebase Auth SDK actually emits
/// in production for our flows. Notably we handle both `wrong-password`
/// (legacy, returned when email-enumeration protection is OFF) and
/// `invalid-credential` (the new code Firebase returns when protection
/// is ON — the two were previously both unmapped, falling through to a
/// generic "Authentication failed" that left users guessing).
String localizedFirebaseAuthError(AppLocalizations l10n, String? code) {
  switch (code) {
    case 'user-not-found':
      return l10n.authErrorUserNotFound;
    case 'wrong-password':
      return l10n.authErrorWrongPassword;
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return l10n.authErrorInvalidCredential;
    case 'email-already-in-use':
      return l10n.authErrorEmailInUse;
    case 'invalid-email':
      return l10n.authErrorInvalidEmail;
    case 'weak-password':
      return l10n.authErrorWeakPassword;
    case 'too-many-requests':
      return l10n.authErrorTooManyRequests;
    case 'network-request-failed':
      return l10n.authErrorNetwork;
    case 'user-disabled':
      return l10n.authErrorUserDisabled;
    case 'operation-not-allowed':
      return l10n.authErrorOperationNotAllowed;
    default:
      return l10n.authErrorGeneric;
  }
}
