// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lively';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose how the app talks to you';

  @override
  String get authWelcome => 'Welcome';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authWelcomeSubtitle => 'Hi, it\'s time for you to sign in.';

  @override
  String get authSignUpSubtitle => 'Hi there, let\'s get you started.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authForgotPassword => 'Forgot Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authRegister => 'Register';

  @override
  String get authOrContinueWith => 'or continue with';

  @override
  String get authContinueGoogle => 'Google';

  @override
  String get authContinueApple => 'Apple';

  @override
  String get authTermsPrefix => 'By continuing, you agree to our ';

  @override
  String get authTerms => 'Terms';

  @override
  String get authAnd => ' and ';

  @override
  String get authPrivacy => 'Privacy Policy';

  @override
  String get authEmailRequired => 'Email and password are required.';

  @override
  String get authPasswordsDontMatch => 'Passwords do not match.';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get spaceLockedTitle => 'Members-only space';

  @override
  String get spaceLockedBody =>
      'Tap Join to request access. The owner will accept or decline your request, and you\'ll get a notification either way.';

  @override
  String get spacePendingTitle => 'Request pending';

  @override
  String get spacePendingBody =>
      'The space owner hasn\'t reviewed your request yet. You\'ll be able to see posts here as soon as they accept.';

  @override
  String get spaceManageRequests => 'Manage join requests';

  @override
  String get spaceRequestsTitle => 'Join requests';

  @override
  String get spaceRequestsEmpty => 'No pending requests right now.';

  @override
  String get spaceRequestsAccept => 'Accept';

  @override
  String get spaceRequestsDecline => 'Decline';

  @override
  String get authResetPasswordTitle => 'Reset your password';

  @override
  String get authResetPasswordBody =>
      'Enter the email address on your account and we\'ll send you a link to set a new password.';

  @override
  String get authResetPasswordSend => 'Send reset link';

  @override
  String authResetPasswordSent(Object email) {
    return 'Check your inbox — we just sent a reset link to $email.';
  }

  @override
  String get authResetPasswordEmailEmpty => 'Please enter your email first.';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Incorrect password.';

  @override
  String get authErrorInvalidCredential => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse =>
      'An account already exists with this email.';

  @override
  String get authErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak. Use at least 8 characters.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authErrorNetwork =>
      'Can\'t reach the server — check your internet connection and try again.';

  @override
  String get authErrorUserDisabled =>
      'This account has been disabled. Contact support.';

  @override
  String get authErrorOperationNotAllowed =>
      'Email sign-in isn\'t enabled for this app. Please contact support.';

  @override
  String get authErrorGeneric => 'Authentication failed. Please try again.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingBirthDateTitle => 'When were you born?';

  @override
  String get onboardingBirthDateSubtitle =>
      'Your birth date is the foundation of your cosmic profile.';

  @override
  String get onboardingBirthTimeTitle => 'What time were you born?';

  @override
  String get onboardingBirthTimeSubtitle =>
      'Your birth time determines your Rising sign and house placements.';

  @override
  String get onboardingBirthPlaceTitle => 'Where were you born?';

  @override
  String get onboardingBirthPlaceSubtitle =>
      'Your birthplace helps us calculate precise planetary positions.';

  @override
  String get onboardingNameTitle => 'What\'s your name?';

  @override
  String get onboardingNameSubtitle =>
      'We\'ll use this to personalize your daily guidance.';

  @override
  String get onboardingNameHint => 'First name';

  @override
  String get onboardingNameReassure =>
      'We\'ll never share this. Change it any time in Profile.';

  @override
  String onboardingFocusCount(int count) {
    return '$count of 3 selected';
  }

  @override
  String get onboardingFocusTitle => 'What matters most to you?';

  @override
  String get onboardingFocusSubtitle =>
      'Select areas you want cosmic guidance on. (Optional)';

  @override
  String get onboardingDontKnowTime => 'I don\'t know my birth time';

  @override
  String get onboardingDontKnowTimeHelp =>
      'We\'ll use approximate calculations. Your Rising sign may differ.';

  @override
  String get onboardingNoTimeNote =>
      'No worries! We can still create a meaningful chart using your date and location.';

  @override
  String get focusLove => 'Love & Relationships';

  @override
  String get focusCareer => 'Career & Purpose';

  @override
  String get focusGrowth => 'Personal Growth';

  @override
  String get focusHealth => 'Health & Wellness';

  @override
  String get focusCreativity => 'Creativity';

  @override
  String get focusSpirituality => 'Spirituality';

  @override
  String get placesSearchHint => 'Search for a city…';

  @override
  String get welcomeHello => 'Welcome,';

  @override
  String get welcomeJourneyBegins => 'Your cosmic journey begins.';

  @override
  String get welcomeStarsAligned => 'The stars have aligned for this moment.';

  @override
  String get welcomeEnter => 'Enter Lively';

  @override
  String get welcomeAligning => 'Aligning the stars…';

  @override
  String welcomeKicker(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get welcomeChartReady => 'Your chart';

  @override
  String get welcomeChartReady2 => 'is ready.';

  @override
  String get welcomeSun => 'Sun';

  @override
  String get welcomeMoon => 'Moon';

  @override
  String get welcomeRising => 'Rising';

  @override
  String get authHeroSignIn => 'The sky,\nmade personal.';

  @override
  String get authHeroSignUp => 'Begin your\ncosmic profile.';

  @override
  String get homeSearchHint => 'Search readings, astrologers, spaces…';

  @override
  String get homeChartsTitle => 'Your Cosmos';

  @override
  String get homeChartsSubtitle => 'Your blueprint and your story.';

  @override
  String get homeChartsSearchHint => 'Search your charts…';

  @override
  String get homeFeaturedDiscussions => 'Featured Discussions';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeTodayInTheSky => 'Today in the Sky';

  @override
  String get homeTodaysInsight => 'Today\'s Insight';

  @override
  String get homeReadMore => 'Read More';

  @override
  String get homeTuneIn => 'Tune in to today\'s celestial currents.';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryDaily => 'Daily';

  @override
  String get categorySky => 'Sky';

  @override
  String get categoryCommunity => 'Community';

  @override
  String get chartCategoryWestern => 'Western';

  @override
  String get chartCategoryVedic => 'Vedic';

  @override
  String get chartCategoryEsoteric => 'Esoteric';

  @override
  String get chartCategoryForecast => 'Forecast';

  @override
  String get navHome => 'Home';

  @override
  String get navCharts => 'Charts';

  @override
  String get navChat => 'Chat';

  @override
  String get navCommunity => 'Community';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileSignOutConfirm =>
      'You will need to sign in again to access your data.';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileBirthData => 'Birth Data';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileBirthDate => 'Birth date';

  @override
  String get profileBirthTime => 'Birth time';

  @override
  String get profileBirthPlace => 'Birthplace';

  @override
  String get profileBirthTimeUnknown => 'Not known';

  @override
  String get profileEditBirthData => 'Edit Birth Data';

  @override
  String get profileSun => 'Sun';

  @override
  String get profileMoon => 'Moon';

  @override
  String get profileRising => 'Rising';

  @override
  String get profileDayStreak => 'Day streak';

  @override
  String get profileJournalEntries => 'Journal entries';

  @override
  String get profileAIChats => 'AI chats';

  @override
  String get profileSubscriptionPremium => 'Premium · Active';

  @override
  String get profileSubscriptionFree => 'Free Plan';

  @override
  String get profileSubscriptionPremiumDesc =>
      'Unlimited insights · priority booking';

  @override
  String get profileSubscriptionFreeDesc =>
      'Upgrade for full access to your chart';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profilePrivacy => 'Privacy';

  @override
  String get profileHelp => 'Help & Support';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileNameLabel => 'NAME';

  @override
  String get profileEmailLabel => 'EMAIL';

  @override
  String get profileEmailNote => 'Email is managed by your sign-in provider.';

  @override
  String get profileSave => 'Save';

  @override
  String get profileNameRequired => 'Name cannot be empty.';

  @override
  String profileSaveError(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get editBirthDataTitle => 'Edit birth data';

  @override
  String get editBirthDateLabel => 'BIRTH DATE';

  @override
  String get editBirthTimeLabel => 'BIRTH TIME';

  @override
  String get editBirthPlaceLabel => 'BIRTHPLACE';

  @override
  String get editSaveChanges => 'Save changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get yourName => 'Your name';

  @override
  String get stargazer => 'Stargazer';

  @override
  String get chartsNothingMatches => 'Nothing matches that yet.';

  @override
  String get chartBadgeNew => 'New';

  @override
  String get chartBirthChart => 'Birth Chart';

  @override
  String get chartBirthChartSubtitle =>
      'Planets, houses, aspects.\nThe map of who you are.';

  @override
  String get chartVedic => 'Vedic Chart';

  @override
  String get chartVedicSubtitle =>
      'Sidereal kundli, nakshatras, dashas,\n16 vargas, yogas — full Jyotish.';

  @override
  String get chartNumerology => 'Numerology';

  @override
  String get chartNumerologySubtitle =>
      'Life path, soul urge, cycles\n+ karmic patterns + compatibility.';

  @override
  String get chartHumanDesign => 'Human Design';

  @override
  String get chartHumanDesignSubtitle =>
      'Type, strategy, authority,\nyour body graph blueprint.';

  @override
  String get chartCosmicTimeline => 'Cosmic Timeline';

  @override
  String get chartCosmicTimelineSubtitle =>
      'Your life mapped against the sky.\nMoments + active transits.';

  @override
  String get chartYearlyForecast => 'Yearly Forecast';

  @override
  String get chartYearlyForecastSubtitle =>
      'What 2026 holds across\nlove, work, and growth.';

  @override
  String get chartTransitForecast => 'Transit Forecast';

  @override
  String get chartTransitForecastSubtitle =>
      'The next 30 days, 3 months,\nand year ahead.';

  @override
  String get aiChatTitle => 'Astrologer';

  @override
  String get aiChatInputHint => 'Ask your astrologer...';

  @override
  String get aiChatLimitReachedHint =>
      'Daily limit reached — upgrade to continue';

  @override
  String aiChatMessagesToday(int used, int limit) {
    return '$used of $limit messages today';
  }

  @override
  String get aiChatLimitReached => 'Daily limit reached';

  @override
  String get aiChatPremiumUnlimited => 'Premium · Unlimited';

  @override
  String get aiChatPaywallTitle => 'You\'ve reached today\'s free limit.';

  @override
  String get aiChatPaywallSubtitle =>
      'Upgrade to Premium for unlimited chat with your astrologer.';

  @override
  String get aiChatStatusOnline => 'Powered by your chart';

  @override
  String get aiChatEmptyHeadline => 'Your personal astrologer';

  @override
  String get aiChatEmptySubtitle =>
      'Ask anything about your chart, transits, dreams, or the day ahead.';

  @override
  String get aiChatSuggestedQuestions => 'Try asking…';

  @override
  String get aiChatPrompt1 => 'What should I focus on today?';

  @override
  String get aiChatPrompt2 => 'Tell me about my Venus placement.';

  @override
  String get aiChatPrompt3 => 'How will this week unfold for me?';

  @override
  String get aiChatPrompt4 => 'What are my biggest strengths?';

  @override
  String get aiChatPrompt5 => 'How can I improve my relationships?';

  @override
  String get aiChatPrompt6 => 'What career paths suit my chart?';

  @override
  String get aiChatYou => 'You';

  @override
  String get aiChatAstrologer => 'Astrologer';

  @override
  String get aiChatThinking => 'Thinking…';

  @override
  String get aiChatRename => 'Rename conversation';

  @override
  String get aiChatDelete => 'Delete conversation';

  @override
  String get avatarChooseFromGallery => 'Choose from gallery';

  @override
  String get avatarTakePhoto => 'Take a photo';

  @override
  String get avatarRemovePhoto => 'Remove photo';

  @override
  String get avatarPickerError => 'Couldn\'t open the picker.';

  @override
  String get avatarSaveError => 'Couldn\'t save photo. Try again.';

  @override
  String get discussionsLoadError => 'Couldn\'t load spaces just now.';

  @override
  String get discussionsEmpty => 'No spaces yet — be the first to start one.';

  @override
  String get discussionsJoined => 'Joined';

  @override
  String discussionsMembersCount(String count) {
    return '$count members';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPremiumActive => 'Premium Active';

  @override
  String get settingsFreePlan => 'Free Plan';

  @override
  String get settingsManageSubscription => 'Manage your subscription';

  @override
  String get settingsUpgrade => 'Upgrade for full access';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsRateApp => 'Rate the App';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsDeleteAccountConfirm =>
      'This will permanently delete your account and all data. This action cannot be undone.';

  @override
  String get settingsDelete => 'Delete';

  @override
  String get settingsAppVersion => 'Lively v1.0.0';

  @override
  String get chatThreadsTitle => 'Astrologer';

  @override
  String get chatThreadsStart => 'Start a Conversation';

  @override
  String get chatThreadsEmpty =>
      'Start a new conversation\nwith your astrologer.';

  @override
  String get chatThreadsNew => 'New chat';

  @override
  String get chatThreadsDelete => 'Delete';

  @override
  String get chatThreadsDeleteConfirm => 'Delete this conversation?';

  @override
  String get chatThreadsUntitled => 'New conversation';

  @override
  String get paywallHeadline => 'Unlock Your Full\nCosmic Potential';

  @override
  String get paywallSubheadline =>
      'Premium gives you unlimited access to every feature.';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String paywallSavePercent(String percent) {
    return 'Save $percent';
  }

  @override
  String get paywallStartFreeTrial => 'Start Free Trial';

  @override
  String get paywallSubscribe => 'Subscribe';

  @override
  String get paywallRestorePurchases => 'Restore purchases';

  @override
  String get paywallTermsNote =>
      'Cancel anytime. Auto-renews unless cancelled.';

  @override
  String get paywallFeatureUnlimitedChat => 'Unlimited AI astrologer chat';

  @override
  String get paywallFeatureFullChart =>
      'Full natal chart with houses + aspects';

  @override
  String get paywallFeatureDailyReading => 'Personalized daily readings';

  @override
  String get paywallFeatureCompatibility => 'Unlimited compatibility reports';

  @override
  String get paywallFeatureNoAds => 'Ad-free experience';

  @override
  String get paywallFeatureExport => 'Export your charts';

  @override
  String get paywallBenefit1Title => 'Full Daily Guidance';

  @override
  String get paywallBenefit1Subtitle =>
      'Detailed love, career, and health insights';

  @override
  String get paywallBenefit2Title => 'Unlimited AI Chat';

  @override
  String get paywallBenefit2Subtitle => 'Ask your personal astrologer anything';

  @override
  String get paywallBenefit3Title => 'Full Compatibility';

  @override
  String get paywallBenefit3Subtitle =>
      'Deep reports for all your relationships';

  @override
  String get paywallBenefit4Title => 'Life Timeline';

  @override
  String get paywallBenefit4Subtitle =>
      '30-day, 3-month, and 12-month forecasts';

  @override
  String get paywallBenefit5Title => 'Yearly Forecast';

  @override
  String get paywallBenefit5Subtitle =>
      'Your cosmic roadmap for the year ahead';

  @override
  String get paywallBenefit6Title => 'Rituals & Journal';

  @override
  String get paywallBenefit6Subtitle =>
      'Daily practices for growth and reflection';

  @override
  String get paywallSaveBadge => 'SAVE 52%';

  @override
  String get paywallTrialIncluded => '3-day free trial included';

  @override
  String get paywallRestoreLong => 'Restore Purchases';

  @override
  String get paywallCancelNote =>
      'Cancel anytime. Subscription renews automatically.';

  @override
  String get dailyReadingTitle => 'Today\'s Reading';

  @override
  String get dailyReadingEnergy => 'Energy';

  @override
  String get dailyReadingEmotional => 'Emotional';

  @override
  String get dailyReadingLove => 'Love & Connection';

  @override
  String get dailyReadingCareer => 'Career & Purpose';

  @override
  String get dailyReadingHealth => 'Health & Wellness';

  @override
  String get dailyReadingCaution => 'Caution';

  @override
  String get dailyReadingAction => 'Action Steps';

  @override
  String get dailyReadingAffirmation => 'Affirmation';

  @override
  String get dailyReadingLuckyColor => 'Lucky Color';

  @override
  String get dailyReadingLuckyNumber => 'Lucky Number';

  @override
  String get dailyReadingSun => 'Sun';

  @override
  String get dailyReadingMoon => 'Moon';

  @override
  String get dailyReadingRising => 'Rising';

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalNewEntry => 'New Entry';

  @override
  String get journalEmpty => 'No entries yet.\nWrite your first reflection.';

  @override
  String get journalPromptHint => 'Today I noticed...';

  @override
  String get journalSaved => 'Saved';

  @override
  String get journalSave => 'Save';

  @override
  String get journalDelete => 'Delete';

  @override
  String get journalDeleteConfirm => 'Delete this entry?';

  @override
  String journalEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0 · capture what the sky meant to you';
  }

  @override
  String get journalCosmicTitle => 'Your Cosmic Journal';

  @override
  String get journalEmptyBlurb =>
      'A private space to write what you noticed,\nfelt, or wondered about today.';

  @override
  String get journalNewMoment => 'A new moment';

  @override
  String get journalEditMoment => 'Edit your moment';

  @override
  String get journalMoodHeader => 'HOW DOES TODAY FEEL?';

  @override
  String get journalPromptHeader => 'OR START FROM A PROMPT';

  @override
  String get journalMoodSuffix => 'mood';

  @override
  String get journalMoodGlad => 'Glad';

  @override
  String get journalMoodCalm => 'Calm';

  @override
  String get journalMoodLoved => 'Loved';

  @override
  String get journalMoodSparkly => 'Sparkly';

  @override
  String get journalMoodCurious => 'Curious';

  @override
  String get journalMoodTired => 'Tired';

  @override
  String get journalMoodHeavy => 'Heavy';

  @override
  String get journalMoodRestless => 'Restless';

  @override
  String get journalPrompt1 => 'What surprised you today?';

  @override
  String get journalPrompt2 => 'Where did you feel most yourself?';

  @override
  String get journalPrompt3 => 'What are you releasing?';

  @override
  String get journalPrompt4 => 'What did the sky feel like today?';

  @override
  String get journalEditorHint =>
      'Write what you noticed, felt, or wondered about today...';

  @override
  String journalSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get todaySkyEnergyHighTitle => 'Energy: high';

  @override
  String get todaySkyEnergyHighBody =>
      'A good day to start something — momentum favors action.';

  @override
  String get todaySkyHeartTitle => 'Heart-forward';

  @override
  String get todaySkyHeartBody =>
      'Venus angles invite warmth in conversation. Reach out.';

  @override
  String get todaySkyMindTitle => 'Mind sharp';

  @override
  String get todaySkyMindBody =>
      'Mercury favors clear thinking. Tackle the hard email.';

  @override
  String get todaySkyPauseTitle => 'Pause before reacting';

  @override
  String get todaySkyPauseBody =>
      'Tense aspect — sleep on big decisions today.';

  @override
  String get todaySkyRestTitle => 'Restorative window';

  @override
  String get todaySkyRestBody =>
      'Soft transits — make time for stillness this evening.';

  @override
  String get todaySkyCreativeTitle => 'Creative spark';

  @override
  String get todaySkyCreativeBody =>
      'Imagination runs high — capture the idea before it fades.';

  @override
  String get todaySkyRecognitionTitle => 'Recognition possible';

  @override
  String get todaySkyRecognitionBody =>
      'Sun-Jupiter trine boosts visibility. Stand in your work.';

  @override
  String get todaySkyNewGroundTitle => 'New ground';

  @override
  String get todaySkyNewGroundBody =>
      'A perspective shift is available. Try a different route home.';

  @override
  String get todaySkyBridgesTitle => 'Bridges, not walls';

  @override
  String get todaySkyBridgesBody =>
      'Diplomatic energy — a hard talk could go better than expected.';

  @override
  String todaySkyIlluminated(String percent) {
    return '$percent% illuminated';
  }

  @override
  String todaySkySunIn(String sign) {
    return 'Sun in $sign';
  }

  @override
  String get compatibilityTitle => 'Compatibility';

  @override
  String get compatibilityAddPerson => 'Add Person';

  @override
  String get compatibilityEmpty => 'Add someone to see how you click.';

  @override
  String get compatibilityViewReport => 'View report';

  @override
  String get compatibilityName => 'Name';

  @override
  String get compatibilityRelationship => 'Relationship';

  @override
  String get compatibilityBirthDate => 'Birth date';

  @override
  String get compatibilityBirthTime => 'Birth time';

  @override
  String get compatibilityBirthPlace => 'Birth place';

  @override
  String get compatibilitySave => 'Save';

  @override
  String compatibilitySavedCount(int count) {
    return '$count saved · explore your synastry';
  }

  @override
  String get compatibilitySeeHow => 'See How You Connect';

  @override
  String get compatibilityEmptyBlurb =>
      'Add a partner, friend, or family member\nand compare your charts.';

  @override
  String get addPersonTitle => 'Add Someone';

  @override
  String get addPersonSubtitle => 'We\'ll compare their chart with yours.';

  @override
  String get addPersonNameLabel => 'Their name';

  @override
  String get addPersonNameHint => 'e.g. Theo Marlow';

  @override
  String get addPersonRelationship => 'Relationship';

  @override
  String get addPersonBirthDate => 'Birth date';

  @override
  String get addPersonBirthTime => 'Birth time';

  @override
  String get addPersonBirthplace => 'Birthplace';

  @override
  String get addPersonGenerate => 'Add & Generate Report';

  @override
  String get addPersonOptional => '(optional)';

  @override
  String get addPersonSelectDate => 'Select a date';

  @override
  String get addPersonSelectTime => 'Select a time';

  @override
  String get addPersonTimeKnown => 'Known';

  @override
  String get addPersonTimeUnknown => 'Unknown';

  @override
  String get compatReportSummary => 'Summary';

  @override
  String get compatReportConflictPatterns => 'Conflict Patterns';

  @override
  String get compatReportAdvice => 'Advice';

  @override
  String get compatScoreMagnetic => 'A magnetic alignment';

  @override
  String get compatScoreEasy => 'Easy, generative energy';

  @override
  String get compatScoreWorthWork => 'Worth the work';

  @override
  String get compatScoreFriction => 'Friction with potential';

  @override
  String get compatScoreOpposites => 'A study in opposites';

  @override
  String get compatDimEmotional => 'Emotional';

  @override
  String get compatDimCommunication => 'Communication';

  @override
  String get compatDimChemistry => 'Chemistry';

  @override
  String get chartScreenTitle => 'Natal Chart';

  @override
  String get chartTabPlanets => 'Planets';

  @override
  String get chartTabHouses => 'Houses';

  @override
  String get chartTabAspects => 'Aspects';

  @override
  String get chartTabElements => 'Elements';

  @override
  String get chartTabSummary => 'Summary';

  @override
  String get chartViewVedic => 'View Vedic Chart';

  @override
  String get chartLegendConjunction => 'Conjunction';

  @override
  String get chartLegendSextile => 'Sextile';

  @override
  String get chartLegendSquare => 'Square';

  @override
  String get chartLegendTrine => 'Trine';

  @override
  String get chartLegendOpposition => 'Opposition';

  @override
  String chartHouseNumber(int n) {
    return 'House $n';
  }

  @override
  String get chartHouse1 => 'Self & Identity';

  @override
  String get chartHouse2 => 'Values & Resources';

  @override
  String get chartHouse3 => 'Communication';

  @override
  String get chartHouse4 => 'Home & Roots';

  @override
  String get chartHouse5 => 'Creativity & Joy';

  @override
  String get chartHouse6 => 'Work & Wellness';

  @override
  String get chartHouse7 => 'Partnerships';

  @override
  String get chartHouse8 => 'Transformation';

  @override
  String get chartHouse9 => 'Philosophy & Travel';

  @override
  String get chartHouse10 => 'Career & Legacy';

  @override
  String get chartHouse11 => 'Community & Vision';

  @override
  String get chartHouse12 => 'Spirit & Surrender';

  @override
  String get chartNoPlanets => 'No planet data';

  @override
  String get chartNoHouses => 'No house data';

  @override
  String get chartNoAspects => 'No aspect data';

  @override
  String get chartNoElements => 'No element data';

  @override
  String chartHouseLine(String sign, String degree) {
    return '$sign · $degree°';
  }

  @override
  String chartAspectOrb(String value) {
    return 'Orb $value°';
  }

  @override
  String get vedicScreenTitle => 'Vedic Chart';

  @override
  String get vedicAyanamsa => 'Ayanamsa';

  @override
  String get vedicTabOverview => 'Overview';

  @override
  String get vedicTabPlanets => 'Planets';

  @override
  String get vedicTabHouses => 'Houses';

  @override
  String get vedicTabBhavas => 'Bhavas';

  @override
  String get vedicTabAspects => 'Aspects';

  @override
  String get vedicTabNakshatras => 'Nakshatras';

  @override
  String get vedicTabVargas => 'Vargas';

  @override
  String get vedicTabDasha => 'Dasha';

  @override
  String get vedicTabYogas => 'Yogas';

  @override
  String get vedicTabShadbala => 'Shadbala';

  @override
  String get vedicTabAshtakavarga => 'Ashtakavarga';

  @override
  String vedicAtmakarakaLabel(String name) {
    return 'Atmakaraka: $name';
  }

  @override
  String vedicChartCaption(String varga, int divisor, String ayanamsa) {
    return '$varga (D$divisor) · $ayanamsa ayanamsa';
  }

  @override
  String get vedicNoAspects => 'No graha-to-graha drishti';

  @override
  String get vedicNoYogas =>
      'No active classical yogas detected for this chart.';

  @override
  String get vedicNoShadbala => 'No Shadbala data';

  @override
  String get vedicVargasNote =>
      'The hero chart above re-renders for the selected Varga. Each divisional chart reveals a different facet of life: D9 marriage and dharma, D10 career, D12 parents, D60 past karma.';

  @override
  String vedicBhavaOccupants(String planets) {
    return 'Occupants: $planets';
  }

  @override
  String vedicBhavaLord(String sign, String sanskrit, String lord) {
    return '$sign ($sanskrit) · Lord $lord';
  }

  @override
  String vedicAspectsLine(String from, String to) {
    return '$from aspects $to';
  }

  @override
  String get vedicRetro => 'Rx';

  @override
  String get vedicCombust => 'Combust';

  @override
  String get numerologyTitle => 'Numerology';

  @override
  String get numerologyTabCore => 'Core';

  @override
  String get numerologyTabToday => 'Today';

  @override
  String get numerologyTabCycles => 'Cycles';

  @override
  String get numerologyTabKarmic => 'Karmic';

  @override
  String get numerologyTabCompat => 'Compat';

  @override
  String get numerologyTabCompatibility => 'Compatibility';

  @override
  String get numerologyCompareWith => 'Compare with someone';

  @override
  String get numerologyNameCalculatorTitle => 'Name Calculator';

  @override
  String get numerologyNameCalculatorBlurb =>
      'Enter any full name to see its Expression, Soul Urge, and Personality numbers — plus the letter-by-letter breakdown.';

  @override
  String get numerologyNameInputHint => 'e.g. Norma Jeane Baker';

  @override
  String get numerologyNameCalculate => 'Calculate';

  @override
  String get numerologyNameOpenCalculator => 'Calculate any name';

  @override
  String get numerologyNameLetterBreakdown => 'Letter breakdown';

  @override
  String get numerologyNameVowels => 'vowels';

  @override
  String get numerologyNameConsonants => 'consonants';

  @override
  String get numerologyNameHiddenPassion => 'Hidden passion';

  @override
  String get numerologyNameKarmicLessons => 'Karmic lessons';

  @override
  String get numerologyNameKarmicLessonsNone =>
      'None — every digit appears in this name.';

  @override
  String get errOfflineTitle => 'You\'re offline';

  @override
  String get errOfflineBody =>
      'Check your connection and try again. Some screens work without a signal, but charts need the sky.';

  @override
  String get errAuthTitle => 'Session expired';

  @override
  String get errAuthBody => 'Sign in again to continue. Your data is safe.';

  @override
  String get errRateLimitTitle => 'Slow down a sec';

  @override
  String get errRateLimitBody =>
      'You\'ve hit a daily limit. Try again later or upgrade to remove the cap.';

  @override
  String get errChatLimitBody =>
      'You\'ve used today\'s free messages with the astrologer. Upgrade to Premium for unlimited chat, or come back tomorrow.';

  @override
  String get errNotFoundTitle => 'Not found';

  @override
  String get errNotFoundBody =>
      'We couldn\'t find what you were looking for. It might have moved or been removed.';

  @override
  String get errServerTitle => 'Something\'s off on our side';

  @override
  String get errServerBody =>
      'Our server is having a moment. We\'re already looking — please try again in a bit.';

  @override
  String get errCacheBody =>
      'We couldn\'t read the local copy. Try again — we\'ll fetch a fresh version.';

  @override
  String get errGenericTitle => 'Something went wrong';

  @override
  String get errGenericBody =>
      'We hit an unexpected error. Tap retry, or restart the app if it keeps happening.';

  @override
  String get errRetry => 'Try again';

  @override
  String get errGoHome => 'Go home';

  @override
  String get errReportProblem => 'Report problem';

  @override
  String get errCrashTitle => 'The cosmos hiccuped';

  @override
  String get errCrashBody =>
      'Something unexpected happened. Restart the app — if it keeps happening, let us know.';

  @override
  String get numerologyLifePathBadge => 'LIFE PATH';

  @override
  String get numerologyMasterBadge => 'MASTER';

  @override
  String get numerologyCoreLifePath => 'Life Path';

  @override
  String get numerologyCoreExpression => 'Expression';

  @override
  String get numerologyCoreSoulUrge => 'Soul Urge';

  @override
  String get numerologyCorePersonality => 'Personality';

  @override
  String get numerologyCoreMaturity => 'Maturity';

  @override
  String get numerologyCoreBirthday => 'Birthday';

  @override
  String get numerologyCompatBlurb =>
      'Enter their full birth name + birth date and we\'ll calculate numerology compatibility for the three relationship-relevant numbers.';

  @override
  String get numerologyOpenCompat => 'Open compatibility';

  @override
  String get humanDesignTitle => 'Human Design';

  @override
  String get humanDesignTabBodyGraph => 'Body Graph';

  @override
  String get humanDesignTabCenters => 'Centers';

  @override
  String get humanDesignTabChannels => 'Channels';

  @override
  String get humanDesignTabGates => 'Gates';

  @override
  String get humanDesignTabProfile => 'Profile';

  @override
  String get humanDesignBodyGraphLegend =>
      'Filled centers are defined; outlined centers are open. Lines are defined channels. Red dots are Personality gates (conscious), cream dots are Design gates (unconscious).';

  @override
  String get humanDesignNoChannels =>
      'No defined channels — you may be a Reflector or have only individual active gates.';

  @override
  String get humanDesignProfileLabel => 'PROFILE';

  @override
  String get humanDesignProfileDesc =>
      'Personality conscious line × Design unconscious line.';

  @override
  String get yearlyForecastTitle => 'Yearly Forecast';

  @override
  String get transitForecastTitle => 'Transit Forecast';

  @override
  String get lifeTimelineTitle => 'Cosmic Timeline';

  @override
  String get ritualsTitle => 'Rituals';

  @override
  String get ritualsTodayTitle => 'Today\'s Rituals';

  @override
  String ritualsStreak(int days) {
    return '$days day streak';
  }

  @override
  String get ritualsTodayHeading => 'Your rituals for today';

  @override
  String get ritualsTodaySubtitle =>
      'Complete these to strengthen your cosmic connection.';

  @override
  String get ritualMorningTitle => 'Morning Intention';

  @override
  String get ritualMorningDesc => 'Set your intention for the day ahead.';

  @override
  String get ritualAffirmationTitle => 'Affirmation';

  @override
  String get ritualAffirmationDesc =>
      'Read and internalize today\'s affirmation.';

  @override
  String get ritualEveningTitle => 'Evening Reflection';

  @override
  String get ritualEveningDesc =>
      'Reflect on your day and note what you\'re grateful for.';

  @override
  String get notifEmptyBlurb =>
      'No notifications yet — when people interact with your spaces, posts, or comments you\'ll see them here.';

  @override
  String get notifGroupToday => 'TODAY';

  @override
  String get notifGroupYesterday => 'YESTERDAY';

  @override
  String get notifGroupThisWeek => 'THIS WEEK';

  @override
  String get notifGroupEarlier => 'EARLIER';

  @override
  String get spacePostsHeader => 'Posts';

  @override
  String get spaceNoPosts => 'No posts yet — be the first.';

  @override
  String get editSpaceLossWarning =>
      'All posts and comments will be permanently lost.';

  @override
  String get editSpaceSaving => 'Saving…';

  @override
  String get editSpaceSave => 'Save';

  @override
  String get editSpaceHandleLabel => 'HANDLE';

  @override
  String get editSpaceNameLabel => 'NAME';

  @override
  String get editSpaceDescLabel => 'DESCRIPTION';

  @override
  String get homeWelcomeBack => 'Welcome Back';

  @override
  String get dailyReadingHeading => 'Your Daily Reading';

  @override
  String get dailyReadingResonant => 'Resonant';

  @override
  String get yfYearTheme => 'YOUR YEAR THEME';

  @override
  String get yfQuarterBreakdown => 'Quarter Breakdown';

  @override
  String get yfHeroSubtitle =>
      'Your cosmic roadmap. One year, four chapters, each with its own weather and weather forecast.';

  @override
  String yfQuarterLabel(int n) {
    return 'Q$n';
  }

  @override
  String get yfNoData => 'No yearly forecast available yet. Check back soon.';

  @override
  String get transit30Days => '30 Days';

  @override
  String get transit3Months => '3 Months';

  @override
  String get transit12Months => '12 Months';

  @override
  String get transitHeroTitle => 'Transit Forecast';

  @override
  String get transitHeroSubtitle =>
      'The sky ahead — pick a window and see when to push, when to wait, and when to listen.';

  @override
  String get transitEnergyPositive => 'Positive';

  @override
  String get transitEnergyChallenging => 'Challenging';

  @override
  String get transitEnergyIntense => 'Intense';

  @override
  String get transitEnergyNeutral => 'Neutral';

  @override
  String get transitNoData => 'No transits charted for this window yet.';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityCreateSpace => 'Create space';

  @override
  String get communityHeroBlurb =>
      'Find your people. Share readings, ask questions, follow the conversations that move you.';

  @override
  String get communityFilterAll => 'All';

  @override
  String get communityFilterJoined => 'Joined';

  @override
  String get communitySpacesEmpty => 'No spaces yet.';

  @override
  String get communityNewPost => 'New post';

  @override
  String get communityWriteSomething => 'Write something...';

  @override
  String get communityPostSubmit => 'Post';

  @override
  String get communityComment => 'Comment';

  @override
  String get communityReply => 'Reply';

  @override
  String get communityLike => 'Like';

  @override
  String get communityShare => 'Share';

  @override
  String get communityJoinSpace => 'Join';

  @override
  String get communityLeaveSpace => 'Leave';

  @override
  String get communityMembers => 'Members';

  @override
  String get communityNotifications => 'Notifications';

  @override
  String get communityNotificationsEmpty => 'Nothing new.';

  @override
  String get communityMarkAllRead => 'Mark all read';

  @override
  String get communityPostTitle => 'Post';

  @override
  String get communityNewSpace => 'New Space';

  @override
  String get communityEditSpace => 'Edit Space';

  @override
  String get communityDeleteSpaceConfirm => 'Delete this space?';

  @override
  String get communityProfile => 'Profile';

  @override
  String get communityCategoriesLabel => 'CATEGORIES';

  @override
  String get communitySearchSpaces => 'Search spaces';

  @override
  String get communityNewPostTitle => 'New post';

  @override
  String get communitySpacesEmptyTap =>
      'No spaces yet — tap + to create the first one.';

  @override
  String get communityComposeHint => 'What\'s on your mind?';

  @override
  String get communityLinkHint => 'Optional link URL';

  @override
  String get communityNotificationsTooltip => 'Notifications';

  @override
  String get communityNewSpaceTooltip => 'New space';

  @override
  String get lifeTimelineAddMoment => 'Add Moment';

  @override
  String lifeTimelineMomentsMapped(int count) {
    return '$count moments mapped';
  }

  @override
  String get lifeTimelineHeaderTitle => 'Your Cosmic Timeline';

  @override
  String get lifeTimelineHeaderSubtitle =>
      'Your life mapped against the sky.\nAdd moments. See what was happening above.';

  @override
  String lifeTimelineFelt(String mood) {
    return 'felt $mood';
  }

  @override
  String get lifeTimelineWhatSky => 'WHAT THE SKY WAS DOING';
}
