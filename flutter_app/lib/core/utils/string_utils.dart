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
