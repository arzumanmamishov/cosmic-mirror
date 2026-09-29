import 'package:cosmic_mirror/core/network/app_locale.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class CosmicDateUtils {
  CosmicDateUtils._();

  // Display formatters are built per call so month/day names follow the
  // user's current app language (see [currentLocaleCode]). The API format
  // is locale-independent and stays cached.
  static DateFormat _fmt(String pattern) =>
      DateFormat(pattern, currentLocaleCode);
  static final _apiDate = DateFormat('yyyy-MM-dd');

  /// Localized strings for context-free callers. Pass [l] explicitly from a
  /// widget when available; otherwise we resolve from the current app locale.
  static AppLocalizations _l10n(AppLocalizations? l) =>
      l ?? lookupAppLocalizations(Locale(currentLocaleCode));

  static String formatFull(DateTime date) => _fmt('d MMMM yyyy').format(date);
  static String formatShort(DateTime date) => _fmt('d MMM').format(date);
  static String formatMonthYear(DateTime date) =>
      _fmt('MMMM yyyy').format(date);
  static String formatTime(DateTime date) => _fmt('HH:mm').format(date);
  static String formatDayName(DateTime date) => _fmt('EEEE').format(date);
  static String formatApi(DateTime date) => _apiDate.format(date);

  static DateTime? parseApi(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      return _apiDate.parse(date);
    } catch (_) {
      return null;
    }
  }

  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static String timeAgo(DateTime dateTime, [AppLocalizations? l]) {
    final l10n = _l10n(l);
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return l10n.commonJustNow;
    if (diff.inMinutes < 60) return l10n.commonMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.commonHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.commonDaysAgo(diff.inDays);
    return formatShort(dateTime);
  }

  static String greeting([AppLocalizations? l]) {
    final l10n = _l10n(l);
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.commonGoodMorning;
    if (hour < 17) return l10n.commonGoodAfternoon;
    return l10n.commonGoodEvening;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
