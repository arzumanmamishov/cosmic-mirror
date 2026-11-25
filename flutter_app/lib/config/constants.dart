class AppConstants {
  AppConstants._();

  // Free tier limits
  static const int freeChatMessagesPerDay = 3;
  static const int freeTimelinePreviewDays = 7;
  static const int freeCompatibilityPreviews = 1;

  // Cache durations
  static const Duration dailyReadingCache = Duration(hours: 24);
  static const Duration chartCache = Duration(days: 7);
  static const Duration compatibilityCache = Duration(days: 3);
  static const Duration timelineCache = Duration(days: 1);

  // Animation durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration standardAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration revealAnimation = Duration(milliseconds: 800);

  // UI
  static const double cardRadius = 16;
  static const double buttonRadius = 12;
  static const double inputRadius = 12;
  static const double bottomNavHeight = 80;
  static const double minTouchTarget = 48;

  // Pagination
  static const int defaultPageSize = 20;

  // Chat
  static const int maxChatMessageLength = 500;
  static const int chatHistoryContextLimit = 20;

  // RevenueCat
  static const String monthlyEntitlement = 'premium_monthly';
  static const String yearlyEntitlement = 'premium_yearly';
  static const String premiumEntitlement = 'premium';

  // Hive boxes
  static const String userBox = 'user_box';
  static const String cacheBox = 'cache_box';
  static const String settingsBox = 'settings_box';
}

/// Public web pages and the support mailbox. The pages are served by the
/// API server itself (go_backend/internal/handler/legal_pages.go), so they
/// live on the same domain as the production API.
class AppLinks {
  AppLinks._();

  static const String site = 'https://lively.cofinden.co';
  static const String privacy = '$site/privacy';
  static const String terms = '$site/terms';
  static const String support = '$site/support';
  static const String supportEmail = 'lively@cofinden.co';
}
