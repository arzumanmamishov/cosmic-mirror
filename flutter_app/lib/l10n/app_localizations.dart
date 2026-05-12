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

  /// No description provided for @aiChatStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Powered by your chart'**
  String get aiChatStatusOnline;

  /// No description provided for @aiChatEmptyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your personal astrologer'**
  String get aiChatEmptyHeadline;

  /// No description provided for @aiChatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your chart, transits, dreams, or the day ahead.'**
  String get aiChatEmptySubtitle;

  /// No description provided for @aiChatSuggestedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Try asking…'**
  String get aiChatSuggestedQuestions;

  /// No description provided for @aiChatPrompt1.
  ///
  /// In en, this message translates to:
  /// **'What should I focus on today?'**
  String get aiChatPrompt1;

  /// No description provided for @aiChatPrompt2.
  ///
  /// In en, this message translates to:
  /// **'Tell me about my Venus placement.'**
  String get aiChatPrompt2;

  /// No description provided for @aiChatPrompt3.
  ///
  /// In en, this message translates to:
  /// **'How will this week unfold for me?'**
  String get aiChatPrompt3;

  /// No description provided for @aiChatPrompt4.
  ///
  /// In en, this message translates to:
  /// **'What are my biggest strengths?'**
  String get aiChatPrompt4;

  /// No description provided for @aiChatPrompt5.
  ///
  /// In en, this message translates to:
  /// **'How can I improve my relationships?'**
  String get aiChatPrompt5;

  /// No description provided for @aiChatPrompt6.
  ///
  /// In en, this message translates to:
  /// **'What career paths suit my chart?'**
  String get aiChatPrompt6;

  /// No description provided for @aiChatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get aiChatYou;

  /// No description provided for @aiChatAstrologer.
  ///
  /// In en, this message translates to:
  /// **'Astrologer'**
  String get aiChatAstrologer;

  /// No description provided for @aiChatThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiChatThinking;

  /// No description provided for @aiChatRename.
  ///
  /// In en, this message translates to:
  /// **'Rename conversation'**
  String get aiChatRename;

  /// No description provided for @aiChatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get aiChatDelete;

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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegal;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Active'**
  String get settingsPremiumActive;

  /// No description provided for @settingsFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get settingsFreePlan;

  /// No description provided for @settingsManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscription'**
  String get settingsManageSubscription;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for full access'**
  String get settingsUpgrade;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get settingsRateApp;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirm;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all data. This action cannot be undone.'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDelete;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Lively v1.0.0'**
  String get settingsAppVersion;

  /// No description provided for @chatThreadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Astrologer'**
  String get chatThreadsTitle;

  /// No description provided for @chatThreadsStart.
  ///
  /// In en, this message translates to:
  /// **'Start a Conversation'**
  String get chatThreadsStart;

  /// No description provided for @chatThreadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation\nwith your astrologer.'**
  String get chatThreadsEmpty;

  /// No description provided for @chatThreadsNew.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatThreadsNew;

  /// No description provided for @chatThreadsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatThreadsDelete;

  /// No description provided for @chatThreadsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation?'**
  String get chatThreadsDeleteConfirm;

  /// No description provided for @chatThreadsUntitled.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get chatThreadsUntitled;

  /// No description provided for @paywallHeadline.
  ///
  /// In en, this message translates to:
  /// **'Unlock Your Full\nCosmic Potential'**
  String get paywallHeadline;

  /// No description provided for @paywallSubheadline.
  ///
  /// In en, this message translates to:
  /// **'Premium gives you unlimited access to every feature.'**
  String get paywallSubheadline;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallYearly;

  /// No description provided for @paywallSavePercent.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}'**
  String paywallSavePercent(String percent);

  /// No description provided for @paywallStartFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get paywallStartFreeTrial;

  /// No description provided for @paywallSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get paywallSubscribe;

  /// No description provided for @paywallRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestorePurchases;

  /// No description provided for @paywallTermsNote.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. Auto-renews unless cancelled.'**
  String get paywallTermsNote;

  /// No description provided for @paywallFeatureUnlimitedChat.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI astrologer chat'**
  String get paywallFeatureUnlimitedChat;

  /// No description provided for @paywallFeatureFullChart.
  ///
  /// In en, this message translates to:
  /// **'Full natal chart with houses + aspects'**
  String get paywallFeatureFullChart;

  /// No description provided for @paywallFeatureDailyReading.
  ///
  /// In en, this message translates to:
  /// **'Personalized daily readings'**
  String get paywallFeatureDailyReading;

  /// No description provided for @paywallFeatureCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Unlimited compatibility reports'**
  String get paywallFeatureCompatibility;

  /// No description provided for @paywallFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'Ad-free experience'**
  String get paywallFeatureNoAds;

  /// No description provided for @paywallFeatureExport.
  ///
  /// In en, this message translates to:
  /// **'Export your charts'**
  String get paywallFeatureExport;

  /// No description provided for @paywallBenefit1Title.
  ///
  /// In en, this message translates to:
  /// **'Full Daily Guidance'**
  String get paywallBenefit1Title;

  /// No description provided for @paywallBenefit1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed love, career, and health insights'**
  String get paywallBenefit1Subtitle;

  /// No description provided for @paywallBenefit2Title.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Chat'**
  String get paywallBenefit2Title;

  /// No description provided for @paywallBenefit2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your personal astrologer anything'**
  String get paywallBenefit2Subtitle;

  /// No description provided for @paywallBenefit3Title.
  ///
  /// In en, this message translates to:
  /// **'Full Compatibility'**
  String get paywallBenefit3Title;

  /// No description provided for @paywallBenefit3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Deep reports for all your relationships'**
  String get paywallBenefit3Subtitle;

  /// No description provided for @paywallBenefit4Title.
  ///
  /// In en, this message translates to:
  /// **'Life Timeline'**
  String get paywallBenefit4Title;

  /// No description provided for @paywallBenefit4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'30-day, 3-month, and 12-month forecasts'**
  String get paywallBenefit4Subtitle;

  /// No description provided for @paywallBenefit5Title.
  ///
  /// In en, this message translates to:
  /// **'Yearly Forecast'**
  String get paywallBenefit5Title;

  /// No description provided for @paywallBenefit5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your cosmic roadmap for the year ahead'**
  String get paywallBenefit5Subtitle;

  /// No description provided for @paywallBenefit6Title.
  ///
  /// In en, this message translates to:
  /// **'Rituals & Journal'**
  String get paywallBenefit6Title;

  /// No description provided for @paywallBenefit6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily practices for growth and reflection'**
  String get paywallBenefit6Subtitle;

  /// No description provided for @paywallSaveBadge.
  ///
  /// In en, this message translates to:
  /// **'SAVE 52%'**
  String get paywallSaveBadge;

  /// No description provided for @paywallTrialIncluded.
  ///
  /// In en, this message translates to:
  /// **'3-day free trial included'**
  String get paywallTrialIncluded;

  /// No description provided for @paywallRestoreLong.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywallRestoreLong;

  /// No description provided for @paywallCancelNote.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. Subscription renews automatically.'**
  String get paywallCancelNote;

  /// No description provided for @dailyReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reading'**
  String get dailyReadingTitle;

  /// No description provided for @dailyReadingEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get dailyReadingEnergy;

  /// No description provided for @dailyReadingEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get dailyReadingEmotional;

  /// No description provided for @dailyReadingLove.
  ///
  /// In en, this message translates to:
  /// **'Love & Connection'**
  String get dailyReadingLove;

  /// No description provided for @dailyReadingCareer.
  ///
  /// In en, this message translates to:
  /// **'Career & Purpose'**
  String get dailyReadingCareer;

  /// No description provided for @dailyReadingHealth.
  ///
  /// In en, this message translates to:
  /// **'Health & Wellness'**
  String get dailyReadingHealth;

  /// No description provided for @dailyReadingCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get dailyReadingCaution;

  /// No description provided for @dailyReadingAction.
  ///
  /// In en, this message translates to:
  /// **'Action Steps'**
  String get dailyReadingAction;

  /// No description provided for @dailyReadingAffirmation.
  ///
  /// In en, this message translates to:
  /// **'Affirmation'**
  String get dailyReadingAffirmation;

  /// No description provided for @dailyReadingLuckyColor.
  ///
  /// In en, this message translates to:
  /// **'Lucky Color'**
  String get dailyReadingLuckyColor;

  /// No description provided for @dailyReadingLuckyNumber.
  ///
  /// In en, this message translates to:
  /// **'Lucky Number'**
  String get dailyReadingLuckyNumber;

  /// No description provided for @dailyReadingSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get dailyReadingSun;

  /// No description provided for @dailyReadingMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get dailyReadingMoon;

  /// No description provided for @dailyReadingRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get dailyReadingRising;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// No description provided for @journalNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get journalNewEntry;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.\nWrite your first reflection.'**
  String get journalEmpty;

  /// No description provided for @journalPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Today I noticed...'**
  String get journalPromptHint;

  /// No description provided for @journalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get journalSaved;

  /// No description provided for @journalSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get journalSave;

  /// No description provided for @journalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get journalDelete;

  /// No description provided for @journalDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get journalDeleteConfirm;

  /// No description provided for @journalEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}} · capture what the sky meant to you'**
  String journalEntriesCount(int count);

  /// No description provided for @journalCosmicTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Cosmic Journal'**
  String get journalCosmicTitle;

  /// No description provided for @journalEmptyBlurb.
  ///
  /// In en, this message translates to:
  /// **'A private space to write what you noticed,\nfelt, or wondered about today.'**
  String get journalEmptyBlurb;

  /// No description provided for @journalNewMoment.
  ///
  /// In en, this message translates to:
  /// **'A new moment'**
  String get journalNewMoment;

  /// No description provided for @journalEditMoment.
  ///
  /// In en, this message translates to:
  /// **'Edit your moment'**
  String get journalEditMoment;

  /// No description provided for @journalMoodHeader.
  ///
  /// In en, this message translates to:
  /// **'HOW DOES TODAY FEEL?'**
  String get journalMoodHeader;

  /// No description provided for @journalPromptHeader.
  ///
  /// In en, this message translates to:
  /// **'OR START FROM A PROMPT'**
  String get journalPromptHeader;

  /// No description provided for @journalMoodSuffix.
  ///
  /// In en, this message translates to:
  /// **'mood'**
  String get journalMoodSuffix;

  /// No description provided for @journalMoodGlad.
  ///
  /// In en, this message translates to:
  /// **'Glad'**
  String get journalMoodGlad;

  /// No description provided for @journalMoodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get journalMoodCalm;

  /// No description provided for @journalMoodLoved.
  ///
  /// In en, this message translates to:
  /// **'Loved'**
  String get journalMoodLoved;

  /// No description provided for @journalMoodSparkly.
  ///
  /// In en, this message translates to:
  /// **'Sparkly'**
  String get journalMoodSparkly;

  /// No description provided for @journalMoodCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get journalMoodCurious;

  /// No description provided for @journalMoodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get journalMoodTired;

  /// No description provided for @journalMoodHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get journalMoodHeavy;

  /// No description provided for @journalMoodRestless.
  ///
  /// In en, this message translates to:
  /// **'Restless'**
  String get journalMoodRestless;

  /// No description provided for @journalPrompt1.
  ///
  /// In en, this message translates to:
  /// **'What surprised you today?'**
  String get journalPrompt1;

  /// No description provided for @journalPrompt2.
  ///
  /// In en, this message translates to:
  /// **'Where did you feel most yourself?'**
  String get journalPrompt2;

  /// No description provided for @journalPrompt3.
  ///
  /// In en, this message translates to:
  /// **'What are you releasing?'**
  String get journalPrompt3;

  /// No description provided for @journalPrompt4.
  ///
  /// In en, this message translates to:
  /// **'What did the sky feel like today?'**
  String get journalPrompt4;

  /// No description provided for @journalEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Write what you noticed, felt, or wondered about today...'**
  String get journalEditorHint;

  /// No description provided for @journalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String journalSaveFailed(String error);

  /// No description provided for @todaySkyEnergyHighTitle.
  ///
  /// In en, this message translates to:
  /// **'Energy: high'**
  String get todaySkyEnergyHighTitle;

  /// No description provided for @todaySkyEnergyHighBody.
  ///
  /// In en, this message translates to:
  /// **'A good day to start something — momentum favors action.'**
  String get todaySkyEnergyHighBody;

  /// No description provided for @todaySkyHeartTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart-forward'**
  String get todaySkyHeartTitle;

  /// No description provided for @todaySkyHeartBody.
  ///
  /// In en, this message translates to:
  /// **'Venus angles invite warmth in conversation. Reach out.'**
  String get todaySkyHeartBody;

  /// No description provided for @todaySkyMindTitle.
  ///
  /// In en, this message translates to:
  /// **'Mind sharp'**
  String get todaySkyMindTitle;

  /// No description provided for @todaySkyMindBody.
  ///
  /// In en, this message translates to:
  /// **'Mercury favors clear thinking. Tackle the hard email.'**
  String get todaySkyMindBody;

  /// No description provided for @todaySkyPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause before reacting'**
  String get todaySkyPauseTitle;

  /// No description provided for @todaySkyPauseBody.
  ///
  /// In en, this message translates to:
  /// **'Tense aspect — sleep on big decisions today.'**
  String get todaySkyPauseBody;

  /// No description provided for @todaySkyRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Restorative window'**
  String get todaySkyRestTitle;

  /// No description provided for @todaySkyRestBody.
  ///
  /// In en, this message translates to:
  /// **'Soft transits — make time for stillness this evening.'**
  String get todaySkyRestBody;

  /// No description provided for @todaySkyCreativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Creative spark'**
  String get todaySkyCreativeTitle;

  /// No description provided for @todaySkyCreativeBody.
  ///
  /// In en, this message translates to:
  /// **'Imagination runs high — capture the idea before it fades.'**
  String get todaySkyCreativeBody;

  /// No description provided for @todaySkyRecognitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recognition possible'**
  String get todaySkyRecognitionTitle;

  /// No description provided for @todaySkyRecognitionBody.
  ///
  /// In en, this message translates to:
  /// **'Sun-Jupiter trine boosts visibility. Stand in your work.'**
  String get todaySkyRecognitionBody;

  /// No description provided for @todaySkyNewGroundTitle.
  ///
  /// In en, this message translates to:
  /// **'New ground'**
  String get todaySkyNewGroundTitle;

  /// No description provided for @todaySkyNewGroundBody.
  ///
  /// In en, this message translates to:
  /// **'A perspective shift is available. Try a different route home.'**
  String get todaySkyNewGroundBody;

  /// No description provided for @todaySkyBridgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Bridges, not walls'**
  String get todaySkyBridgesTitle;

  /// No description provided for @todaySkyBridgesBody.
  ///
  /// In en, this message translates to:
  /// **'Diplomatic energy — a hard talk could go better than expected.'**
  String get todaySkyBridgesBody;

  /// No description provided for @todaySkyIlluminated.
  ///
  /// In en, this message translates to:
  /// **'{percent}% illuminated'**
  String todaySkyIlluminated(String percent);

  /// No description provided for @todaySkySunIn.
  ///
  /// In en, this message translates to:
  /// **'Sun in {sign}'**
  String todaySkySunIn(String sign);

  /// No description provided for @compatibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatibilityTitle;

  /// No description provided for @compatibilityAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add Person'**
  String get compatibilityAddPerson;

  /// No description provided for @compatibilityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add someone to see how you click.'**
  String get compatibilityEmpty;

  /// No description provided for @compatibilityViewReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get compatibilityViewReport;

  /// No description provided for @compatibilityName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get compatibilityName;

  /// No description provided for @compatibilityRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get compatibilityRelationship;

  /// No description provided for @compatibilityBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get compatibilityBirthDate;

  /// No description provided for @compatibilityBirthTime.
  ///
  /// In en, this message translates to:
  /// **'Birth time'**
  String get compatibilityBirthTime;

  /// No description provided for @compatibilityBirthPlace.
  ///
  /// In en, this message translates to:
  /// **'Birth place'**
  String get compatibilityBirthPlace;

  /// No description provided for @compatibilitySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get compatibilitySave;

  /// No description provided for @compatibilitySavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved · explore your synastry'**
  String compatibilitySavedCount(int count);

  /// No description provided for @compatibilitySeeHow.
  ///
  /// In en, this message translates to:
  /// **'See How You Connect'**
  String get compatibilitySeeHow;

  /// No description provided for @compatibilityEmptyBlurb.
  ///
  /// In en, this message translates to:
  /// **'Add a partner, friend, or family member\nand compare your charts.'**
  String get compatibilityEmptyBlurb;

  /// No description provided for @addPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Someone'**
  String get addPersonTitle;

  /// No description provided for @addPersonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll compare their chart with yours.'**
  String get addPersonSubtitle;

  /// No description provided for @addPersonNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get addPersonNameLabel;

  /// No description provided for @addPersonNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Theo Marlow'**
  String get addPersonNameHint;

  /// No description provided for @addPersonRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get addPersonRelationship;

  /// No description provided for @addPersonBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get addPersonBirthDate;

  /// No description provided for @addPersonBirthTime.
  ///
  /// In en, this message translates to:
  /// **'Birth time'**
  String get addPersonBirthTime;

  /// No description provided for @addPersonBirthplace.
  ///
  /// In en, this message translates to:
  /// **'Birthplace'**
  String get addPersonBirthplace;

  /// No description provided for @addPersonGenerate.
  ///
  /// In en, this message translates to:
  /// **'Add & Generate Report'**
  String get addPersonGenerate;

  /// No description provided for @addPersonOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get addPersonOptional;

  /// No description provided for @addPersonSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get addPersonSelectDate;

  /// No description provided for @addPersonSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Select a time'**
  String get addPersonSelectTime;

  /// No description provided for @addPersonTimeKnown.
  ///
  /// In en, this message translates to:
  /// **'Known'**
  String get addPersonTimeKnown;

  /// No description provided for @addPersonTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get addPersonTimeUnknown;

  /// No description provided for @compatReportSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get compatReportSummary;

  /// No description provided for @compatReportConflictPatterns.
  ///
  /// In en, this message translates to:
  /// **'Conflict Patterns'**
  String get compatReportConflictPatterns;

  /// No description provided for @compatReportAdvice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get compatReportAdvice;

  /// No description provided for @compatScoreMagnetic.
  ///
  /// In en, this message translates to:
  /// **'A magnetic alignment'**
  String get compatScoreMagnetic;

  /// No description provided for @compatScoreEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy, generative energy'**
  String get compatScoreEasy;

  /// No description provided for @compatScoreWorthWork.
  ///
  /// In en, this message translates to:
  /// **'Worth the work'**
  String get compatScoreWorthWork;

  /// No description provided for @compatScoreFriction.
  ///
  /// In en, this message translates to:
  /// **'Friction with potential'**
  String get compatScoreFriction;

  /// No description provided for @compatScoreOpposites.
  ///
  /// In en, this message translates to:
  /// **'A study in opposites'**
  String get compatScoreOpposites;

  /// No description provided for @compatDimEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get compatDimEmotional;

  /// No description provided for @compatDimCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get compatDimCommunication;

  /// No description provided for @compatDimChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get compatDimChemistry;

  /// No description provided for @chartScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Natal Chart'**
  String get chartScreenTitle;

  /// No description provided for @chartTabPlanets.
  ///
  /// In en, this message translates to:
  /// **'Planets'**
  String get chartTabPlanets;

  /// No description provided for @chartTabHouses.
  ///
  /// In en, this message translates to:
  /// **'Houses'**
  String get chartTabHouses;

  /// No description provided for @chartTabAspects.
  ///
  /// In en, this message translates to:
  /// **'Aspects'**
  String get chartTabAspects;

  /// No description provided for @chartTabElements.
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get chartTabElements;

  /// No description provided for @chartTabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get chartTabSummary;

  /// No description provided for @chartViewVedic.
  ///
  /// In en, this message translates to:
  /// **'View Vedic Chart'**
  String get chartViewVedic;

  /// No description provided for @chartLegendConjunction.
  ///
  /// In en, this message translates to:
  /// **'Conjunction'**
  String get chartLegendConjunction;

  /// No description provided for @chartLegendSextile.
  ///
  /// In en, this message translates to:
  /// **'Sextile'**
  String get chartLegendSextile;

  /// No description provided for @chartLegendSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get chartLegendSquare;

  /// No description provided for @chartLegendTrine.
  ///
  /// In en, this message translates to:
  /// **'Trine'**
  String get chartLegendTrine;

  /// No description provided for @chartLegendOpposition.
  ///
  /// In en, this message translates to:
  /// **'Opposition'**
  String get chartLegendOpposition;

  /// No description provided for @chartHouseNumber.
  ///
  /// In en, this message translates to:
  /// **'House {n}'**
  String chartHouseNumber(int n);

  /// No description provided for @chartHouse1.
  ///
  /// In en, this message translates to:
  /// **'Self & Identity'**
  String get chartHouse1;

  /// No description provided for @chartHouse2.
  ///
  /// In en, this message translates to:
  /// **'Values & Resources'**
  String get chartHouse2;

  /// No description provided for @chartHouse3.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get chartHouse3;

  /// No description provided for @chartHouse4.
  ///
  /// In en, this message translates to:
  /// **'Home & Roots'**
  String get chartHouse4;

  /// No description provided for @chartHouse5.
  ///
  /// In en, this message translates to:
  /// **'Creativity & Joy'**
  String get chartHouse5;

  /// No description provided for @chartHouse6.
  ///
  /// In en, this message translates to:
  /// **'Work & Wellness'**
  String get chartHouse6;

  /// No description provided for @chartHouse7.
  ///
  /// In en, this message translates to:
  /// **'Partnerships'**
  String get chartHouse7;

  /// No description provided for @chartHouse8.
  ///
  /// In en, this message translates to:
  /// **'Transformation'**
  String get chartHouse8;

  /// No description provided for @chartHouse9.
  ///
  /// In en, this message translates to:
  /// **'Philosophy & Travel'**
  String get chartHouse9;

  /// No description provided for @chartHouse10.
  ///
  /// In en, this message translates to:
  /// **'Career & Legacy'**
  String get chartHouse10;

  /// No description provided for @chartHouse11.
  ///
  /// In en, this message translates to:
  /// **'Community & Vision'**
  String get chartHouse11;

  /// No description provided for @chartHouse12.
  ///
  /// In en, this message translates to:
  /// **'Spirit & Surrender'**
  String get chartHouse12;

  /// No description provided for @chartNoPlanets.
  ///
  /// In en, this message translates to:
  /// **'No planet data'**
  String get chartNoPlanets;

  /// No description provided for @chartNoHouses.
  ///
  /// In en, this message translates to:
  /// **'No house data'**
  String get chartNoHouses;

  /// No description provided for @chartNoAspects.
  ///
  /// In en, this message translates to:
  /// **'No aspect data'**
  String get chartNoAspects;

  /// No description provided for @chartNoElements.
  ///
  /// In en, this message translates to:
  /// **'No element data'**
  String get chartNoElements;

  /// No description provided for @chartHouseLine.
  ///
  /// In en, this message translates to:
  /// **'{sign} · {degree}°'**
  String chartHouseLine(String sign, String degree);

  /// No description provided for @chartAspectOrb.
  ///
  /// In en, this message translates to:
  /// **'Orb {value}°'**
  String chartAspectOrb(String value);

  /// No description provided for @vedicScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Vedic Chart'**
  String get vedicScreenTitle;

  /// No description provided for @vedicAyanamsa.
  ///
  /// In en, this message translates to:
  /// **'Ayanamsa'**
  String get vedicAyanamsa;

  /// No description provided for @vedicTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get vedicTabOverview;

  /// No description provided for @vedicTabPlanets.
  ///
  /// In en, this message translates to:
  /// **'Planets'**
  String get vedicTabPlanets;

  /// No description provided for @vedicTabHouses.
  ///
  /// In en, this message translates to:
  /// **'Houses'**
  String get vedicTabHouses;

  /// No description provided for @vedicTabBhavas.
  ///
  /// In en, this message translates to:
  /// **'Bhavas'**
  String get vedicTabBhavas;

  /// No description provided for @vedicTabAspects.
  ///
  /// In en, this message translates to:
  /// **'Aspects'**
  String get vedicTabAspects;

  /// No description provided for @vedicTabNakshatras.
  ///
  /// In en, this message translates to:
  /// **'Nakshatras'**
  String get vedicTabNakshatras;

  /// No description provided for @vedicTabVargas.
  ///
  /// In en, this message translates to:
  /// **'Vargas'**
  String get vedicTabVargas;

  /// No description provided for @vedicTabDasha.
  ///
  /// In en, this message translates to:
  /// **'Dasha'**
  String get vedicTabDasha;

  /// No description provided for @vedicTabYogas.
  ///
  /// In en, this message translates to:
  /// **'Yogas'**
  String get vedicTabYogas;

  /// No description provided for @vedicTabShadbala.
  ///
  /// In en, this message translates to:
  /// **'Shadbala'**
  String get vedicTabShadbala;

  /// No description provided for @vedicTabAshtakavarga.
  ///
  /// In en, this message translates to:
  /// **'Ashtakavarga'**
  String get vedicTabAshtakavarga;

  /// No description provided for @vedicAtmakarakaLabel.
  ///
  /// In en, this message translates to:
  /// **'Atmakaraka: {name}'**
  String vedicAtmakarakaLabel(String name);

  /// No description provided for @vedicChartCaption.
  ///
  /// In en, this message translates to:
  /// **'{varga} (D{divisor}) · {ayanamsa} ayanamsa'**
  String vedicChartCaption(String varga, int divisor, String ayanamsa);

  /// No description provided for @vedicNoAspects.
  ///
  /// In en, this message translates to:
  /// **'No graha-to-graha drishti'**
  String get vedicNoAspects;

  /// No description provided for @vedicNoYogas.
  ///
  /// In en, this message translates to:
  /// **'No active classical yogas detected for this chart.'**
  String get vedicNoYogas;

  /// No description provided for @vedicNoShadbala.
  ///
  /// In en, this message translates to:
  /// **'No Shadbala data'**
  String get vedicNoShadbala;

  /// No description provided for @vedicVargasNote.
  ///
  /// In en, this message translates to:
  /// **'The hero chart above re-renders for the selected Varga. Each divisional chart reveals a different facet of life: D9 marriage and dharma, D10 career, D12 parents, D60 past karma.'**
  String get vedicVargasNote;

  /// No description provided for @vedicBhavaOccupants.
  ///
  /// In en, this message translates to:
  /// **'Occupants: {planets}'**
  String vedicBhavaOccupants(String planets);

  /// No description provided for @vedicBhavaLord.
  ///
  /// In en, this message translates to:
  /// **'{sign} ({sanskrit}) · Lord {lord}'**
  String vedicBhavaLord(String sign, String sanskrit, String lord);

  /// No description provided for @vedicAspectsLine.
  ///
  /// In en, this message translates to:
  /// **'{from} aspects {to}'**
  String vedicAspectsLine(String from, String to);

  /// No description provided for @vedicRetro.
  ///
  /// In en, this message translates to:
  /// **'Rx'**
  String get vedicRetro;

  /// No description provided for @vedicCombust.
  ///
  /// In en, this message translates to:
  /// **'Combust'**
  String get vedicCombust;

  /// No description provided for @numerologyTitle.
  ///
  /// In en, this message translates to:
  /// **'Numerology'**
  String get numerologyTitle;

  /// No description provided for @numerologyTabCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get numerologyTabCore;

  /// No description provided for @numerologyTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get numerologyTabToday;

  /// No description provided for @numerologyTabCycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get numerologyTabCycles;

  /// No description provided for @numerologyTabKarmic.
  ///
  /// In en, this message translates to:
  /// **'Karmic'**
  String get numerologyTabKarmic;

  /// No description provided for @numerologyTabCompat.
  ///
  /// In en, this message translates to:
  /// **'Compat'**
  String get numerologyTabCompat;

  /// No description provided for @numerologyTabCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get numerologyTabCompatibility;

  /// No description provided for @numerologyCompareWith.
  ///
  /// In en, this message translates to:
  /// **'Compare with someone'**
  String get numerologyCompareWith;

  /// No description provided for @numerologyNameCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Name Calculator'**
  String get numerologyNameCalculatorTitle;

  /// No description provided for @numerologyNameCalculatorBlurb.
  ///
  /// In en, this message translates to:
  /// **'Enter any full name to see its Expression, Soul Urge, and Personality numbers — plus the letter-by-letter breakdown.'**
  String get numerologyNameCalculatorBlurb;

  /// No description provided for @numerologyNameInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Norma Jeane Baker'**
  String get numerologyNameInputHint;

  /// No description provided for @numerologyNameCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get numerologyNameCalculate;

  /// No description provided for @numerologyNameOpenCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculate any name'**
  String get numerologyNameOpenCalculator;

  /// No description provided for @numerologyNameLetterBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Letter breakdown'**
  String get numerologyNameLetterBreakdown;

  /// No description provided for @numerologyNameVowels.
  ///
  /// In en, this message translates to:
  /// **'vowels'**
  String get numerologyNameVowels;

  /// No description provided for @numerologyNameConsonants.
  ///
  /// In en, this message translates to:
  /// **'consonants'**
  String get numerologyNameConsonants;

  /// No description provided for @numerologyNameHiddenPassion.
  ///
  /// In en, this message translates to:
  /// **'Hidden passion'**
  String get numerologyNameHiddenPassion;

  /// No description provided for @numerologyNameKarmicLessons.
  ///
  /// In en, this message translates to:
  /// **'Karmic lessons'**
  String get numerologyNameKarmicLessons;

  /// No description provided for @numerologyNameKarmicLessonsNone.
  ///
  /// In en, this message translates to:
  /// **'None — every digit appears in this name.'**
  String get numerologyNameKarmicLessonsNone;

  /// No description provided for @errOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get errOfflineTitle;

  /// No description provided for @errOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Some screens work without a signal, but charts need the sky.'**
  String get errOfflineBody;

  /// No description provided for @errAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get errAuthTitle;

  /// No description provided for @errAuthBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue. Your data is safe.'**
  String get errAuthBody;

  /// No description provided for @errRateLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Slow down a sec'**
  String get errRateLimitTitle;

  /// No description provided for @errRateLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve hit a daily limit. Try again later or upgrade to remove the cap.'**
  String get errRateLimitBody;

  /// No description provided for @errChatLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free messages with the astrologer. Upgrade to Premium for unlimited chat, or come back tomorrow.'**
  String get errChatLimitBody;

  /// No description provided for @errNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get errNotFoundTitle;

  /// No description provided for @errNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find what you were looking for. It might have moved or been removed.'**
  String get errNotFoundBody;

  /// No description provided for @errServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Something\'s off on our side'**
  String get errServerTitle;

  /// No description provided for @errServerBody.
  ///
  /// In en, this message translates to:
  /// **'Our server is having a moment. We\'re already looking — please try again in a bit.'**
  String get errServerBody;

  /// No description provided for @errCacheBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read the local copy. Try again — we\'ll fetch a fresh version.'**
  String get errCacheBody;

  /// No description provided for @errGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errGenericTitle;

  /// No description provided for @errGenericBody.
  ///
  /// In en, this message translates to:
  /// **'We hit an unexpected error. Tap retry, or restart the app if it keeps happening.'**
  String get errGenericBody;

  /// No description provided for @errRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errRetry;

  /// No description provided for @errGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get errGoHome;

  /// No description provided for @errReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report problem'**
  String get errReportProblem;

  /// No description provided for @errCrashTitle.
  ///
  /// In en, this message translates to:
  /// **'The cosmos hiccuped'**
  String get errCrashTitle;

  /// No description provided for @errCrashBody.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened. Restart the app — if it keeps happening, let us know.'**
  String get errCrashBody;

  /// No description provided for @numerologyLifePathBadge.
  ///
  /// In en, this message translates to:
  /// **'LIFE PATH'**
  String get numerologyLifePathBadge;

  /// No description provided for @numerologyMasterBadge.
  ///
  /// In en, this message translates to:
  /// **'MASTER'**
  String get numerologyMasterBadge;

  /// No description provided for @numerologyCoreLifePath.
  ///
  /// In en, this message translates to:
  /// **'Life Path'**
  String get numerologyCoreLifePath;

  /// No description provided for @numerologyCoreExpression.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get numerologyCoreExpression;

  /// No description provided for @numerologyCoreSoulUrge.
  ///
  /// In en, this message translates to:
  /// **'Soul Urge'**
  String get numerologyCoreSoulUrge;

  /// No description provided for @numerologyCorePersonality.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get numerologyCorePersonality;

  /// No description provided for @numerologyCoreMaturity.
  ///
  /// In en, this message translates to:
  /// **'Maturity'**
  String get numerologyCoreMaturity;

  /// No description provided for @numerologyCoreBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get numerologyCoreBirthday;

  /// No description provided for @numerologyCompatBlurb.
  ///
  /// In en, this message translates to:
  /// **'Enter their full birth name + birth date and we\'ll calculate numerology compatibility for the three relationship-relevant numbers.'**
  String get numerologyCompatBlurb;

  /// No description provided for @numerologyOpenCompat.
  ///
  /// In en, this message translates to:
  /// **'Open compatibility'**
  String get numerologyOpenCompat;

  /// No description provided for @humanDesignTitle.
  ///
  /// In en, this message translates to:
  /// **'Human Design'**
  String get humanDesignTitle;

  /// No description provided for @humanDesignTabBodyGraph.
  ///
  /// In en, this message translates to:
  /// **'Body Graph'**
  String get humanDesignTabBodyGraph;

  /// No description provided for @humanDesignTabCenters.
  ///
  /// In en, this message translates to:
  /// **'Centers'**
  String get humanDesignTabCenters;

  /// No description provided for @humanDesignTabChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get humanDesignTabChannels;

  /// No description provided for @humanDesignTabGates.
  ///
  /// In en, this message translates to:
  /// **'Gates'**
  String get humanDesignTabGates;

  /// No description provided for @humanDesignTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get humanDesignTabProfile;

  /// No description provided for @humanDesignBodyGraphLegend.
  ///
  /// In en, this message translates to:
  /// **'Filled centers are defined; outlined centers are open. Lines are defined channels. Red dots are Personality gates (conscious), cream dots are Design gates (unconscious).'**
  String get humanDesignBodyGraphLegend;

  /// No description provided for @humanDesignNoChannels.
  ///
  /// In en, this message translates to:
  /// **'No defined channels — you may be a Reflector or have only individual active gates.'**
  String get humanDesignNoChannels;

  /// No description provided for @humanDesignProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get humanDesignProfileLabel;

  /// No description provided for @humanDesignProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Personality conscious line × Design unconscious line.'**
  String get humanDesignProfileDesc;

  /// No description provided for @yearlyForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly Forecast'**
  String get yearlyForecastTitle;

  /// No description provided for @transitForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Transit Forecast'**
  String get transitForecastTitle;

  /// No description provided for @lifeTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Timeline'**
  String get lifeTimelineTitle;

  /// No description provided for @ritualsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rituals'**
  String get ritualsTitle;

  /// No description provided for @ritualsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Rituals'**
  String get ritualsTodayTitle;

  /// No description provided for @ritualsStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String ritualsStreak(int days);

  /// No description provided for @ritualsTodayHeading.
  ///
  /// In en, this message translates to:
  /// **'Your rituals for today'**
  String get ritualsTodayHeading;

  /// No description provided for @ritualsTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete these to strengthen your cosmic connection.'**
  String get ritualsTodaySubtitle;

  /// No description provided for @ritualMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning Intention'**
  String get ritualMorningTitle;

  /// No description provided for @ritualMorningDesc.
  ///
  /// In en, this message translates to:
  /// **'Set your intention for the day ahead.'**
  String get ritualMorningDesc;

  /// No description provided for @ritualAffirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Affirmation'**
  String get ritualAffirmationTitle;

  /// No description provided for @ritualAffirmationDesc.
  ///
  /// In en, this message translates to:
  /// **'Read and internalize today\'s affirmation.'**
  String get ritualAffirmationDesc;

  /// No description provided for @ritualEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening Reflection'**
  String get ritualEveningTitle;

  /// No description provided for @ritualEveningDesc.
  ///
  /// In en, this message translates to:
  /// **'Reflect on your day and note what you\'re grateful for.'**
  String get ritualEveningDesc;

  /// No description provided for @notifEmptyBlurb.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet — when people interact with your spaces, posts, or comments you\'ll see them here.'**
  String get notifEmptyBlurb;

  /// No description provided for @notifGroupToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get notifGroupToday;

  /// No description provided for @notifGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get notifGroupYesterday;

  /// No description provided for @notifGroupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get notifGroupThisWeek;

  /// No description provided for @notifGroupEarlier.
  ///
  /// In en, this message translates to:
  /// **'EARLIER'**
  String get notifGroupEarlier;

  /// No description provided for @spacePostsHeader.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get spacePostsHeader;

  /// No description provided for @spaceNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet — be the first.'**
  String get spaceNoPosts;

  /// No description provided for @editSpaceLossWarning.
  ///
  /// In en, this message translates to:
  /// **'All posts and comments will be permanently lost.'**
  String get editSpaceLossWarning;

  /// No description provided for @editSpaceSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editSpaceSaving;

  /// No description provided for @editSpaceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editSpaceSave;

  /// No description provided for @editSpaceHandleLabel.
  ///
  /// In en, this message translates to:
  /// **'HANDLE'**
  String get editSpaceHandleLabel;

  /// No description provided for @editSpaceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get editSpaceNameLabel;

  /// No description provided for @editSpaceDescLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get editSpaceDescLabel;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get homeWelcomeBack;

  /// No description provided for @dailyReadingHeading.
  ///
  /// In en, this message translates to:
  /// **'Your Daily Reading'**
  String get dailyReadingHeading;

  /// No description provided for @dailyReadingResonant.
  ///
  /// In en, this message translates to:
  /// **'Resonant'**
  String get dailyReadingResonant;

  /// No description provided for @yfYearTheme.
  ///
  /// In en, this message translates to:
  /// **'YOUR YEAR THEME'**
  String get yfYearTheme;

  /// No description provided for @yfQuarterBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Quarter Breakdown'**
  String get yfQuarterBreakdown;

  /// No description provided for @yfHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your cosmic roadmap. One year, four chapters, each with its own weather and weather forecast.'**
  String get yfHeroSubtitle;

  /// No description provided for @yfQuarterLabel.
  ///
  /// In en, this message translates to:
  /// **'Q{n}'**
  String yfQuarterLabel(int n);

  /// No description provided for @yfNoData.
  ///
  /// In en, this message translates to:
  /// **'No yearly forecast available yet. Check back soon.'**
  String get yfNoData;

  /// No description provided for @transit30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get transit30Days;

  /// No description provided for @transit3Months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get transit3Months;

  /// No description provided for @transit12Months.
  ///
  /// In en, this message translates to:
  /// **'12 Months'**
  String get transit12Months;

  /// No description provided for @transitHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Transit Forecast'**
  String get transitHeroTitle;

  /// No description provided for @transitHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The sky ahead — pick a window and see when to push, when to wait, and when to listen.'**
  String get transitHeroSubtitle;

  /// No description provided for @transitEnergyPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get transitEnergyPositive;

  /// No description provided for @transitEnergyChallenging.
  ///
  /// In en, this message translates to:
  /// **'Challenging'**
  String get transitEnergyChallenging;

  /// No description provided for @transitEnergyIntense.
  ///
  /// In en, this message translates to:
  /// **'Intense'**
  String get transitEnergyIntense;

  /// No description provided for @transitEnergyNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get transitEnergyNeutral;

  /// No description provided for @transitNoData.
  ///
  /// In en, this message translates to:
  /// **'No transits charted for this window yet.'**
  String get transitNoData;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @communityCreateSpace.
  ///
  /// In en, this message translates to:
  /// **'Create space'**
  String get communityCreateSpace;

  /// No description provided for @communityHeroBlurb.
  ///
  /// In en, this message translates to:
  /// **'Find your people. Share readings, ask questions, follow the conversations that move you.'**
  String get communityHeroBlurb;

  /// No description provided for @communityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityFilterAll;

  /// No description provided for @communityFilterJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get communityFilterJoined;

  /// No description provided for @communitySpacesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet.'**
  String get communitySpacesEmpty;

  /// No description provided for @communityNewPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get communityNewPost;

  /// No description provided for @communityWriteSomething.
  ///
  /// In en, this message translates to:
  /// **'Write something...'**
  String get communityWriteSomething;

  /// No description provided for @communityPostSubmit.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityPostSubmit;

  /// No description provided for @communityComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get communityComment;

  /// No description provided for @communityReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get communityReply;

  /// No description provided for @communityLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get communityLike;

  /// No description provided for @communityShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get communityShare;

  /// No description provided for @communityJoinSpace.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get communityJoinSpace;

  /// No description provided for @communityLeaveSpace.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get communityLeaveSpace;

  /// No description provided for @communityMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communityMembers;

  /// No description provided for @communityNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get communityNotifications;

  /// No description provided for @communityNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing new.'**
  String get communityNotificationsEmpty;

  /// No description provided for @communityMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get communityMarkAllRead;

  /// No description provided for @communityPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityPostTitle;

  /// No description provided for @communityNewSpace.
  ///
  /// In en, this message translates to:
  /// **'New Space'**
  String get communityNewSpace;

  /// No description provided for @communityEditSpace.
  ///
  /// In en, this message translates to:
  /// **'Edit Space'**
  String get communityEditSpace;

  /// No description provided for @communityDeleteSpaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this space?'**
  String get communityDeleteSpaceConfirm;

  /// No description provided for @communityProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get communityProfile;

  /// No description provided for @communityCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get communityCategoriesLabel;

  /// No description provided for @communitySearchSpaces.
  ///
  /// In en, this message translates to:
  /// **'Search spaces'**
  String get communitySearchSpaces;

  /// No description provided for @communityNewPostTitle.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get communityNewPostTitle;

  /// No description provided for @communitySpacesEmptyTap.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet — tap + to create the first one.'**
  String get communitySpacesEmptyTap;

  /// No description provided for @communityComposeHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get communityComposeHint;

  /// No description provided for @communityLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Optional link URL'**
  String get communityLinkHint;

  /// No description provided for @communityNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get communityNotificationsTooltip;

  /// No description provided for @communityNewSpaceTooltip.
  ///
  /// In en, this message translates to:
  /// **'New space'**
  String get communityNewSpaceTooltip;

  /// No description provided for @lifeTimelineAddMoment.
  ///
  /// In en, this message translates to:
  /// **'Add Moment'**
  String get lifeTimelineAddMoment;

  /// No description provided for @lifeTimelineMomentsMapped.
  ///
  /// In en, this message translates to:
  /// **'{count} moments mapped'**
  String lifeTimelineMomentsMapped(int count);

  /// No description provided for @lifeTimelineHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Cosmic Timeline'**
  String get lifeTimelineHeaderTitle;

  /// No description provided for @lifeTimelineHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your life mapped against the sky.\nAdd moments. See what was happening above.'**
  String get lifeTimelineHeaderSubtitle;

  /// No description provided for @lifeTimelineFelt.
  ///
  /// In en, this message translates to:
  /// **'felt {mood}'**
  String lifeTimelineFelt(String mood);

  /// No description provided for @lifeTimelineWhatSky.
  ///
  /// In en, this message translates to:
  /// **'WHAT THE SKY WAS DOING'**
  String get lifeTimelineWhatSky;
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
