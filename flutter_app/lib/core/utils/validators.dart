import 'package:cosmic_mirror/core/utils/date_utils.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';

/// Form validators. Each takes the active [AppLocalizations] so error text
/// is shown in the user's language, e.g.
/// `validator: (v) => Validators.email(v, AppLocalizations.of(context))`.
class Validators {
  Validators._();

  static String? name(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.validationNameRequired;
    }
    if (value.trim().length < 2) {
      return l.validationNameTooShort;
    }
    if (value.trim().length > 50) {
      return l.validationNameTooLong;
    }
    return null;
  }

  static String? email(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.validationEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l.validationEmailInvalid;
    }
    return null;
  }

  static String? password(String? value, AppLocalizations l) {
    if (value == null || value.isEmpty) {
      return l.validationPasswordRequired;
    }
    if (value.length < 8) {
      return l.authPasswordTooShort;
    }
    return null;
  }

  static String? birthDate(DateTime? date, AppLocalizations l) {
    if (date == null) {
      return l.validationBirthDateRequired;
    }
    // Check the future case first — otherwise a future date yields a
    // negative age and the misleading "must be at least 13" message.
    if (date.isAfter(DateTime.now())) {
      return l.validationBirthDateFuture;
    }
    // Use the calendar-accurate age (accounts for month/day), not a bare
    // year subtraction which is off by one for anyone who hasn't had this
    // year's birthday yet.
    final age = CosmicDateUtils.calculateAge(date);
    if (age < 13) {
      return l.validationMinAge;
    }
    if (age > 120) {
      return l.validationBirthDateInvalid;
    }
    return null;
  }

  static String? birthPlace(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.validationBirthPlaceRequired;
    }
    return null;
  }

  static String? chatMessage(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.validationMessageRequired;
    }
    if (value.length > 500) {
      return l.validationMessageTooLong;
    }
    return null;
  }
}
