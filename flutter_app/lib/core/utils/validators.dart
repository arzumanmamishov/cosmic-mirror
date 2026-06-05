import 'package:cosmic_mirror/core/utils/date_utils.dart';

class Validators {
  Validators._();

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? birthDate(DateTime? date) {
    if (date == null) {
      return 'Please select your birth date';
    }
    // Check the future case first — otherwise a future date yields a
    // negative age and the misleading "must be at least 13" message.
    if (date.isAfter(DateTime.now())) {
      return 'Birth date cannot be in the future';
    }
    // Use the calendar-accurate age (accounts for month/day), not a bare
    // year subtraction which is off by one for anyone who hasn't had this
    // year's birthday yet.
    final age = CosmicDateUtils.calculateAge(date);
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    if (age > 120) {
      return 'Please enter a valid birth date';
    }
    return null;
  }

  static String? birthPlace(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select your birthplace';
    }
    return null;
  }

  static String? chatMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a message';
    }
    if (value.length > 500) {
      return 'Message must be less than 500 characters';
    }
    return null;
  }
}
