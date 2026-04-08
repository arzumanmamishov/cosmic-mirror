class ApiEndpoints {
  ApiEndpoints._();

  static const String basePath = '/api/v1';

  // Auth
  static const String session = '$basePath/auth/session';

  // User
  static const String me = '$basePath/users/me';
  static const String birthProfile = '$basePath/users/me/birth-profile';
  static const String preferences = '$basePath/users/me/preferences';

  // Chart
  static const String chart = '$basePath/chart';
  static const String chartSummary = '$basePath/chart/summary';

  // Daily Reading
  static const String dailyReading = '$basePath/daily-reading';
  static String dailyReadingByDate(String date) =>
      '$basePath/daily-reading/$date';

  // AI Chat
  static const String chatThreads = '$basePath/ai/threads';
  static String chatThread(String id) => '$basePath/ai/threads/$id';
  static String chatMessages(String threadId) =>
      '$basePath/ai/threads/$threadId/messages';

  // People & Compatibility
  static const String people = '$basePath/people';
  static String person(String id) => '$basePath/people/$id';
  static String compatibility(String personId) =>
      '$basePath/people/$personId/compatibility';

  // Timeline & Forecast
  static const String timeline = '$basePath/timeline';
  static const String yearlyForecast = '$basePath/forecast/yearly';

  // Rituals
  static const String ritualsToday = '$basePath/rituals/today';
  static String ritualComplete(String type) =>
      '$basePath/rituals/$type/complete';

  // Journal
  static const String journal = '$basePath/journal';
  static String journalEntry(String id) => '$basePath/journal/$id';

  // Notifications
  static const String notificationPreferences =
      '$basePath/notifications/preferences';

  // Subscription
  static const String subscriptionStatus = '$basePath/subscription/status';

  // Legal
  static const String privacyPolicy = '$basePath/legal/privacy';
  static const String termsOfService = '$basePath/legal/terms';
}
