import 'package:intl/intl.dart';

class CosmicDateUtils {
  CosmicDateUtils._();

  static final _dayMonthYear = DateFormat('d MMMM yyyy');
  static final _shortDate = DateFormat('d MMM');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _time = DateFormat('HH:mm');
  static final _dayName = DateFormat('EEEE');
  static final _apiDate = DateFormat('yyyy-MM-dd');

  static String formatFull(DateTime date) => _dayMonthYear.format(date);
  static String formatShort(DateTime date) => _shortDate.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatTime(DateTime date) => _time.format(date);
  static String formatDayName(DateTime date) => _dayName.format(date);
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

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShort(dateTime);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
