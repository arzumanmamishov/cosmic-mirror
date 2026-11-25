// Localized messages for failed /auth/* calls, shared by the sign-in,
// one-time-code and forgot-password screens. Matches on the backend's
// error code (`apiErrorCode`) — the exceptions' toString() only carries
// the server's English message, so matching on it silently fell through
// to "Something went wrong" (e.g. for a wrong password).

import 'dart:convert';

import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';

/// bcrypt only uses the first 72 bytes, and the API refuses longer
/// passwords.
const maxPasswordBytes = 72;

bool isPasswordTooLong(String password) =>
    utf8.encode(password).length > maxPasswordBytes;

/// The message to show for [error]. [noAccount] is used for
/// `user_not_found` and [rateLimited] for any 429; both default to the
/// generic wording.
String authErrorMessage(
  AppLocalizations l,
  Object error, {
  String? noAccount,
  String? rateLimited,
}) {
  switch (apiErrorCode(error)) {
    case 'account_banned':
      return l.authAccountSuspended;
    case 'email_in_use':
      return l.authEmailAlreadyRegistered;
    case 'invalid_credentials':
      return l.authErrorInvalidCredential;
    case 'invalid_code':
      return l.authOtpInvalidCode;
    case 'user_not_found':
      return noAccount ?? l.authNoAccountCheckAddress;
    case 'invalid_password':
      return l.authPasswordTooLong;
    case 'weak_password':
      return l.authPasswordTooShort;
  }
  if (error is RateLimitException) {
    return rateLimited ?? l.authTooManyAttemptsShort;
  }
  if (error is NetworkException) return l.authErrorNetwork;
  return l.commonSomethingWentWrong;
}
