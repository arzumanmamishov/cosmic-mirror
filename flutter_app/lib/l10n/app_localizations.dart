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

  /// No description provided for @spaceLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Members-only space'**
  String get spaceLockedTitle;

  /// No description provided for @spaceLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Join to request access. The owner will accept or decline your request, and you\'ll get a notification either way.'**
  String get spaceLockedBody;

  /// No description provided for @spacePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Request pending'**
  String get spacePendingTitle;

  /// No description provided for @spacePendingBody.
  ///
  /// In en, this message translates to:
  /// **'The space owner hasn\'t reviewed your request yet. You\'ll be able to see posts here as soon as they accept.'**
  String get spacePendingBody;

  /// No description provided for @spaceManageRequests.
  ///
  /// In en, this message translates to:
  /// **'Manage join requests'**
  String get spaceManageRequests;

  /// No description provided for @spaceRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Join requests'**
  String get spaceRequestsTitle;

  /// No description provided for @spaceRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests right now.'**
  String get spaceRequestsEmpty;

  /// No description provided for @spaceRequestsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get spaceRequestsAccept;

  /// No description provided for @spaceRequestsDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get spaceRequestsDecline;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address on your account and we\'ll send you a link to set a new password.'**
  String get authResetPasswordBody;

  /// No description provided for @authResetPasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authResetPasswordSend;

  /// No description provided for @authResetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox — we just sent a reset link to {email}.'**
  String authResetPasswordSent(Object email);

  /// No description provided for @authResetPasswordEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email first.'**
  String get authResetPasswordEmailEmpty;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 8 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server — check your internet connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in isn\'t enabled for this app. Please contact support.'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authErrorGeneric;

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

  /// No description provided for @onboardingNameReassure.
  ///
  /// In en, this message translates to:
  /// **'We\'ll never share this. Change it any time in Profile.'**
  String get onboardingNameReassure;

  /// No description provided for @onboardingFocusCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of 3 selected'**
  String onboardingFocusCount(int count);

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
  /// **'Enter Lively'**
  String get welcomeEnter;

  /// No description provided for @welcomeAligning.
  ///
  /// In en, this message translates to:
  /// **'Aligning the stars…'**
  String get welcomeAligning;

  /// No description provided for @welcomeKicker.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeKicker(Object name);

  /// No description provided for @welcomeChartReady.
  ///
  /// In en, this message translates to:
  /// **'Your chart'**
  String get welcomeChartReady;

  /// No description provided for @welcomeChartReady2.
  ///
  /// In en, this message translates to:
  /// **'is ready.'**
  String get welcomeChartReady2;

  /// No description provided for @welcomeSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get welcomeSun;

  /// No description provided for @welcomeMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get welcomeMoon;

  /// No description provided for @welcomeRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get welcomeRising;

  /// No description provided for @authHeroSignIn.
  ///
  /// In en, this message translates to:
  /// **'The sky,\nmade personal.'**
  String get authHeroSignIn;

  /// No description provided for @authHeroSignUp.
  ///
  /// In en, this message translates to:
  /// **'Begin your\ncosmic profile.'**
  String get authHeroSignUp;

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
  /// **'Colored centers are defined; white centers are open. Black is Personality (conscious), red is Design (unconscious), striped is both. Pinch the chart to zoom.'**
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

  /// No description provided for @commonJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get commonJustNow;

  /// No description provided for @commonMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String commonMinutesAgo(int count);

  /// No description provided for @commonHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String commonHoursAgo(int count);

  /// No description provided for @commonDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String commonDaysAgo(int count);

  /// No description provided for @commonGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get commonGoodMorning;

  /// No description provided for @commonGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get commonGoodAfternoon;

  /// No description provided for @commonGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get commonGoodEvening;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get validationNameTooShort;

  /// No description provided for @validationNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be less than 50 characters'**
  String get validationNameTooLong;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get validationPasswordRequired;

  /// No description provided for @validationBirthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your birth date'**
  String get validationBirthDateRequired;

  /// No description provided for @validationBirthDateFuture.
  ///
  /// In en, this message translates to:
  /// **'Birth date cannot be in the future'**
  String get validationBirthDateFuture;

  /// No description provided for @validationMinAge.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old'**
  String get validationMinAge;

  /// No description provided for @validationBirthDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid birth date'**
  String get validationBirthDateInvalid;

  /// No description provided for @validationBirthPlaceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your birthplace'**
  String get validationBirthPlaceRequired;

  /// No description provided for @validationMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get validationMessageRequired;

  /// No description provided for @validationMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message must be less than 500 characters'**
  String get validationMessageTooLong;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authInvalidEmail;

  /// No description provided for @authNoAccountTapCreate.
  ///
  /// In en, this message translates to:
  /// **'No account with that email. Tap Create account to sign up.'**
  String get authNoAccountTapCreate;

  /// No description provided for @authNoAccountCheckAddress.
  ///
  /// In en, this message translates to:
  /// **'No account with that email. Check the address or create one.'**
  String get authNoAccountCheckAddress;

  /// No description provided for @authTooManyCodeRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many code requests. Please wait a minute.'**
  String get authTooManyCodeRequests;

  /// No description provided for @authTooManyAttemptsShort.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again shortly.'**
  String get authTooManyAttemptsShort;

  /// No description provided for @authTooManyAttemptsWait.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute.'**
  String get authTooManyAttemptsWait;

  /// No description provided for @authKickerWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get authKickerWelcomeBack;

  /// No description provided for @authKickerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get authKickerCreateAccount;

  /// No description provided for @authBeginJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey'**
  String get authBeginJourney;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your cosmic mirror is waiting. Sign in to continue.'**
  String get authSignInSubtitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few details and the stars are yours to explore.'**
  String get authRegisterSubtitle;

  /// No description provided for @authSignInWithCode.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a code instead'**
  String get authSignInWithCode;

  /// No description provided for @authForgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotYourPassword;

  /// No description provided for @authResetPasswordKicker.
  ///
  /// In en, this message translates to:
  /// **'RESET PASSWORD'**
  String get authResetPasswordKicker;

  /// No description provided for @authForgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a code to set a new password.'**
  String get authForgotPasswordBody;

  /// No description provided for @authSendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get authSendResetCode;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please sign in.'**
  String get authPasswordUpdated;

  /// No description provided for @authOtpInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work. Try again or resend.'**
  String get authOtpInvalidCode;

  /// No description provided for @authOtpKickerConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM YOUR EMAIL'**
  String get authOtpKickerConfirmEmail;

  /// No description provided for @authOtpKickerSignIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get authOtpKickerSignIn;

  /// No description provided for @authOtpKickerResetPassword.
  ///
  /// In en, this message translates to:
  /// **'RESET YOUR PASSWORD'**
  String get authOtpKickerResetPassword;

  /// No description provided for @authOtpCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authOtpCheckEmail;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String authOtpSentTo(String email);

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authResetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordButton;

  /// No description provided for @authOtpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String authOtpResendIn(String time);

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authOtpResend;

  /// No description provided for @onboardingRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cosmic blueprint'**
  String get onboardingRevealTitle;

  /// No description provided for @onboardingRevealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here are your Big Three.'**
  String get onboardingRevealSubtitle;

  /// No description provided for @onboardingRevealSunSign.
  ///
  /// In en, this message translates to:
  /// **'Sun Sign'**
  String get onboardingRevealSunSign;

  /// No description provided for @onboardingRevealMoonSign.
  ///
  /// In en, this message translates to:
  /// **'Moon Sign'**
  String get onboardingRevealMoonSign;

  /// No description provided for @onboardingRevealRisingSign.
  ///
  /// In en, this message translates to:
  /// **'Rising Sign'**
  String get onboardingRevealRisingSign;

  /// No description provided for @onboardingSignUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get onboardingSignUnknown;

  /// No description provided for @premiumUnlockFeature.
  ///
  /// In en, this message translates to:
  /// **'Unlock {feature}'**
  String premiumUnlockFeature(String feature);

  /// No description provided for @premiumUnlockThisFeature.
  ///
  /// In en, this message translates to:
  /// **'Unlock this feature'**
  String get premiumUnlockThisFeature;

  /// No description provided for @premiumUpgradeBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium for full access to personalized insights.'**
  String get premiumUpgradeBody;

  /// No description provided for @premiumViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get premiumViewPlans;

  /// No description provided for @paywallPricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/mo'**
  String paywallPricePerMonth(String price);

  /// No description provided for @paywallPricePerYear.
  ///
  /// In en, this message translates to:
  /// **'{price}/yr'**
  String paywallPricePerYear(String price);

  /// No description provided for @chartSignAries.
  ///
  /// In en, this message translates to:
  /// **'Aries'**
  String get chartSignAries;

  /// No description provided for @chartSignTaurus.
  ///
  /// In en, this message translates to:
  /// **'Taurus'**
  String get chartSignTaurus;

  /// No description provided for @chartSignGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get chartSignGemini;

  /// No description provided for @chartSignCancer.
  ///
  /// In en, this message translates to:
  /// **'Cancer'**
  String get chartSignCancer;

  /// No description provided for @chartSignLeo.
  ///
  /// In en, this message translates to:
  /// **'Leo'**
  String get chartSignLeo;

  /// No description provided for @chartSignVirgo.
  ///
  /// In en, this message translates to:
  /// **'Virgo'**
  String get chartSignVirgo;

  /// No description provided for @chartSignLibra.
  ///
  /// In en, this message translates to:
  /// **'Libra'**
  String get chartSignLibra;

  /// No description provided for @chartSignScorpio.
  ///
  /// In en, this message translates to:
  /// **'Scorpio'**
  String get chartSignScorpio;

  /// No description provided for @chartSignSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Sagittarius'**
  String get chartSignSagittarius;

  /// No description provided for @chartSignCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Capricorn'**
  String get chartSignCapricorn;

  /// No description provided for @chartSignAquarius.
  ///
  /// In en, this message translates to:
  /// **'Aquarius'**
  String get chartSignAquarius;

  /// No description provided for @chartSignPisces.
  ///
  /// In en, this message translates to:
  /// **'Pisces'**
  String get chartSignPisces;

  /// No description provided for @chartSignAbbrAries.
  ///
  /// In en, this message translates to:
  /// **'Ar'**
  String get chartSignAbbrAries;

  /// No description provided for @chartSignAbbrTaurus.
  ///
  /// In en, this message translates to:
  /// **'Ta'**
  String get chartSignAbbrTaurus;

  /// No description provided for @chartSignAbbrGemini.
  ///
  /// In en, this message translates to:
  /// **'Ge'**
  String get chartSignAbbrGemini;

  /// No description provided for @chartSignAbbrCancer.
  ///
  /// In en, this message translates to:
  /// **'Cn'**
  String get chartSignAbbrCancer;

  /// No description provided for @chartSignAbbrLeo.
  ///
  /// In en, this message translates to:
  /// **'Le'**
  String get chartSignAbbrLeo;

  /// No description provided for @chartSignAbbrVirgo.
  ///
  /// In en, this message translates to:
  /// **'Vi'**
  String get chartSignAbbrVirgo;

  /// No description provided for @chartSignAbbrLibra.
  ///
  /// In en, this message translates to:
  /// **'Li'**
  String get chartSignAbbrLibra;

  /// No description provided for @chartSignAbbrScorpio.
  ///
  /// In en, this message translates to:
  /// **'Sc'**
  String get chartSignAbbrScorpio;

  /// No description provided for @chartSignAbbrSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Sg'**
  String get chartSignAbbrSagittarius;

  /// No description provided for @chartSignAbbrCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Cp'**
  String get chartSignAbbrCapricorn;

  /// No description provided for @chartSignAbbrAquarius.
  ///
  /// In en, this message translates to:
  /// **'Aq'**
  String get chartSignAbbrAquarius;

  /// No description provided for @chartSignAbbrPisces.
  ///
  /// In en, this message translates to:
  /// **'Pi'**
  String get chartSignAbbrPisces;

  /// No description provided for @chartPlanetSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get chartPlanetSun;

  /// No description provided for @chartPlanetMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get chartPlanetMoon;

  /// No description provided for @chartPlanetMercury.
  ///
  /// In en, this message translates to:
  /// **'Mercury'**
  String get chartPlanetMercury;

  /// No description provided for @chartPlanetVenus.
  ///
  /// In en, this message translates to:
  /// **'Venus'**
  String get chartPlanetVenus;

  /// No description provided for @chartPlanetMars.
  ///
  /// In en, this message translates to:
  /// **'Mars'**
  String get chartPlanetMars;

  /// No description provided for @chartPlanetJupiter.
  ///
  /// In en, this message translates to:
  /// **'Jupiter'**
  String get chartPlanetJupiter;

  /// No description provided for @chartPlanetSaturn.
  ///
  /// In en, this message translates to:
  /// **'Saturn'**
  String get chartPlanetSaturn;

  /// No description provided for @chartPlanetUranus.
  ///
  /// In en, this message translates to:
  /// **'Uranus'**
  String get chartPlanetUranus;

  /// No description provided for @chartPlanetNeptune.
  ///
  /// In en, this message translates to:
  /// **'Neptune'**
  String get chartPlanetNeptune;

  /// No description provided for @chartPlanetPluto.
  ///
  /// In en, this message translates to:
  /// **'Pluto'**
  String get chartPlanetPluto;

  /// No description provided for @chartPlanetNorthNode.
  ///
  /// In en, this message translates to:
  /// **'North Node'**
  String get chartPlanetNorthNode;

  /// No description provided for @chartPlanetSouthNode.
  ///
  /// In en, this message translates to:
  /// **'South Node'**
  String get chartPlanetSouthNode;

  /// No description provided for @chartPlanetChiron.
  ///
  /// In en, this message translates to:
  /// **'Chiron'**
  String get chartPlanetChiron;

  /// No description provided for @chartAspectQuincunx.
  ///
  /// In en, this message translates to:
  /// **'Quincunx'**
  String get chartAspectQuincunx;

  /// No description provided for @chartAspectTitle.
  ///
  /// In en, this message translates to:
  /// **'{planet1} {aspect} {planet2}'**
  String chartAspectTitle(String planet1, String aspect, String planet2);

  /// No description provided for @chartElementFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get chartElementFire;

  /// No description provided for @chartElementEarth.
  ///
  /// In en, this message translates to:
  /// **'Earth'**
  String get chartElementEarth;

  /// No description provided for @chartElementAir.
  ///
  /// In en, this message translates to:
  /// **'Air'**
  String get chartElementAir;

  /// No description provided for @chartElementWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get chartElementWater;

  /// No description provided for @chartPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String chartPercent(String value);

  /// No description provided for @vedicLagnaLabel.
  ///
  /// In en, this message translates to:
  /// **'LAGNA'**
  String get vedicLagnaLabel;

  /// No description provided for @vedicChandraLabel.
  ///
  /// In en, this message translates to:
  /// **'CHANDRA'**
  String get vedicChandraLabel;

  /// No description provided for @vedicSuryaLabel.
  ///
  /// In en, this message translates to:
  /// **'SURYA'**
  String get vedicSuryaLabel;

  /// No description provided for @vedicLagna.
  ///
  /// In en, this message translates to:
  /// **'Lagna'**
  String get vedicLagna;

  /// No description provided for @vedicPlanetPosition.
  ///
  /// In en, this message translates to:
  /// **'{sign} ({sanskrit}) · {degree}° · House {house}'**
  String vedicPlanetPosition(
      String sign, String sanskrit, String degree, int house);

  /// No description provided for @vedicNakshatraPada.
  ///
  /// In en, this message translates to:
  /// **'{nakshatra} pada {pada}'**
  String vedicNakshatraPada(String nakshatra, int pada);

  /// No description provided for @vedicDignityExalted.
  ///
  /// In en, this message translates to:
  /// **'Exalted'**
  String get vedicDignityExalted;

  /// No description provided for @vedicDignityDebilitated.
  ///
  /// In en, this message translates to:
  /// **'Debilitated'**
  String get vedicDignityDebilitated;

  /// No description provided for @vedicDignityMooltrikona.
  ///
  /// In en, this message translates to:
  /// **'Mooltrikona'**
  String get vedicDignityMooltrikona;

  /// No description provided for @vedicDignityOwn.
  ///
  /// In en, this message translates to:
  /// **'Own'**
  String get vedicDignityOwn;

  /// No description provided for @vedicDignityFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get vedicDignityFriend;

  /// No description provided for @vedicDignityEnemy.
  ///
  /// In en, this message translates to:
  /// **'Enemy'**
  String get vedicDignityEnemy;

  /// No description provided for @vedicDignityNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get vedicDignityNeutral;

  /// No description provided for @vedicAspectOrdinal.
  ///
  /// In en, this message translates to:
  /// **'{n, select, 1{1st} 2{2nd} 3{3rd} other{{n}th}}'**
  String vedicAspectOrdinal(String n);

  /// No description provided for @vedicMahadashasHeader.
  ///
  /// In en, this message translates to:
  /// **'Mahadashas (120-year cycle)'**
  String get vedicMahadashasHeader;

  /// No description provided for @vedicCurrentDasha.
  ///
  /// In en, this message translates to:
  /// **'CURRENT DASHA'**
  String get vedicCurrentDasha;

  /// No description provided for @vedicDashaLevels.
  ///
  /// In en, this message translates to:
  /// **'Maha · Antar · Pratyantar'**
  String get vedicDashaLevels;

  /// No description provided for @vedicDashaNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get vedicDashaNow;

  /// No description provided for @vedicYogaStrength.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get vedicYogaStrength;

  /// No description provided for @vedicYogaCategoryPanchaMahapurusha.
  ///
  /// In en, this message translates to:
  /// **'Pancha Mahapurusha'**
  String get vedicYogaCategoryPanchaMahapurusha;

  /// No description provided for @vedicYogaCategoryLunar.
  ///
  /// In en, this message translates to:
  /// **'Lunar'**
  String get vedicYogaCategoryLunar;

  /// No description provided for @vedicYogaCategorySolar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get vedicYogaCategorySolar;

  /// No description provided for @vedicYogaCategoryWealth.
  ///
  /// In en, this message translates to:
  /// **'Wealth'**
  String get vedicYogaCategoryWealth;

  /// No description provided for @vedicYogaCategoryPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get vedicYogaCategoryPower;

  /// No description provided for @vedicYogaCategoryWisdom.
  ///
  /// In en, this message translates to:
  /// **'Wisdom'**
  String get vedicYogaCategoryWisdom;

  /// No description provided for @vedicYogaCategoryNodal.
  ///
  /// In en, this message translates to:
  /// **'Nodal'**
  String get vedicYogaCategoryNodal;

  /// No description provided for @vedicNakshatraPadaRuler.
  ///
  /// In en, this message translates to:
  /// **'Pada {pada} · Ruler {ruler}'**
  String vedicNakshatraPadaRuler(int pada, String ruler);

  /// No description provided for @vedicNakshatraDeity.
  ///
  /// In en, this message translates to:
  /// **'Deity'**
  String get vedicNakshatraDeity;

  /// No description provided for @vedicNakshatraSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get vedicNakshatraSymbol;

  /// No description provided for @vedicNakshatraGana.
  ///
  /// In en, this message translates to:
  /// **'Gana'**
  String get vedicNakshatraGana;

  /// No description provided for @vedicNakshatraNadi.
  ///
  /// In en, this message translates to:
  /// **'Nadi'**
  String get vedicNakshatraNadi;

  /// No description provided for @vedicNakshatraVarna.
  ///
  /// In en, this message translates to:
  /// **'Varna'**
  String get vedicNakshatraVarna;

  /// No description provided for @vedicNakshatraCaste.
  ///
  /// In en, this message translates to:
  /// **'Caste'**
  String get vedicNakshatraCaste;

  /// No description provided for @vedicNakshatraAnimal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get vedicNakshatraAnimal;

  /// No description provided for @vedicNakshatraGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get vedicNakshatraGender;

  /// No description provided for @vedicShadbalaSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} / {required} Virupas — {verdict}'**
  String vedicShadbalaSummary(String total, String required, String verdict);

  /// No description provided for @vedicShadbalaStrong.
  ///
  /// In en, this message translates to:
  /// **'STRONG'**
  String get vedicShadbalaStrong;

  /// No description provided for @vedicShadbalaWeak.
  ///
  /// In en, this message translates to:
  /// **'WEAK'**
  String get vedicShadbalaWeak;

  /// No description provided for @vedicShadbalaChesta.
  ///
  /// In en, this message translates to:
  /// **'Chesta'**
  String get vedicShadbalaChesta;

  /// No description provided for @vedicAshtakavargaSarva.
  ///
  /// In en, this message translates to:
  /// **'Sarva'**
  String get vedicAshtakavargaSarva;

  /// No description provided for @vedicAshtakavargaSarvaNote.
  ///
  /// In en, this message translates to:
  /// **'Sarva Ashtakavarga — total benefic points each sign receives from all seven grahas (max {max} per sign).'**
  String vedicAshtakavargaSarvaNote(int max);

  /// No description provided for @vedicAshtakavargaBhinnNote.
  ///
  /// In en, this message translates to:
  /// **'Bhinn Ashtakavarga of {planet} — bindus contributed to each sign by {planet} (max {max} per sign).'**
  String vedicAshtakavargaBhinnNote(String planet, int max);

  /// No description provided for @communityMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String communityMembersCount(int count);

  /// No description provided for @communityCategoryFallback.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get communityCategoryFallback;

  /// No description provided for @communityCategoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spaces in this category yet.'**
  String get communityCategoryEmpty;

  /// No description provided for @postInSpace.
  ///
  /// In en, this message translates to:
  /// **'in @{handle}'**
  String postInSpace(String handle);

  /// No description provided for @postCommentsHeader.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get postCommentsHeader;

  /// No description provided for @postNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get postNoComments;

  /// No description provided for @postReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String postReplyingTo(String name);

  /// No description provided for @postWriteCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get postWriteCommentHint;

  /// No description provided for @spaceCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get spaceCreateAction;

  /// No description provided for @spaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Stargazers Club'**
  String get spaceNameHint;

  /// No description provided for @spaceHandleHint.
  ///
  /// In en, this message translates to:
  /// **'stargazers'**
  String get spaceHandleHint;

  /// No description provided for @spaceDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this space about?'**
  String get spaceDescriptionHint;

  /// No description provided for @spaceCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get spaceCategoryLabel;

  /// No description provided for @spaceSpicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Spicy'**
  String get spaceSpicyLabel;

  /// No description provided for @spaceSpicyDescription.
  ///
  /// In en, this message translates to:
  /// **'Mature topics — shown with a Spicy badge.'**
  String get spaceSpicyDescription;

  /// No description provided for @communityHashtagComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Posts by hashtag are coming soon.'**
  String get communityHashtagComingSoon;

  /// No description provided for @communityHashtagComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'For now, browse spaces and discover hashtags inside posts.'**
  String get communityHashtagComingSoonBody;

  /// No description provided for @postTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get postTimeNow;

  /// No description provided for @postTimeMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String postTimeMinutesShort(int n);

  /// No description provided for @postTimeHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String postTimeHoursShort(int n);

  /// No description provided for @postTimeDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String postTimeDaysShort(int n);

  /// No description provided for @postTimeWeeksShort.
  ///
  /// In en, this message translates to:
  /// **'{n}w'**
  String postTimeWeeksShort(int n);

  /// No description provided for @notificationTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get notificationTimeJustNow;

  /// No description provided for @notificationTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String notificationTimeMinutesAgo(int n);

  /// No description provided for @notificationTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String notificationTimeHoursAgo(int n);

  /// No description provided for @notificationTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String notificationTimeDaysAgo(int n);

  /// No description provided for @notificationTimeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}w ago'**
  String notificationTimeWeeksAgo(int n);

  /// No description provided for @notificationPostLiked.
  ///
  /// In en, this message translates to:
  /// **'liked your post'**
  String get notificationPostLiked;

  /// No description provided for @notificationCommentLiked.
  ///
  /// In en, this message translates to:
  /// **'liked your comment'**
  String get notificationCommentLiked;

  /// No description provided for @notificationPostCommented.
  ///
  /// In en, this message translates to:
  /// **'commented on your post'**
  String get notificationPostCommented;

  /// No description provided for @notificationCommentReplied.
  ///
  /// In en, this message translates to:
  /// **'replied to your comment'**
  String get notificationCommentReplied;

  /// No description provided for @notificationSpaceMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'joined your space'**
  String get notificationSpaceMemberJoined;

  /// No description provided for @notificationSpaceFollowed.
  ///
  /// In en, this message translates to:
  /// **'followed your space'**
  String get notificationSpaceFollowed;

  /// No description provided for @notificationSpaceJoinRequested.
  ///
  /// In en, this message translates to:
  /// **'requested to join your space'**
  String get notificationSpaceJoinRequested;

  /// No description provided for @notificationSpaceJoinApproved.
  ///
  /// In en, this message translates to:
  /// **'accepted your request to join'**
  String get notificationSpaceJoinApproved;

  /// No description provided for @notificationSpaceJoinDeclined.
  ///
  /// In en, this message translates to:
  /// **'declined your request to join'**
  String get notificationSpaceJoinDeclined;

  /// No description provided for @notificationPostInSpace.
  ///
  /// In en, this message translates to:
  /// **'posted in a space you follow'**
  String get notificationPostInSpace;

  /// No description provided for @notificationMentioned.
  ///
  /// In en, this message translates to:
  /// **'mentioned you'**
  String get notificationMentioned;

  /// No description provided for @notificationGeneric.
  ///
  /// In en, this message translates to:
  /// **'sent you a notification'**
  String get notificationGeneric;

  /// No description provided for @communityProfileJoinedSpaces.
  ///
  /// In en, this message translates to:
  /// **'JOINED SPACES ({count})'**
  String communityProfileJoinedSpaces(int count);

  /// No description provided for @communityProfileNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Not in any spaces yet.'**
  String get communityProfileNoSpaces;

  /// No description provided for @communityProfileRecentPosts.
  ///
  /// In en, this message translates to:
  /// **'RECENT POSTS ({count})'**
  String communityProfileRecentPosts(int count);

  /// No description provided for @communityProfileNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get communityProfileNoPosts;

  /// No description provided for @communityUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get communityUnknownUser;

  /// No description provided for @communityUnknownMember.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get communityUnknownMember;

  /// No description provided for @spaceRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get spaceRoleOwner;

  /// No description provided for @spaceRoleMod.
  ///
  /// In en, this message translates to:
  /// **'MOD'**
  String get spaceRoleMod;

  /// No description provided for @spaceRoleMember.
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get spaceRoleMember;

  /// No description provided for @spaceJoinPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get spaceJoinPending;

  /// No description provided for @communityMembersCountCompact.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String communityMembersCountCompact(String count);

  /// No description provided for @aiChatSuggestedQuestionsCaps.
  ///
  /// In en, this message translates to:
  /// **'TRY ASKING…'**
  String get aiChatSuggestedQuestionsCaps;

  /// No description provided for @chatThreadsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and all its messages will be removed. This cannot be undone.'**
  String chatThreadsDeleteBody(String title);

  /// No description provided for @chatThreadsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Conversations'**
  String get chatThreadsHeaderTitle;

  /// No description provided for @chatThreadsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conversation} other{{count} conversations}} · powered by your chart'**
  String chatThreadsHeaderSubtitle(int count);

  /// No description provided for @chatThreadsTapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue your reading'**
  String get chatThreadsTapToContinue;

  /// No description provided for @chatThreadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin a Cosmic Dialogue'**
  String get chatThreadsEmptyTitle;

  /// No description provided for @chatThreadsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your chart, transits,\nor a moment you want to understand.'**
  String get chatThreadsEmptyBody;

  /// No description provided for @aiMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Memory'**
  String get aiMemoryTitle;

  /// No description provided for @aiMemorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'What I remember about you'**
  String get aiMemorySubtitle;

  /// No description provided for @aiMemoryLive.
  ///
  /// In en, this message translates to:
  /// **'live'**
  String get aiMemoryLive;

  /// No description provided for @aiMemorySaturnReturnLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturn return (1st pass)'**
  String get aiMemorySaturnReturnLabel;

  /// No description provided for @aiMemorySaturnReturnDetail.
  ///
  /// In en, this message translates to:
  /// **'You\'ve asked about this 4 times since February.'**
  String get aiMemorySaturnReturnDetail;

  /// No description provided for @aiMemoryCareerLabel.
  ///
  /// In en, this message translates to:
  /// **'Career transition'**
  String get aiMemoryCareerLabel;

  /// No description provided for @aiMemoryCareerDetail.
  ///
  /// In en, this message translates to:
  /// **'You\'re weighing a move into product design.'**
  String get aiMemoryCareerDetail;

  /// No description provided for @aiMemoryPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Theo, Pisces'**
  String get aiMemoryPartnerLabel;

  /// No description provided for @aiMemoryPartnerDetail.
  ///
  /// In en, this message translates to:
  /// **'Compatibility synastry saved · Oct 2024.'**
  String get aiMemoryPartnerDetail;

  /// No description provided for @aiMemorySelfTrustLabel.
  ///
  /// In en, this message translates to:
  /// **'Self-trust theme'**
  String get aiMemorySelfTrustLabel;

  /// No description provided for @aiMemorySelfTrustDetail.
  ///
  /// In en, this message translates to:
  /// **'A recurring question across 6 conversations.'**
  String get aiMemorySelfTrustDetail;

  /// No description provided for @compatSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get compatSomeone;

  /// No description provided for @compatShareText.
  ///
  /// In en, this message translates to:
  /// **'My cosmic compatibility with {name} is {score}%! Check yours on Lively.'**
  String compatShareText(String name, int score);

  /// No description provided for @compatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get compatYou;

  /// No description provided for @compatYouAnd.
  ///
  /// In en, this message translates to:
  /// **'You & {name}'**
  String compatYouAnd(String name);

  /// No description provided for @compatRelPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get compatRelPartner;

  /// No description provided for @compatRelFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get compatRelFriend;

  /// No description provided for @compatRelFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get compatRelFamily;

  /// No description provided for @compatRelCoworker.
  ///
  /// In en, this message translates to:
  /// **'Coworker'**
  String get compatRelCoworker;

  /// No description provided for @compatRelCrush.
  ///
  /// In en, this message translates to:
  /// **'Crush'**
  String get compatRelCrush;

  /// No description provided for @compatRelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get compatRelOther;

  /// No description provided for @timelineFeatureName.
  ///
  /// In en, this message translates to:
  /// **'Timeline Forecasts'**
  String get timelineFeatureName;

  /// No description provided for @lifeTimelineCatCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get lifeTimelineCatCareer;

  /// No description provided for @lifeTimelineCatLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get lifeTimelineCatLove;

  /// No description provided for @lifeTimelineCatGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get lifeTimelineCatGrowth;

  /// No description provided for @lifeTimelineCatLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get lifeTimelineCatLoss;

  /// No description provided for @lifeTimelineCatTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get lifeTimelineCatTravel;

  /// No description provided for @lifeTimelineCatFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get lifeTimelineCatFamily;

  /// No description provided for @lifeTimelineCatReflection.
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get lifeTimelineCatReflection;

  /// No description provided for @lifeTimelineMoodElated.
  ///
  /// In en, this message translates to:
  /// **'Elated'**
  String get lifeTimelineMoodElated;

  /// No description provided for @lifeTimelineMoodGrounded.
  ///
  /// In en, this message translates to:
  /// **'Grounded'**
  String get lifeTimelineMoodGrounded;

  /// No description provided for @lifeTimelineMoodOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get lifeTimelineMoodOpen;

  /// No description provided for @lifeTimelineMoodPressured.
  ///
  /// In en, this message translates to:
  /// **'Pressured'**
  String get lifeTimelineMoodPressured;

  /// No description provided for @lifeTimelineMoodFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get lifeTimelineMoodFree;

  /// No description provided for @lifeTimelineMoodCleansed.
  ///
  /// In en, this message translates to:
  /// **'Cleansed'**
  String get lifeTimelineMoodCleansed;

  /// No description provided for @lifeTimelineMoodTender.
  ///
  /// In en, this message translates to:
  /// **'Tender'**
  String get lifeTimelineMoodTender;

  /// No description provided for @lifeTimelineMoodResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get lifeTimelineMoodResolved;

  /// No description provided for @lifeTimelineAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Moment'**
  String get lifeTimelineAddTitle;

  /// No description provided for @lifeTimelineAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A turning point worth remembering.'**
  String get lifeTimelineAddSubtitle;

  /// No description provided for @lifeTimelineFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get lifeTimelineFieldTitle;

  /// No description provided for @lifeTimelineFieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Got the offer'**
  String get lifeTimelineFieldTitleHint;

  /// No description provided for @lifeTimelineFieldWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get lifeTimelineFieldWhen;

  /// No description provided for @lifeTimelineFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get lifeTimelineFieldCategory;

  /// No description provided for @lifeTimelineFieldMood.
  ///
  /// In en, this message translates to:
  /// **'How did it feel?'**
  String get lifeTimelineFieldMood;

  /// No description provided for @lifeTimelineFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get lifeTimelineFieldNotes;

  /// No description provided for @lifeTimelineFieldNotesHint.
  ///
  /// In en, this message translates to:
  /// **'What was happening, what shifted...'**
  String get lifeTimelineFieldNotesHint;

  /// No description provided for @lifeTimelineSaveMoment.
  ///
  /// In en, this message translates to:
  /// **'Save Moment'**
  String get lifeTimelineSaveMoment;

  /// No description provided for @lifeTimelineTransitPending.
  ///
  /// In en, this message translates to:
  /// **'Transit calculation pending'**
  String get lifeTimelineTransitPending;

  /// No description provided for @lifeTimelineMock1Title.
  ///
  /// In en, this message translates to:
  /// **'Got the offer'**
  String get lifeTimelineMock1Title;

  /// No description provided for @lifeTimelineMock1Desc.
  ///
  /// In en, this message translates to:
  /// **'Accepted the senior role at the design studio. Felt like everything I\'ve worked toward suddenly clicked into place.'**
  String get lifeTimelineMock1Desc;

  /// No description provided for @lifeTimelineMock1Transit1.
  ///
  /// In en, this message translates to:
  /// **'Jupiter trine natal MC'**
  String get lifeTimelineMock1Transit1;

  /// No description provided for @lifeTimelineMock1Transit2.
  ///
  /// In en, this message translates to:
  /// **'Venus in 10th house'**
  String get lifeTimelineMock1Transit2;

  /// No description provided for @lifeTimelineMock2Title.
  ///
  /// In en, this message translates to:
  /// **'Cancer New Moon retreat'**
  String get lifeTimelineMock2Title;

  /// No description provided for @lifeTimelineMock2Desc.
  ///
  /// In en, this message translates to:
  /// **'Three days off-grid in Joshua Tree. Wrote 40 pages of journal. Came back with clarity about what I actually want.'**
  String get lifeTimelineMock2Desc;

  /// No description provided for @lifeTimelineMock2Transit1.
  ///
  /// In en, this message translates to:
  /// **'New Moon conjunct natal Moon'**
  String get lifeTimelineMock2Transit1;

  /// No description provided for @lifeTimelineMock2Transit2.
  ///
  /// In en, this message translates to:
  /// **'Mercury retrograde in 4th'**
  String get lifeTimelineMock2Transit2;

  /// No description provided for @lifeTimelineMock3Title.
  ///
  /// In en, this message translates to:
  /// **'Met Theo'**
  String get lifeTimelineMock3Title;

  /// No description provided for @lifeTimelineMock3Desc.
  ///
  /// In en, this message translates to:
  /// **'Coffee at 4pm became dinner became a long walk. Felt the kind of recognition you can\'t fake.'**
  String get lifeTimelineMock3Desc;

  /// No description provided for @lifeTimelineMock3Transit1.
  ///
  /// In en, this message translates to:
  /// **'Venus trine natal Sun'**
  String get lifeTimelineMock3Transit1;

  /// No description provided for @lifeTimelineMock3Transit2.
  ///
  /// In en, this message translates to:
  /// **'Sun in 7th house'**
  String get lifeTimelineMock3Transit2;

  /// No description provided for @lifeTimelineMock4Title.
  ///
  /// In en, this message translates to:
  /// **'Saturn return begins'**
  String get lifeTimelineMock4Title;

  /// No description provided for @lifeTimelineMock4Desc.
  ///
  /// In en, this message translates to:
  /// **'The first wave hit. Re-evaluating every commitment. Starting to feel which structures need to come down.'**
  String get lifeTimelineMock4Desc;

  /// No description provided for @lifeTimelineMock4Transit1.
  ///
  /// In en, this message translates to:
  /// **'Saturn conjunct natal Saturn (1st pass)'**
  String get lifeTimelineMock4Transit1;

  /// No description provided for @lifeTimelineMock5Title.
  ///
  /// In en, this message translates to:
  /// **'Trip to Lisbon'**
  String get lifeTimelineMock5Title;

  /// No description provided for @lifeTimelineMock5Desc.
  ///
  /// In en, this message translates to:
  /// **'Two weeks alone with my notebook. Realised how much of my anxiety was just being too plugged in.'**
  String get lifeTimelineMock5Desc;

  /// No description provided for @lifeTimelineMock5Transit1.
  ///
  /// In en, this message translates to:
  /// **'Jupiter in 9th house'**
  String get lifeTimelineMock5Transit1;

  /// No description provided for @lifeTimelineMock5Transit2.
  ///
  /// In en, this message translates to:
  /// **'Mars trine Mercury'**
  String get lifeTimelineMock5Transit2;

  /// No description provided for @lifeTimelineMock6Title.
  ///
  /// In en, this message translates to:
  /// **'Ended the lease'**
  String get lifeTimelineMock6Title;

  /// No description provided for @lifeTimelineMock6Desc.
  ///
  /// In en, this message translates to:
  /// **'Moved out of the apartment. Decided I needed less space and fewer attachments. Saturn was right.'**
  String get lifeTimelineMock6Desc;

  /// No description provided for @lifeTimelineMock6Transit1.
  ///
  /// In en, this message translates to:
  /// **'Saturn square natal Moon'**
  String get lifeTimelineMock6Transit1;

  /// No description provided for @lifeTimelineMock6Transit2.
  ///
  /// In en, this message translates to:
  /// **'Pluto opposite natal Venus'**
  String get lifeTimelineMock6Transit2;

  /// No description provided for @destinyMatrixTitle.
  ///
  /// In en, this message translates to:
  /// **'Matrix of Destiny'**
  String get destinyMatrixTitle;

  /// No description provided for @destinyYourOctagram.
  ///
  /// In en, this message translates to:
  /// **'Your Octagram'**
  String get destinyYourOctagram;

  /// No description provided for @destinyPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get destinyPurpose;

  /// No description provided for @destinyTheLines.
  ///
  /// In en, this message translates to:
  /// **'The Lines'**
  String get destinyTheLines;

  /// No description provided for @destinyYourCoreArcana.
  ///
  /// In en, this message translates to:
  /// **'YOUR CORE ARCANA'**
  String get destinyYourCoreArcana;

  /// No description provided for @destinyBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date {date}'**
  String destinyBirthDate(String date);

  /// No description provided for @destinyComfortCore.
  ///
  /// In en, this message translates to:
  /// **'Comfort / Core'**
  String get destinyComfortCore;

  /// No description provided for @destinyMaleGenerationLine.
  ///
  /// In en, this message translates to:
  /// **'male generation line'**
  String get destinyMaleGenerationLine;

  /// No description provided for @destinyFemaleGenerationLine.
  ///
  /// In en, this message translates to:
  /// **'female generation line'**
  String get destinyFemaleGenerationLine;

  /// No description provided for @destinyTapNodeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any node to read its arcana.'**
  String get destinyTapNodeHint;

  /// No description provided for @destinyArcanaNumber.
  ///
  /// In en, this message translates to:
  /// **'Arcana {n}'**
  String destinyArcanaNumber(int n);

  /// No description provided for @destinySkyPurpose.
  ///
  /// In en, this message translates to:
  /// **'Sky Purpose'**
  String get destinySkyPurpose;

  /// No description provided for @destinyEarthPurpose.
  ///
  /// In en, this message translates to:
  /// **'Earth Purpose'**
  String get destinyEarthPurpose;

  /// No description provided for @destinyPersonalPurpose.
  ///
  /// In en, this message translates to:
  /// **'Personal Purpose'**
  String get destinyPersonalPurpose;

  /// No description provided for @psychoTitle.
  ///
  /// In en, this message translates to:
  /// **'Pythagoras Square'**
  String get psychoTitle;

  /// No description provided for @psychoYourMatrix.
  ///
  /// In en, this message translates to:
  /// **'Your Matrix'**
  String get psychoYourMatrix;

  /// No description provided for @psychoLinesStrengths.
  ///
  /// In en, this message translates to:
  /// **'Lines & Strengths'**
  String get psychoLinesStrengths;

  /// No description provided for @psychoWorkingNumbers.
  ///
  /// In en, this message translates to:
  /// **'WORKING NUMBERS'**
  String get psychoWorkingNumbers;

  /// No description provided for @psychoBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date {date}'**
  String psychoBirthDate(String date);

  /// No description provided for @psychoWorkingShort.
  ///
  /// In en, this message translates to:
  /// **'W{n}'**
  String psychoWorkingShort(int n);

  /// No description provided for @psychoTapCellHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any cell to read its meaning.'**
  String get psychoTapCellHint;

  /// No description provided for @psychoAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get psychoAbsent;

  /// No description provided for @psychoCellCount.
  ///
  /// In en, this message translates to:
  /// **'{digits}  ·  {count}x'**
  String psychoCellCount(String digits, int count);

  /// No description provided for @psychoCellsList.
  ///
  /// In en, this message translates to:
  /// **'Cells {cells}'**
  String psychoCellsList(String cells);

  /// No description provided for @numerologyCompatPartnerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'PARTNER FULL BIRTH NAME'**
  String get numerologyCompatPartnerNameLabel;

  /// No description provided for @numerologyCompatPartnerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sarah Anne Chen'**
  String get numerologyCompatPartnerNameHint;

  /// No description provided for @numerologyCompatPartnerBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'PARTNER BIRTH DATE'**
  String get numerologyCompatPartnerBirthDateLabel;

  /// No description provided for @numerologyCompatTapToPick.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick'**
  String get numerologyCompatTapToPick;

  /// No description provided for @numerologyCompatCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get numerologyCompatCalculating;

  /// No description provided for @numerologyCompatCompute.
  ///
  /// In en, this message translates to:
  /// **'Compute compatibility'**
  String get numerologyCompatCompute;

  /// No description provided for @numerologyCompatMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get numerologyCompatMatch;

  /// No description provided for @numerologyKarmicLessonsHeader.
  ///
  /// In en, this message translates to:
  /// **'KARMIC LESSONS'**
  String get numerologyKarmicLessonsHeader;

  /// No description provided for @numerologyKarmicNoneMissing.
  ///
  /// In en, this message translates to:
  /// **'Your name carries every digit — no missing lessons.'**
  String get numerologyKarmicNoneMissing;

  /// No description provided for @numerologyKarmicMissingBlurb.
  ///
  /// In en, this message translates to:
  /// **'Numbers missing from your name show areas you came to learn.'**
  String get numerologyKarmicMissingBlurb;

  /// No description provided for @numerologyHiddenPassionHeader.
  ///
  /// In en, this message translates to:
  /// **'HIDDEN PASSION'**
  String get numerologyHiddenPassionHeader;

  /// No description provided for @numerologyHiddenPassionNone.
  ///
  /// In en, this message translates to:
  /// **'No dominant digit — your name is balanced across the spectrum.'**
  String get numerologyHiddenPassionNone;

  /// No description provided for @numerologyHiddenPassionBlurb.
  ///
  /// In en, this message translates to:
  /// **'Your strongest gift is the energy of {number} — the digit that appears most often in your name.'**
  String numerologyHiddenPassionBlurb(int number);

  /// No description provided for @numerologyTodayHeader.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get numerologyTodayHeader;

  /// No description provided for @numerologyPersonalYear.
  ///
  /// In en, this message translates to:
  /// **'Personal Year'**
  String get numerologyPersonalYear;

  /// No description provided for @numerologyPersonalMonth.
  ///
  /// In en, this message translates to:
  /// **'Personal Month'**
  String get numerologyPersonalMonth;

  /// No description provided for @numerologyPersonalDay.
  ///
  /// In en, this message translates to:
  /// **'Personal Day'**
  String get numerologyPersonalDay;

  /// No description provided for @numerologyPinnaclesHeader.
  ///
  /// In en, this message translates to:
  /// **'PINNACLES — life\'s themes'**
  String get numerologyPinnaclesHeader;

  /// No description provided for @numerologyPinnacleN.
  ///
  /// In en, this message translates to:
  /// **'Pinnacle {n}'**
  String numerologyPinnacleN(int n);

  /// No description provided for @numerologyChallengesHeader.
  ///
  /// In en, this message translates to:
  /// **'CHALLENGES — areas to grow'**
  String get numerologyChallengesHeader;

  /// No description provided for @numerologyChallengeN.
  ///
  /// In en, this message translates to:
  /// **'Challenge {n}'**
  String numerologyChallengeN(int n);

  /// No description provided for @numerologyCurrentAgeNote.
  ///
  /// In en, this message translates to:
  /// **'You are {age} — active cycle is highlighted.'**
  String numerologyCurrentAgeNote(int age);

  /// No description provided for @numerologyAgeFrom.
  ///
  /// In en, this message translates to:
  /// **'age {start}+'**
  String numerologyAgeFrom(int start);

  /// No description provided for @numerologyAgeRange.
  ///
  /// In en, this message translates to:
  /// **'ages {start}–{end}'**
  String numerologyAgeRange(int start, int end);

  /// No description provided for @numerologyNowBadge.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get numerologyNowBadge;

  /// No description provided for @numerologyMasterChip.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get numerologyMasterChip;

  /// No description provided for @numerologyKarmicChip.
  ///
  /// In en, this message translates to:
  /// **'Karmic {number}'**
  String numerologyKarmicChip(int number);

  /// No description provided for @hdYouAre.
  ///
  /// In en, this message translates to:
  /// **'YOU ARE'**
  String get hdYouAre;

  /// No description provided for @hdStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get hdStrategy;

  /// No description provided for @hdAuthority.
  ///
  /// In en, this message translates to:
  /// **'Authority'**
  String get hdAuthority;

  /// No description provided for @hdDefinition.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get hdDefinition;

  /// No description provided for @hdNotSelfTheme.
  ///
  /// In en, this message translates to:
  /// **'Not-self theme: {theme}'**
  String hdNotSelfTheme(String theme);

  /// No description provided for @hdVariablesHeader.
  ///
  /// In en, this message translates to:
  /// **'VARIABLES (PRA)'**
  String get hdVariablesHeader;

  /// No description provided for @hdVarDigestion.
  ///
  /// In en, this message translates to:
  /// **'Digestion'**
  String get hdVarDigestion;

  /// No description provided for @hdVarEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get hdVarEnvironment;

  /// No description provided for @hdVarAwareness.
  ///
  /// In en, this message translates to:
  /// **'Awareness'**
  String get hdVarAwareness;

  /// No description provided for @hdVarPerspective.
  ///
  /// In en, this message translates to:
  /// **'Perspective'**
  String get hdVarPerspective;

  /// No description provided for @hdDirectionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get hdDirectionLeft;

  /// No description provided for @hdDirectionRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get hdDirectionRight;

  /// No description provided for @hdCenterDefinedBadge.
  ///
  /// In en, this message translates to:
  /// **'DEFINED'**
  String get hdCenterDefinedBadge;

  /// No description provided for @hdCenterOpenBadge.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get hdCenterOpenBadge;

  /// No description provided for @hdGateN.
  ///
  /// In en, this message translates to:
  /// **'Gate {n}'**
  String hdGateN(int n);

  /// No description provided for @hdIncarnationCross.
  ///
  /// In en, this message translates to:
  /// **'INCARNATION CROSS'**
  String get hdIncarnationCross;

  /// No description provided for @hdQuarterOf.
  ///
  /// In en, this message translates to:
  /// **'Quarter of {quarter}'**
  String hdQuarterOf(String quarter);

  /// No description provided for @hdCrossOf.
  ///
  /// In en, this message translates to:
  /// **'Cross of {gates}'**
  String hdCrossOf(String gates);

  /// No description provided for @hdCrossPersonalitySun.
  ///
  /// In en, this message translates to:
  /// **'P-Sun'**
  String get hdCrossPersonalitySun;

  /// No description provided for @hdCrossPersonalityEarth.
  ///
  /// In en, this message translates to:
  /// **'P-Earth'**
  String get hdCrossPersonalityEarth;

  /// No description provided for @hdCrossDesignSun.
  ///
  /// In en, this message translates to:
  /// **'D-Sun'**
  String get hdCrossDesignSun;

  /// No description provided for @hdCrossDesignEarth.
  ///
  /// In en, this message translates to:
  /// **'D-Earth'**
  String get hdCrossDesignEarth;

  /// No description provided for @hdPersonalityHeader.
  ///
  /// In en, this message translates to:
  /// **'PERSONALITY'**
  String get hdPersonalityHeader;

  /// No description provided for @hdDesignHeader.
  ///
  /// In en, this message translates to:
  /// **'DESIGN'**
  String get hdDesignHeader;

  /// No description provided for @hdTypeManifestor.
  ///
  /// In en, this message translates to:
  /// **'Manifestor'**
  String get hdTypeManifestor;

  /// No description provided for @hdTypeGenerator.
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get hdTypeGenerator;

  /// No description provided for @hdTypeManifestingGenerator.
  ///
  /// In en, this message translates to:
  /// **'Manifesting Generator'**
  String get hdTypeManifestingGenerator;

  /// No description provided for @hdTypeProjector.
  ///
  /// In en, this message translates to:
  /// **'Projector'**
  String get hdTypeProjector;

  /// No description provided for @hdTypeReflector.
  ///
  /// In en, this message translates to:
  /// **'Reflector'**
  String get hdTypeReflector;

  /// No description provided for @hdStrategyInform.
  ///
  /// In en, this message translates to:
  /// **'Inform before acting'**
  String get hdStrategyInform;

  /// No description provided for @hdStrategyRespond.
  ///
  /// In en, this message translates to:
  /// **'Wait to respond'**
  String get hdStrategyRespond;

  /// No description provided for @hdStrategyRespondInform.
  ///
  /// In en, this message translates to:
  /// **'Wait to respond, then inform'**
  String get hdStrategyRespondInform;

  /// No description provided for @hdStrategyInvitation.
  ///
  /// In en, this message translates to:
  /// **'Wait for the invitation'**
  String get hdStrategyInvitation;

  /// No description provided for @hdStrategyLunarCycle.
  ///
  /// In en, this message translates to:
  /// **'Wait a lunar cycle (28 days)'**
  String get hdStrategyLunarCycle;

  /// No description provided for @hdAuthorityEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get hdAuthorityEmotional;

  /// No description provided for @hdAuthoritySacral.
  ///
  /// In en, this message translates to:
  /// **'Sacral'**
  String get hdAuthoritySacral;

  /// No description provided for @hdAuthoritySplenic.
  ///
  /// In en, this message translates to:
  /// **'Splenic'**
  String get hdAuthoritySplenic;

  /// No description provided for @hdAuthorityEgo.
  ///
  /// In en, this message translates to:
  /// **'Ego'**
  String get hdAuthorityEgo;

  /// No description provided for @hdAuthoritySelfProjected.
  ///
  /// In en, this message translates to:
  /// **'Self-Projected'**
  String get hdAuthoritySelfProjected;

  /// No description provided for @hdAuthorityMental.
  ///
  /// In en, this message translates to:
  /// **'Mental'**
  String get hdAuthorityMental;

  /// No description provided for @hdAuthorityLunar.
  ///
  /// In en, this message translates to:
  /// **'Lunar'**
  String get hdAuthorityLunar;

  /// No description provided for @hdDefinitionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hdDefinitionNone;

  /// No description provided for @hdDefinitionSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get hdDefinitionSingle;

  /// No description provided for @hdDefinitionSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get hdDefinitionSplit;

  /// No description provided for @hdDefinitionTripleSplit.
  ///
  /// In en, this message translates to:
  /// **'Triple Split'**
  String get hdDefinitionTripleSplit;

  /// No description provided for @hdDefinitionQuadrupleSplit.
  ///
  /// In en, this message translates to:
  /// **'Quadruple Split'**
  String get hdDefinitionQuadrupleSplit;

  /// No description provided for @hdNotSelfAnger.
  ///
  /// In en, this message translates to:
  /// **'Anger'**
  String get hdNotSelfAnger;

  /// No description provided for @hdNotSelfFrustration.
  ///
  /// In en, this message translates to:
  /// **'Frustration'**
  String get hdNotSelfFrustration;

  /// No description provided for @hdNotSelfFrustrationAnger.
  ///
  /// In en, this message translates to:
  /// **'Frustration & Anger'**
  String get hdNotSelfFrustrationAnger;

  /// No description provided for @hdNotSelfBitterness.
  ///
  /// In en, this message translates to:
  /// **'Bitterness'**
  String get hdNotSelfBitterness;

  /// No description provided for @hdNotSelfDisappointment.
  ///
  /// In en, this message translates to:
  /// **'Disappointment'**
  String get hdNotSelfDisappointment;

  /// No description provided for @hdCenterHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get hdCenterHead;

  /// No description provided for @hdCenterAjna.
  ///
  /// In en, this message translates to:
  /// **'Ajna'**
  String get hdCenterAjna;

  /// No description provided for @hdCenterThroat.
  ///
  /// In en, this message translates to:
  /// **'Throat'**
  String get hdCenterThroat;

  /// No description provided for @hdCenterG.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get hdCenterG;

  /// No description provided for @hdCenterHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get hdCenterHeart;

  /// No description provided for @hdCenterSacral.
  ///
  /// In en, this message translates to:
  /// **'Sacral'**
  String get hdCenterSacral;

  /// No description provided for @hdCenterSolarPlexus.
  ///
  /// In en, this message translates to:
  /// **'Solar Plexus'**
  String get hdCenterSolarPlexus;

  /// No description provided for @hdCenterSpleen.
  ///
  /// In en, this message translates to:
  /// **'Spleen'**
  String get hdCenterSpleen;

  /// No description provided for @hdCenterRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get hdCenterRoot;

  /// No description provided for @hdCenterThemeHead.
  ///
  /// In en, this message translates to:
  /// **'Inspiration · pressure to know'**
  String get hdCenterThemeHead;

  /// No description provided for @hdCenterThemeAjna.
  ///
  /// In en, this message translates to:
  /// **'Conceptualization · certainty vs doubt'**
  String get hdCenterThemeAjna;

  /// No description provided for @hdCenterThemeThroat.
  ///
  /// In en, this message translates to:
  /// **'Manifestation · expression'**
  String get hdCenterThemeThroat;

  /// No description provided for @hdCenterThemeG.
  ///
  /// In en, this message translates to:
  /// **'Identity · love · direction'**
  String get hdCenterThemeG;

  /// No description provided for @hdCenterThemeHeart.
  ///
  /// In en, this message translates to:
  /// **'Willpower · ego · resources'**
  String get hdCenterThemeHeart;

  /// No description provided for @hdCenterThemeSacral.
  ///
  /// In en, this message translates to:
  /// **'Life force · sustainable work · sexuality'**
  String get hdCenterThemeSacral;

  /// No description provided for @hdCenterThemeSolarPlexus.
  ///
  /// In en, this message translates to:
  /// **'Emotional wave · feelings · clarity'**
  String get hdCenterThemeSolarPlexus;

  /// No description provided for @hdCenterThemeSpleen.
  ///
  /// In en, this message translates to:
  /// **'Intuition · health · survival'**
  String get hdCenterThemeSpleen;

  /// No description provided for @hdCenterThemeRoot.
  ///
  /// In en, this message translates to:
  /// **'Pressure · adrenaline · drive'**
  String get hdCenterThemeRoot;

  /// No description provided for @hdQuarterInitiation.
  ///
  /// In en, this message translates to:
  /// **'Initiation'**
  String get hdQuarterInitiation;

  /// No description provided for @hdQuarterCivilization.
  ///
  /// In en, this message translates to:
  /// **'Civilization'**
  String get hdQuarterCivilization;

  /// No description provided for @hdQuarterDuality.
  ///
  /// In en, this message translates to:
  /// **'Duality'**
  String get hdQuarterDuality;

  /// No description provided for @hdQuarterMutation.
  ///
  /// In en, this message translates to:
  /// **'Mutation'**
  String get hdQuarterMutation;

  /// No description provided for @hdBodySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get hdBodySun;

  /// No description provided for @hdBodyEarth.
  ///
  /// In en, this message translates to:
  /// **'Earth'**
  String get hdBodyEarth;

  /// No description provided for @hdBodyNorthNode.
  ///
  /// In en, this message translates to:
  /// **'North Node'**
  String get hdBodyNorthNode;

  /// No description provided for @hdBodySouthNode.
  ///
  /// In en, this message translates to:
  /// **'South Node'**
  String get hdBodySouthNode;

  /// No description provided for @hdBodyMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get hdBodyMoon;

  /// No description provided for @hdBodyMercury.
  ///
  /// In en, this message translates to:
  /// **'Mercury'**
  String get hdBodyMercury;

  /// No description provided for @hdBodyVenus.
  ///
  /// In en, this message translates to:
  /// **'Venus'**
  String get hdBodyVenus;

  /// No description provided for @hdBodyMars.
  ///
  /// In en, this message translates to:
  /// **'Mars'**
  String get hdBodyMars;

  /// No description provided for @hdBodyJupiter.
  ///
  /// In en, this message translates to:
  /// **'Jupiter'**
  String get hdBodyJupiter;

  /// No description provided for @hdBodySaturn.
  ///
  /// In en, this message translates to:
  /// **'Saturn'**
  String get hdBodySaturn;

  /// No description provided for @hdBodyUranus.
  ///
  /// In en, this message translates to:
  /// **'Uranus'**
  String get hdBodyUranus;

  /// No description provided for @hdBodyNeptune.
  ///
  /// In en, this message translates to:
  /// **'Neptune'**
  String get hdBodyNeptune;

  /// No description provided for @hdBodyPluto.
  ///
  /// In en, this message translates to:
  /// **'Pluto'**
  String get hdBodyPluto;

  /// No description provided for @hdChannelInspiration.
  ///
  /// In en, this message translates to:
  /// **'Inspiration'**
  String get hdChannelInspiration;

  /// No description provided for @hdChannelTheBeat.
  ///
  /// In en, this message translates to:
  /// **'The Beat'**
  String get hdChannelTheBeat;

  /// No description provided for @hdChannelMutation.
  ///
  /// In en, this message translates to:
  /// **'Mutation'**
  String get hdChannelMutation;

  /// No description provided for @hdChannelLogic.
  ///
  /// In en, this message translates to:
  /// **'Logic'**
  String get hdChannelLogic;

  /// No description provided for @hdChannelRhythm.
  ///
  /// In en, this message translates to:
  /// **'Rhythm'**
  String get hdChannelRhythm;

  /// No description provided for @hdChannelMating.
  ///
  /// In en, this message translates to:
  /// **'Mating'**
  String get hdChannelMating;

  /// No description provided for @hdChannelAlpha.
  ///
  /// In en, this message translates to:
  /// **'Alpha (Leadership)'**
  String get hdChannelAlpha;

  /// No description provided for @hdChannelConcentration.
  ///
  /// In en, this message translates to:
  /// **'Concentration'**
  String get hdChannelConcentration;

  /// No description provided for @hdChannelAwakening.
  ///
  /// In en, this message translates to:
  /// **'Awakening'**
  String get hdChannelAwakening;

  /// No description provided for @hdChannelExploration.
  ///
  /// In en, this message translates to:
  /// **'Exploration'**
  String get hdChannelExploration;

  /// No description provided for @hdChannelPerfectedForm.
  ///
  /// In en, this message translates to:
  /// **'Perfected Form'**
  String get hdChannelPerfectedForm;

  /// No description provided for @hdChannelCuriosity.
  ///
  /// In en, this message translates to:
  /// **'Curiosity'**
  String get hdChannelCuriosity;

  /// No description provided for @hdChannelOpenness.
  ///
  /// In en, this message translates to:
  /// **'Openness'**
  String get hdChannelOpenness;

  /// No description provided for @hdChannelTheProdigal.
  ///
  /// In en, this message translates to:
  /// **'The Prodigal'**
  String get hdChannelTheProdigal;

  /// No description provided for @hdChannelTheWavelength.
  ///
  /// In en, this message translates to:
  /// **'The Wavelength'**
  String get hdChannelTheWavelength;

  /// No description provided for @hdChannelAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Acceptance'**
  String get hdChannelAcceptance;

  /// No description provided for @hdChannelJudgement.
  ///
  /// In en, this message translates to:
  /// **'Judgement'**
  String get hdChannelJudgement;

  /// No description provided for @hdChannelSynthesis.
  ///
  /// In en, this message translates to:
  /// **'Synthesis'**
  String get hdChannelSynthesis;

  /// No description provided for @hdChannelCharisma.
  ///
  /// In en, this message translates to:
  /// **'Charisma'**
  String get hdChannelCharisma;

  /// No description provided for @hdChannelTheBrainWave.
  ///
  /// In en, this message translates to:
  /// **'The Brain Wave'**
  String get hdChannelTheBrainWave;

  /// No description provided for @hdChannelMoneyLine.
  ///
  /// In en, this message translates to:
  /// **'Money Line'**
  String get hdChannelMoneyLine;

  /// No description provided for @hdChannelStructuring.
  ///
  /// In en, this message translates to:
  /// **'Structuring'**
  String get hdChannelStructuring;

  /// No description provided for @hdChannelAwareness.
  ///
  /// In en, this message translates to:
  /// **'Awareness'**
  String get hdChannelAwareness;

  /// No description provided for @hdChannelInitiation.
  ///
  /// In en, this message translates to:
  /// **'Initiation'**
  String get hdChannelInitiation;

  /// No description provided for @hdChannelSurrender.
  ///
  /// In en, this message translates to:
  /// **'Surrender'**
  String get hdChannelSurrender;

  /// No description provided for @hdChannelPreservation.
  ///
  /// In en, this message translates to:
  /// **'Preservation'**
  String get hdChannelPreservation;

  /// No description provided for @hdChannelStruggle.
  ///
  /// In en, this message translates to:
  /// **'Struggle'**
  String get hdChannelStruggle;

  /// No description provided for @hdChannelDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get hdChannelDiscovery;

  /// No description provided for @hdChannelRecognition.
  ///
  /// In en, this message translates to:
  /// **'Recognition'**
  String get hdChannelRecognition;

  /// No description provided for @hdChannelTransformation.
  ///
  /// In en, this message translates to:
  /// **'Transformation'**
  String get hdChannelTransformation;

  /// No description provided for @hdChannelPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get hdChannelPower;

  /// No description provided for @hdChannelTransitoriness.
  ///
  /// In en, this message translates to:
  /// **'Transitoriness'**
  String get hdChannelTransitoriness;

  /// No description provided for @hdChannelCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get hdChannelCommunity;

  /// No description provided for @hdChannelEmoting.
  ///
  /// In en, this message translates to:
  /// **'Emoting'**
  String get hdChannelEmoting;

  /// No description provided for @hdChannelMaturation.
  ///
  /// In en, this message translates to:
  /// **'Maturation'**
  String get hdChannelMaturation;

  /// No description provided for @hdChannelAbstraction.
  ///
  /// In en, this message translates to:
  /// **'Abstraction'**
  String get hdChannelAbstraction;

  /// No description provided for @homeChartPsychomatrix.
  ///
  /// In en, this message translates to:
  /// **'Pythagoras Square'**
  String get homeChartPsychomatrix;

  /// No description provided for @homeChartPsychomatrixSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your psychomatrix by birth date'**
  String get homeChartPsychomatrixSubtitle;

  /// No description provided for @homeChartDestinyMatrix.
  ///
  /// In en, this message translates to:
  /// **'Matrix of Destiny'**
  String get homeChartDestinyMatrix;

  /// No description provided for @homeChartDestinyMatrixSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your 22-arcana octagram'**
  String get homeChartDestinyMatrixSubtitle;

  /// No description provided for @homePremiumPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get homePremiumPlanTitle;

  /// No description provided for @homePremiumPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited AI insights, priority\nbooking, and exclusive content.'**
  String get homePremiumPlanBody;

  /// No description provided for @homePremiumPlanCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get homePremiumPlanCta;

  /// No description provided for @homePopularAstrologers.
  ///
  /// In en, this message translates to:
  /// **'Popular Astrologers'**
  String get homePopularAstrologers;

  /// No description provided for @homeTodaysEnergyLabel.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S ENERGY'**
  String get homeTodaysEnergyLabel;

  /// No description provided for @homeDailyEnergyHeadline.
  ///
  /// In en, this message translates to:
  /// **'A day for inner reflection and creative expression'**
  String get homeDailyEnergyHeadline;

  /// No description provided for @homeDailyEnergyBody.
  ///
  /// In en, this message translates to:
  /// **'The Moon in Pisces heightens your intuition. Trust your instincts today, especially in conversations that matter.'**
  String get homeDailyEnergyBody;

  /// No description provided for @homeModerateEnergy.
  ///
  /// In en, this message translates to:
  /// **'Moderate Energy'**
  String get homeModerateEnergy;

  /// No description provided for @homeQuickAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get homeQuickAiChat;

  /// No description provided for @homeQuickFullChart.
  ///
  /// In en, this message translates to:
  /// **'Full Chart'**
  String get homeQuickFullChart;

  /// No description provided for @homeKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get homeKeepItUp;

  /// No description provided for @homeWeekdayInitialMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get homeWeekdayInitialMon;

  /// No description provided for @homeWeekdayInitialTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get homeWeekdayInitialTue;

  /// No description provided for @homeWeekdayInitialWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get homeWeekdayInitialWed;

  /// No description provided for @homeWeekdayInitialThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get homeWeekdayInitialThu;

  /// No description provided for @homeWeekdayInitialFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get homeWeekdayInitialFri;

  /// No description provided for @homeWeekdayInitialSat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get homeWeekdayInitialSat;

  /// No description provided for @homeWeekdayInitialSun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get homeWeekdayInitialSun;

  /// No description provided for @homeSampleAffirmation.
  ///
  /// In en, this message translates to:
  /// **'I trust the timing of my life. What is meant for me will find me.'**
  String get homeSampleAffirmation;

  /// No description provided for @homeDailyAffirmationLabel.
  ///
  /// In en, this message translates to:
  /// **'DAILY AFFIRMATION'**
  String get homeDailyAffirmationLabel;

  /// No description provided for @skyMoonNew.
  ///
  /// In en, this message translates to:
  /// **'New Moon'**
  String get skyMoonNew;

  /// No description provided for @skyMoonWaxingCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waxing Crescent'**
  String get skyMoonWaxingCrescent;

  /// No description provided for @skyMoonFirstQuarter.
  ///
  /// In en, this message translates to:
  /// **'First Quarter'**
  String get skyMoonFirstQuarter;

  /// No description provided for @skyMoonWaxingGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waxing Gibbous'**
  String get skyMoonWaxingGibbous;

  /// No description provided for @skyMoonFull.
  ///
  /// In en, this message translates to:
  /// **'Full Moon'**
  String get skyMoonFull;

  /// No description provided for @skyMoonWaningGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waning Gibbous'**
  String get skyMoonWaningGibbous;

  /// No description provided for @skyMoonLastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last Quarter'**
  String get skyMoonLastQuarter;

  /// No description provided for @skyMoonWaningCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waning Crescent'**
  String get skyMoonWaningCrescent;

  /// No description provided for @dailyEnergyRingLabel.
  ///
  /// In en, this message translates to:
  /// **'energy'**
  String get dailyEnergyRingLabel;

  /// No description provided for @profileBirthDataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your birth data: {error}'**
  String profileBirthDataLoadError(String error);

  /// No description provided for @ritualsDailyRitualsFeature.
  ///
  /// In en, this message translates to:
  /// **'Daily Rituals'**
  String get ritualsDailyRitualsFeature;

  /// No description provided for @dailyShareText.
  ///
  /// In en, this message translates to:
  /// **'\"{affirmation}\"\n\nMy lucky color today: {color}\n\n~ Lively'**
  String dailyShareText(String affirmation, String color);
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
