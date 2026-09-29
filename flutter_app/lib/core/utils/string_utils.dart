/// Small, null/length-safe string helpers used by chart widgets that
/// render labels from backend data which may arrive empty or shorter
/// than expected. The naive `str.substring(0, 2)` / `str[0]` patterns
/// throw a RangeError on empty or single-character input.
extension SafeStringLabels on String {
  /// First [n] characters, or the whole string if it's shorter. Returns
  /// [fallback] when the string is empty. Used for planet/graha glyphs.
  String abbrev([int n = 2, String fallback = '?']) {
    if (isEmpty) return fallback;
    return length >= n ? substring(0, n) : this;
  }

  /// Uppercases the first character, leaving the rest untouched. Safe on
  /// empty strings (returns '').
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// Locale-aware case mapping. Dart's [String.toUpperCase] ignores locale,
/// so Turkish dotted/dotless i come out wrong ("şifre" → "ŞIFRE" instead
/// of "ŞİFRE"). Use these for any *display* text that gets re-cased.
extension LocaleAwareCase on String {
  /// Uppercases using the rules of [languageCode] (e.g. 'tr').
  String toUpperCaseLocale(String languageCode) {
    if (languageCode.toLowerCase().startsWith('tr') ||
        languageCode.toLowerCase().startsWith('az')) {
      return replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
    }
    return toUpperCase();
  }

  /// Lowercases using the rules of [languageCode] (e.g. 'tr').
  String toLowerCaseLocale(String languageCode) {
    if (languageCode.toLowerCase().startsWith('tr') ||
        languageCode.toLowerCase().startsWith('az')) {
      return replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
    }
    return toLowerCase();
  }
}
