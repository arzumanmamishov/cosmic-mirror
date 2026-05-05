import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lively'**
  String get appName;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app talks to you'**
  String get settingsLanguageSubtitle;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authWelcome;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hi, it\'s time for you to sign in.'**
  String get authWelcomeSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hi there, let\'s get you started.'**
  String get authSignUpSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authHaveAccount;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get authContinueApple;

  /// No description provided for @authTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get authTermsPrefix;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get authTerms;

  /// No description provided for @authAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAnd;

  /// No description provided for @authPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacy;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required.'**
  String get authEmailRequired;

  /// No description provided for @authPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authPasswordsDontMatch;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingBirthDateTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get onboardingBirthDateTitle;

  /// No description provided for @onboardingBirthDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your birth date is the foundation of your cosmic profile.'**
  String get onboardingBirthDateSubtitle;

  /// No description provided for @onboardingBirthTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'What time were you born?'**
  String get onboardingBirthTimeTitle;

  /// No description provided for @onboardingBirthTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your birth time determines your Rising sign and house placements.'**
  String get onboardingBirthTimeSubtitle;

  /// No description provided for @onboardingBirthPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Where were you born?'**
  String get onboardingBirthPlaceTitle;

  /// No description provided for @onboardingBirthPlaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your birthplace helps us calculate precise planetary positions.'**
  String get onboardingBirthPlaceSubtitle;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this to personalize your daily guidance.'**
  String get onboardingNameSubtitle;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get onboardingNameHint;

  /// No description provided for @onboardingFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'What matters most to you?'**
  String get onboardingFocusTitle;

  /// No description provided for @onboardingFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select areas you want cosmic guidance on. (Optional)'**
  String get onboardingFocusSubtitle;

  /// No description provided for @onboardingDontKnowTime.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know my birth time'**
  String get onboardingDontKnowTime;

  /// No description provided for @onboardingDontKnowTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use approximate calculations. Your Rising sign may differ.'**
  String get onboardingDontKnowTimeHelp;

  /// No description provided for @onboardingNoTimeNote.
  ///
  /// In en, this message translates to:
  /// **'No worries! We can still create a meaningful chart using your date and location.'**
  String get onboardingNoTimeNote;

  /// No description provided for @focusLove.
  ///
  /// In en, this message translates to:
  /// **'Love & Relationships'**
  String get focusLove;

  /// No description provided for @focusCareer.
  ///
  /// In en, this message translates to:
  /// **'Career & Purpose'**
  String get focusCareer;

  /// No description provided for @focusGrowth.
  ///
  /// In en, this message translates to:
  /// **'Personal Growth'**
  String get focusGrowth;

  /// No description provided for @focusHealth.
  ///
  /// In en, this message translates to:
  /// **'Health & Wellness'**
  String get focusHealth;

  /// No description provided for @focusCreativity.
  ///
  /// In en, this message translates to:
  /// **'Creativity'**
  String get focusCreativity;

  /// No description provided for @focusSpirituality.
  ///
  /// In en, this message translates to:
  /// **'Spirituality'**
  String get focusSpirituality;

  /// No description provided for @placesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a city…'**
  String get placesSearchHint;

  /// No description provided for @welcomeHello.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcomeHello;

  /// No description provided for @welcomeJourneyBegins.
  ///
  /// In en, this message translates to:
  /// **'Your cosmic journey begins.'**
  String get welcomeJourneyBegins;

  /// No description provided for @welcomeStarsAligned.
  ///
  /// In en, this message translates to:
  /// **'The stars have aligned for this moment.'**
  String get welcomeStarsAligned;

  /// No description provided for @welcomeEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Cosmos'**
  String get welcomeEnter;

  /// No description provided for @welcomeAligning.
  ///
  /// In en, this message translates to:
  /// **'Aligning the stars…'**
  String get welcomeAligning;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search readings, astrologers, spaces…'**
  String get homeSearchHint;

  /// No description provided for @homeChartsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Cosmos'**
  String get homeChartsTitle;

  /// No description provided for @homeChartsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your blueprint and your story.'**
  String get homeChartsSubtitle;

  /// No description provided for @homeChartsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your charts…'**
  String get homeChartsSearchHint;

  /// No description provided for @homeFeaturedDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Featured Discussions'**
  String get homeFeaturedDiscussions;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeTodayInTheSky.
  ///
  /// In en, this message translates to:
  /// **'Today in the Sky'**
  String get homeTodayInTheSky;

  /// No description provided for @homeTodaysInsight.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Insight'**
  String get homeTodaysInsight;

  /// No description provided for @homeReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get homeReadMore;

  /// No description provided for @homeTuneIn.
  ///
  /// In en, this message translates to:
  /// **'Tune in to today\'s celestial currents.'**
  String get homeTuneIn;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get categoryDaily;

  /// No description provided for @categorySky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get categorySky;

  /// No description provided for @categoryCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get categoryCommunity;

  /// No description provided for @chartCategoryWestern.
  ///
  /// In en, this message translates to:
  /// **'Western'**
  String get chartCategoryWestern;

  /// No description provided for @chartCategoryVedic.
  ///
  /// In en, this message translates to:
  /// **'Vedic'**
  String get chartCategoryVedic;

  /// No description provided for @chartCategoryEsoteric.
  ///
  /// In en, this message translates to:
  /// **'Esoteric'**
  String get chartCategoryEsoteric;

  /// No description provided for @chartCategoryForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get chartCategoryForecast;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get navCharts;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your data.'**
  String get profileSignOutConfirm;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfile;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileBirthData.
  ///
  /// In en, this message translates to:
  /// **'Birth Data'**
  String get profileBirthData;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get profileBirthDate;

  /// No description provided for @profileBirthTime.
  ///
  /// In en, this message translates to:
  /// **'Birth time'**
  String get profileBirthTime;

  /// No description provided for @profileBirthPlace.
  ///
  /// In en, this message translates to:
  /// **'Birthplace'**
  String get profileBirthPlace;

  /// No description provided for @profileBirthTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not known'**
  String get profileBirthTimeUnknown;

  /// No description provided for @profileEditBirthData.
  ///
  /// In en, this message translates to:
  /// **'Edit Birth Data'**
  String get profileEditBirthData;

  /// No description provided for @profileSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get profileSun;

  /// No description provided for @profileMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get profileMoon;

  /// No description provided for @profileRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get profileRising;

  /// No description provided for @profileDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get profileDayStreak;

  /// No description provided for @profileJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'Journal entries'**
  String get profileJournalEntries;

  /// No description provided for @profileAIChats.
  ///
  /// In en, this message translates to:
  /// **'AI chats'**
  String get profileAIChats;

  /// No description provided for @profileSubscriptionPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium · Active'**
  String get profileSubscriptionPremium;

  /// No description provided for @profileSubscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get profileSubscriptionFree;

  /// No description provided for @profileSubscriptionPremiumDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited insights · priority booking'**
  String get profileSubscriptionPremiumDesc;

  /// No description provided for @profileSubscriptionFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for full access to your chart'**
  String get profileSubscriptionFreeDesc;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profilePrivacy;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelp;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get profileNameLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailNote.
  ///
  /// In en, this message translates to:
  /// **'Email is managed by your sign-in provider.'**
  String get profileEmailNote;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get profileNameRequired;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {error}'**
  String profileSaveError(String error);

  /// No description provided for @editBirthDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit birth data'**
  String get editBirthDataTitle;

  /// No description provided for @editBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'BIRTH DATE'**
  String get editBirthDateLabel;

  /// No description provided for @editBirthTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'BIRTH TIME'**
  String get editBirthTimeLabel;

  /// No description provided for @editBirthPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'BIRTHPLACE'**
  String get editBirthPlaceLabel;

  /// No description provided for @editSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editSaveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @stargazer.
  ///
  /// In en, this message translates to:
  /// **'Stargazer'**
  String get stargazer;

  /// No description provided for @chartsNothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that yet.'**
  String get chartsNothingMatches;

  /// No description provided for @chartBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get chartBadgeNew;

  /// No description provided for @chartBirthChart.
  ///
  /// In en, this message translates to:
  /// **'Birth Chart'**
  String get chartBirthChart;

  /// No description provided for @chartBirthChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Planets, houses, aspects.\nThe map of who you are.'**
  String get chartBirthChartSubtitle;

  /// No description provided for @chartVedic.
  ///
  /// In en, this message translates to:
  /// **'Vedic Chart'**
  String get chartVedic;

  /// No description provided for @chartVedicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sidereal kundli, nakshatras, dashas,\n16 vargas, yogas — full Jyotish.'**
  String get chartVedicSubtitle;

  /// No description provided for @chartNumerology.
  ///
  /// In en, this message translates to:
  /// **'Numerology'**
  String get chartNumerology;

  /// No description provided for @chartNumerologySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Life path, soul urge, cycles\n+ karmic patterns + compatibility.'**
  String get chartNumerologySubtitle;

  /// No description provided for @chartHumanDesign.
  ///
  /// In en, this message translates to:
  /// **'Human Design'**
  String get chartHumanDesign;

  /// No description provided for @chartHumanDesignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type, strategy, authority,\nyour body graph blueprint.'**
  String get chartHumanDesignSubtitle;

  /// No description provided for @chartCosmicTimeline.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Timeline'**
  String get chartCosmicTimeline;

  /// No description provided for @chartCosmicTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your life mapped against the sky.\nMoments + active transits.'**
  String get chartCosmicTimelineSubtitle;

  /// No description provided for @chartYearlyForecast.
  ///
  /// In en, this message translates to:
  /// **'Yearly Forecast'**
  String get chartYearlyForecast;

  /// No description provided for @chartYearlyForecastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What 2026 holds across\nlove, work, and growth.'**
  String get chartYearlyForecastSubtitle;

  /// No description provided for @chartTransitForecast.
  ///
  /// In en, this message translates to:
  /// **'Transit Forecast'**
  String get chartTransitForecast;

  /// No description provided for @chartTransitForecastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The next 30 days, 3 months,\nand year ahead.'**
  String get chartTransitForecastSubtitle;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Astrologer'**
  String get aiChatTitle;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask your astrologer...'**
  String get aiChatInputHint;

  /// No description provided for @aiChatLimitReachedHint.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached — upgrade to continue'**
  String get aiChatLimitReachedHint;

  /// No description provided for @aiChatMessagesToday.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} messages today'**
  String aiChatMessagesToday(int used, int limit);

  /// No description provided for @aiChatLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get aiChatLimitReached;

  /// No description provided for @aiChatPremiumUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Premium · Unlimited'**
  String get aiChatPremiumUnlimited;

  /// No description provided for @aiChatPaywallTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s free limit.'**
  String get aiChatPaywallTitle;

  /// No description provided for @aiChatPaywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium for unlimited chat with your astrologer.'**
  String get aiChatPaywallSubtitle;

  /// No description provided for @avatarChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get avatarChooseFromGallery;

  /// No description provided for @avatarTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get avatarTakePhoto;

  /// No description provided for @avatarRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get avatarRemovePhoto;

  /// No description provided for @avatarPickerError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the picker.'**
  String get avatarPickerError;

  /// No description provided for @avatarSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save photo. Try again.'**
  String get avatarSaveError;

  /// No description provided for @discussionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load spaces just now.'**
  String get discussionsLoadError;

  /// No description provided for @discussionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet — be the first to start one.'**
  String get discussionsEmpty;

  /// No description provided for @discussionsJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get discussionsJoined;

  /// No description provided for @discussionsMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String discussionsMembersCount(String count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
