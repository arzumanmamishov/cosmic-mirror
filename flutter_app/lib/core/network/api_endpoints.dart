class ApiEndpoints {
  ApiEndpoints._();

  static const String basePath = '/api/v1';

  // Auth
  static const String session = '$basePath/auth/session';

  // User
  static const String me = '$basePath/users/me';
  static const String birthProfile = '$basePath/users/me/birth-profile';
  static const String preferences = '$basePath/users/me/preferences';

  // Chart (Western tropical)
  static const String chart = '$basePath/chart';
  static const String chartSummary = '$basePath/chart/summary';

  // Vedic / Jyotish (sidereal)
  static const String vedicChart = '$basePath/vedic/chart';
  static String vedicDivisional(int divisor) =>
      '$basePath/vedic/chart/divisional/$divisor';
  static const String vedicDasha = '$basePath/vedic/dasha';
  static const String vedicYogas = '$basePath/vedic/yogas';
  static const String vedicShadbala = '$basePath/vedic/shadbala';
  static const String vedicAshtakavarga = '$basePath/vedic/ashtakavarga';

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

  // Community / Spaces forum
  static const String spaces = '$basePath/spaces';
  static String space(String id) => '$basePath/spaces/$id';
  static String spaceJoin(String id) => '$basePath/spaces/$id/join';
  static String spaceMembers(String id) => '$basePath/spaces/$id/members';
  static String spacePosts(String id) => '$basePath/spaces/$id/posts';

  static String post(String id) => '$basePath/posts/$id';
  static String postLike(String id) => '$basePath/posts/$id/like';
  static String postComments(String id) => '$basePath/posts/$id/comments';

  static String comment(String id) => '$basePath/comments/$id';
  static String commentLike(String id) => '$basePath/comments/$id/like';

  static const String communityNotifications =
      '$basePath/community/notifications';
  static const String communityNotificationsUnreadCount =
      '$basePath/community/notifications/unread-count';
  static String communityNotificationRead(String id) =>
      '$basePath/community/notifications/$id/read';
  static const String communityNotificationsReadAll =
      '$basePath/community/notifications/read-all';

  static const String spaceCategories = '$basePath/space-categories';
  static const String popularHashtags = '$basePath/hashtags/popular';
}
