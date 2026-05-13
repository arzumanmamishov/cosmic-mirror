// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Lively';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageSubtitle =>
      'Uygulamanın hangi dilde konuşacağını seçin';

  @override
  String get authWelcome => 'Hoş geldin';

  @override
  String get authCreateAccount => 'Hesap oluştur';

  @override
  String get authWelcomeSubtitle => 'Merhaba, giriş zamanı.';

  @override
  String get authSignUpSubtitle => 'Merhaba, hadi başlayalım.';

  @override
  String get authEmail => 'E-posta';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authConfirmPassword => 'Şifreyi doğrula';

  @override
  String get authRememberMe => 'Beni hatırla';

  @override
  String get authForgotPassword => 'Şifremi unuttum';

  @override
  String get authSignIn => 'Giriş yap';

  @override
  String get authNoAccount => 'Hesabın yok mu? ';

  @override
  String get authHaveAccount => 'Zaten bir hesabın var mı? ';

  @override
  String get authRegister => 'Kayıt ol';

  @override
  String get authOrContinueWith => 'veya şununla devam et';

  @override
  String get authContinueGoogle => 'Google';

  @override
  String get authContinueApple => 'Apple';

  @override
  String get authTermsPrefix => 'Devam ederek ';

  @override
  String get authTerms => 'Şartlar';

  @override
  String get authAnd => ' ve ';

  @override
  String get authPrivacy => 'Gizlilik Politikası';

  @override
  String get authEmailRequired => 'E-posta ve şifre gereklidir.';

  @override
  String get authPasswordsDontMatch => 'Şifreler eşleşmiyor.';

  @override
  String get authPasswordTooShort => 'Şifre en az 8 karakter olmalıdır.';

  @override
  String get authResetPasswordTitle => 'Şifreni sıfırla';

  @override
  String get authResetPasswordBody =>
      'Hesabındaki e-posta adresini gir, sana yeni bir şifre belirlemen için bir bağlantı gönderelim.';

  @override
  String get authResetPasswordSend => 'Sıfırlama bağlantısı gönder';

  @override
  String authResetPasswordSent(Object email) {
    return 'Gelen kutunu kontrol et — $email adresine sıfırlama bağlantısı gönderdik.';
  }

  @override
  String get authResetPasswordEmailEmpty => 'Lütfen önce e-posta adresini gir.';

  @override
  String get authCancel => 'Vazgeç';

  @override
  String get authErrorUserNotFound => 'Bu e-posta ile bir hesap bulunamadı.';

  @override
  String get authErrorWrongPassword => 'Şifre hatalı.';

  @override
  String get authErrorInvalidCredential => 'E-posta veya şifre hatalı.';

  @override
  String get authErrorEmailInUse => 'Bu e-posta ile zaten bir hesap var.';

  @override
  String get authErrorInvalidEmail => 'Lütfen geçerli bir e-posta adresi gir.';

  @override
  String get authErrorWeakPassword =>
      'Şifre çok zayıf. En az 8 karakter kullan.';

  @override
  String get authErrorTooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.';

  @override
  String get authErrorNetwork =>
      'Sunucuya ulaşılamıyor — internet bağlantını kontrol edip tekrar dene.';

  @override
  String get authErrorUserDisabled =>
      'Bu hesap devre dışı bırakılmış. Lütfen destekle iletişime geç.';

  @override
  String get authErrorOperationNotAllowed =>
      'E-posta ile giriş bu uygulamada etkin değil. Lütfen destekle iletişime geç.';

  @override
  String get authErrorGeneric =>
      'Kimlik doğrulama başarısız. Lütfen tekrar dene.';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingContinue => 'Devam et';

  @override
  String get onboardingBirthDateTitle => 'Ne zaman doğdun?';

  @override
  String get onboardingBirthDateSubtitle =>
      'Doğum tarihin kozmik profilinin temelidir.';

  @override
  String get onboardingBirthTimeTitle => 'Hangi saatte doğdun?';

  @override
  String get onboardingBirthTimeSubtitle =>
      'Doğum saatin Yükselen burcunu ve ev yerleşimlerini belirler.';

  @override
  String get onboardingBirthPlaceTitle => 'Nerede doğdun?';

  @override
  String get onboardingBirthPlaceSubtitle =>
      'Doğum yerin gezegen konumlarını hassas hesaplamamıza yardımcı olur.';

  @override
  String get onboardingNameTitle => 'Adın ne?';

  @override
  String get onboardingNameSubtitle =>
      'Bunu sana özel rehberliği kişiselleştirmek için kullanacağız.';

  @override
  String get onboardingNameHint => 'Adın';

  @override
  String get onboardingFocusTitle => 'Senin için en önemli olan ne?';

  @override
  String get onboardingFocusSubtitle =>
      'Kozmik rehberlik istediğin alanları seç. (İsteğe bağlı)';

  @override
  String get onboardingDontKnowTime => 'Doğum saatimi bilmiyorum';

  @override
  String get onboardingDontKnowTimeHelp =>
      'Yaklaşık hesaplamalar kullanacağız. Yükselen burcun değişebilir.';

  @override
  String get onboardingNoTimeNote =>
      'Sorun değil! Tarih ve konumunla yine de anlamlı bir harita oluşturabiliriz.';

  @override
  String get focusLove => 'Aşk ve İlişkiler';

  @override
  String get focusCareer => 'Kariyer ve Amaç';

  @override
  String get focusGrowth => 'Kişisel Gelişim';

  @override
  String get focusHealth => 'Sağlık ve Esenlik';

  @override
  String get focusCreativity => 'Yaratıcılık';

  @override
  String get focusSpirituality => 'Maneviyat';

  @override
  String get placesSearchHint => 'Şehir ara…';

  @override
  String get welcomeHello => 'Hoş geldin,';

  @override
  String get welcomeJourneyBegins => 'Kozmik yolculuğun başlıyor.';

  @override
  String get welcomeStarsAligned => 'Yıldızlar bu an için hizalandı.';

  @override
  String get welcomeEnter => 'Kozmosuna Gir';

  @override
  String get welcomeAligning => 'Yıldızlar hizalanıyor…';

  @override
  String get homeSearchHint => 'Okuma, astrolog, alan ara…';

  @override
  String get homeChartsTitle => 'Senin Kozmosun';

  @override
  String get homeChartsSubtitle => 'Haritan ve hikâyen.';

  @override
  String get homeChartsSearchHint => 'Haritalarda ara…';

  @override
  String get homeFeaturedDiscussions => 'Öne Çıkan Tartışmalar';

  @override
  String get homeSeeAll => 'Tümünü gör';

  @override
  String get homeTodayInTheSky => 'Bugün Gökyüzünde';

  @override
  String get homeTodaysInsight => 'Bugünün Öngörüsü';

  @override
  String get homeReadMore => 'Devamını oku';

  @override
  String get homeTuneIn => 'Bugünün gök akışlarına kulak ver.';

  @override
  String get categoryAll => 'Tümü';

  @override
  String get categoryDaily => 'Günlük';

  @override
  String get categorySky => 'Gökyüzü';

  @override
  String get categoryCommunity => 'Topluluk';

  @override
  String get chartCategoryWestern => 'Batı';

  @override
  String get chartCategoryVedic => 'Vedik';

  @override
  String get chartCategoryEsoteric => 'Ezoterik';

  @override
  String get chartCategoryForecast => 'Öngörü';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navCharts => 'Haritalar';

  @override
  String get navChat => 'Sohbet';

  @override
  String get navCommunity => 'Topluluk';

  @override
  String get profileSignOut => 'Çıkış yap';

  @override
  String get profileSignOutConfirm =>
      'Verilerine erişmek için tekrar giriş yapman gerekecek.';

  @override
  String get profileEditProfile => 'Profili düzenle';

  @override
  String get profileEdit => 'Düzenle';

  @override
  String get profileBirthData => 'Doğum Bilgileri';

  @override
  String get profileAccount => 'Hesap';

  @override
  String get profileBirthDate => 'Doğum tarihi';

  @override
  String get profileBirthTime => 'Doğum saati';

  @override
  String get profileBirthPlace => 'Doğum yeri';

  @override
  String get profileBirthTimeUnknown => 'Bilinmiyor';

  @override
  String get profileEditBirthData => 'Doğum Bilgilerini Düzenle';

  @override
  String get profileSun => 'Güneş';

  @override
  String get profileMoon => 'Ay';

  @override
  String get profileRising => 'Yükselen';

  @override
  String get profileDayStreak => 'Gün serisi';

  @override
  String get profileJournalEntries => 'Günlük girişleri';

  @override
  String get profileAIChats => 'AI sohbetleri';

  @override
  String get profileSubscriptionPremium => 'Premium · Aktif';

  @override
  String get profileSubscriptionFree => 'Ücretsiz Plan';

  @override
  String get profileSubscriptionPremiumDesc =>
      'Sınırsız öngörü · öncelikli rezervasyon';

  @override
  String get profileSubscriptionFreeDesc => 'Tam haritan için yükseltme yap';

  @override
  String get profileNotifications => 'Bildirimler';

  @override
  String get profilePrivacy => 'Gizlilik';

  @override
  String get profileHelp => 'Yardım ve Destek';

  @override
  String get profileSettings => 'Ayarlar';

  @override
  String get profileNameLabel => 'AD';

  @override
  String get profileEmailLabel => 'E-POSTA';

  @override
  String get profileEmailNote =>
      'E-posta giriş sağlayıcın tarafından yönetilir.';

  @override
  String get profileSave => 'Kaydet';

  @override
  String get profileNameRequired => 'Ad boş olamaz.';

  @override
  String profileSaveError(String error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get editBirthDataTitle => 'Doğum bilgilerini düzenle';

  @override
  String get editBirthDateLabel => 'DOĞUM TARİHİ';

  @override
  String get editBirthTimeLabel => 'DOĞUM SAATİ';

  @override
  String get editBirthPlaceLabel => 'DOĞUM YERİ';

  @override
  String get editSaveChanges => 'Değişiklikleri kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get yourName => 'Adın';

  @override
  String get stargazer => 'Yıldız izleyici';

  @override
  String get chartsNothingMatches => 'Henüz buna uyan bir şey yok.';

  @override
  String get chartBadgeNew => 'Yeni';

  @override
  String get chartBirthChart => 'Doğum Haritası';

  @override
  String get chartBirthChartSubtitle =>
      'Gezegenler, evler, açılar.\nKim olduğunun haritası.';

  @override
  String get chartVedic => 'Vedik Harita';

  @override
  String get chartVedicSubtitle =>
      'Sidereal kundli, nakşatralar, daşalar,\n16 varga, yogalar — tam Jyotish.';

  @override
  String get chartNumerology => 'Numeroloji';

  @override
  String get chartNumerologySubtitle =>
      'Yaşam yolu, ruh dürtüsü, döngüler\n+ karmik desenler + uyum.';

  @override
  String get chartHumanDesign => 'İnsan Tasarımı';

  @override
  String get chartHumanDesignSubtitle =>
      'Tip, strateji, otorite,\nbeden grafiği planın.';

  @override
  String get chartCosmicTimeline => 'Kozmik Zaman Çizelgesi';

  @override
  String get chartCosmicTimelineSubtitle =>
      'Hayatın gökyüzüyle birlikte.\nAnlar + aktif transitler.';

  @override
  String get chartYearlyForecast => 'Yıllık Öngörü';

  @override
  String get chartYearlyForecastSubtitle =>
      '2026 sana aşkta, işte ve\nkişisel gelişimde ne sunuyor.';

  @override
  String get chartTransitForecast => 'Transit Öngörü';

  @override
  String get chartTransitForecastSubtitle =>
      'Sonraki 30 gün, 3 ay\nve yıl boyunca.';

  @override
  String get aiChatTitle => 'Astrolog';

  @override
  String get aiChatInputHint => 'Astroloğuna sor...';

  @override
  String get aiChatLimitReachedHint =>
      'Günlük limit doldu — devam etmek için yükselt';

  @override
  String aiChatMessagesToday(int used, int limit) {
    return 'Bugün $used/$limit mesaj';
  }

  @override
  String get aiChatLimitReached => 'Günlük limit doldu';

  @override
  String get aiChatPremiumUnlimited => 'Premium · Sınırsız';

  @override
  String get aiChatPaywallTitle => 'Bugünkü ücretsiz limitine ulaştın.';

  @override
  String get aiChatPaywallSubtitle =>
      'Astroloğunla sınırsız sohbet için Premium\'a yükselt.';

  @override
  String get aiChatStatusOnline => 'Haritandan besleniyor';

  @override
  String get aiChatEmptyHeadline => 'Kişisel astroloğun';

  @override
  String get aiChatEmptySubtitle =>
      'Haritan, transitler, rüyaların veya önündeki gün hakkında istediğini sor.';

  @override
  String get aiChatSuggestedQuestions => 'Şunları sorabilirsin…';

  @override
  String get aiChatPrompt1 => 'Bugün neye odaklanmalıyım?';

  @override
  String get aiChatPrompt2 => 'Venüs konumum hakkında ne söylersin?';

  @override
  String get aiChatPrompt3 => 'Bu hafta nasıl geçecek?';

  @override
  String get aiChatPrompt4 => 'En güçlü yanlarım neler?';

  @override
  String get aiChatPrompt5 => 'İlişkilerimi nasıl iyileştirebilirim?';

  @override
  String get aiChatPrompt6 => 'Haritama hangi kariyer yolları uygun?';

  @override
  String get aiChatYou => 'Sen';

  @override
  String get aiChatAstrologer => 'Astrolog';

  @override
  String get aiChatThinking => 'Düşünüyor…';

  @override
  String get aiChatRename => 'Sohbeti yeniden adlandır';

  @override
  String get aiChatDelete => 'Sohbeti sil';

  @override
  String get avatarChooseFromGallery => 'Galeriden seç';

  @override
  String get avatarTakePhoto => 'Fotoğraf çek';

  @override
  String get avatarRemovePhoto => 'Fotoğrafı kaldır';

  @override
  String get avatarPickerError => 'Seçici açılamadı.';

  @override
  String get avatarSaveError => 'Fotoğraf kaydedilemedi. Tekrar dene.';

  @override
  String get discussionsLoadError => 'Alanlar şu anda yüklenemedi.';

  @override
  String get discussionsEmpty => 'Henüz alan yok — ilk başlatan sen ol.';

  @override
  String get discussionsJoined => 'Katıldın';

  @override
  String discussionsMembersCount(String count) {
    return '$count üye';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsSubscription => 'Abonelik';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsPreferences => 'Tercihler';

  @override
  String get settingsSupport => 'Destek';

  @override
  String get settingsLegal => 'Yasal';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsPremiumActive => 'Premium Aktif';

  @override
  String get settingsFreePlan => 'Ücretsiz Plan';

  @override
  String get settingsManageSubscription => 'Aboneliğini yönet';

  @override
  String get settingsUpgrade => 'Tam erişim için yükselt';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsRateApp => 'Uygulamayı puanla';

  @override
  String get settingsTermsOfService => 'Hizmet Şartları';

  @override
  String get settingsSignOut => 'Çıkış yap';

  @override
  String get settingsSignOutConfirm => 'Çıkış yapmak istediğinden emin misin?';

  @override
  String get settingsDeleteAccount => 'Hesabı sil';

  @override
  String get settingsDeleteAccountConfirm =>
      'Bu, hesabını ve tüm verilerini kalıcı olarak siler. Bu işlem geri alınamaz.';

  @override
  String get settingsDelete => 'Sil';

  @override
  String get settingsAppVersion => 'Lively v1.0.0';

  @override
  String get chatThreadsTitle => 'Astrolog';

  @override
  String get chatThreadsStart => 'Sohbet başlat';

  @override
  String get chatThreadsEmpty => 'Astroloğunla yeni\nbir sohbet başlat.';

  @override
  String get chatThreadsNew => 'Yeni sohbet';

  @override
  String get chatThreadsDelete => 'Sil';

  @override
  String get chatThreadsDeleteConfirm => 'Bu sohbet silinsin mi?';

  @override
  String get chatThreadsUntitled => 'Yeni sohbet';

  @override
  String get paywallHeadline => 'Tüm Kozmik\nPotansiyelini Aç';

  @override
  String get paywallSubheadline =>
      'Premium her özelliğe sınırsız erişim sağlar.';

  @override
  String get paywallMonthly => 'Aylık';

  @override
  String get paywallYearly => 'Yıllık';

  @override
  String paywallSavePercent(String percent) {
    return '$percent indirim';
  }

  @override
  String get paywallStartFreeTrial => 'Ücretsiz dene';

  @override
  String get paywallSubscribe => 'Abone ol';

  @override
  String get paywallRestorePurchases => 'Satın alımları geri yükle';

  @override
  String get paywallTermsNote =>
      'İstediğin zaman iptal et. İptal edilmediği sürece otomatik yenilenir.';

  @override
  String get paywallFeatureUnlimitedChat => 'Sınırsız AI astrolog sohbeti';

  @override
  String get paywallFeatureFullChart => 'Evler ve açılarla tam doğum haritası';

  @override
  String get paywallFeatureDailyReading => 'Sana özel günlük okumalar';

  @override
  String get paywallFeatureCompatibility => 'Sınırsız uyum raporları';

  @override
  String get paywallFeatureNoAds => 'Reklamsız deneyim';

  @override
  String get paywallFeatureExport => 'Haritalarını dışa aktar';

  @override
  String get paywallBenefit1Title => 'Tam Günlük Rehberlik';

  @override
  String get paywallBenefit1Subtitle =>
      'Aşk, kariyer ve sağlık için detaylı öngörüler';

  @override
  String get paywallBenefit2Title => 'Sınırsız AI Sohbeti';

  @override
  String get paywallBenefit2Subtitle => 'Kişisel astroloğuna her şeyi sor';

  @override
  String get paywallBenefit3Title => 'Tam Uyum';

  @override
  String get paywallBenefit3Subtitle => 'Tüm ilişkilerin için derin raporlar';

  @override
  String get paywallBenefit4Title => 'Yaşam Çizgisi';

  @override
  String get paywallBenefit4Subtitle =>
      '30 günlük, 3 aylık ve 12 aylık öngörüler';

  @override
  String get paywallBenefit5Title => 'Yıllık Öngörü';

  @override
  String get paywallBenefit5Subtitle =>
      'Önümüzdeki yıl için kozmik yol haritan';

  @override
  String get paywallBenefit6Title => 'Ritüeller ve Günlük';

  @override
  String get paywallBenefit6Subtitle =>
      'Gelişim ve içe bakış için günlük pratikler';

  @override
  String get paywallSaveBadge => '%52 İNDİRİM';

  @override
  String get paywallTrialIncluded => '3 günlük ücretsiz deneme dahil';

  @override
  String get paywallRestoreLong => 'Satın Alımları Geri Yükle';

  @override
  String get paywallCancelNote =>
      'İstediğin zaman iptal et. Abonelik otomatik yenilenir.';

  @override
  String get dailyReadingTitle => 'Bugünün Okuması';

  @override
  String get dailyReadingEnergy => 'Enerji';

  @override
  String get dailyReadingEmotional => 'Duygusal';

  @override
  String get dailyReadingLove => 'Aşk ve Bağlantı';

  @override
  String get dailyReadingCareer => 'Kariyer ve Amaç';

  @override
  String get dailyReadingHealth => 'Sağlık ve Esenlik';

  @override
  String get dailyReadingCaution => 'Dikkat';

  @override
  String get dailyReadingAction => 'Aksiyon adımları';

  @override
  String get dailyReadingAffirmation => 'Olumlama';

  @override
  String get dailyReadingLuckyColor => 'Şans rengi';

  @override
  String get dailyReadingLuckyNumber => 'Şans sayısı';

  @override
  String get dailyReadingSun => 'Güneş';

  @override
  String get dailyReadingMoon => 'Ay';

  @override
  String get dailyReadingRising => 'Yükselen';

  @override
  String get journalTitle => 'Günlük';

  @override
  String get journalNewEntry => 'Yeni giriş';

  @override
  String get journalEmpty => 'Henüz giriş yok.\nİlk yansımanı yaz.';

  @override
  String get journalPromptHint => 'Bugün fark ettim ki...';

  @override
  String get journalSaved => 'Kaydedildi';

  @override
  String get journalSave => 'Kaydet';

  @override
  String get journalDelete => 'Sil';

  @override
  String get journalDeleteConfirm => 'Bu giriş silinsin mi?';

  @override
  String journalEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giriş',
      one: '1 giriş',
    );
    return '$_temp0 · gökyüzünün sana ne anlattığını yakala';
  }

  @override
  String get journalCosmicTitle => 'Kozmik Günlüğün';

  @override
  String get journalEmptyBlurb =>
      'Bugün fark ettiklerini, hissettiklerini\nveya merak ettiklerini yazabileceğin özel bir alan.';

  @override
  String get journalNewMoment => 'Yeni bir an';

  @override
  String get journalEditMoment => 'Anını düzenle';

  @override
  String get journalMoodHeader => 'BUGÜN NASIL HİSSETTİRİYOR?';

  @override
  String get journalPromptHeader => 'VEYA BİR İPUCUYLA BAŞLA';

  @override
  String get journalMoodSuffix => 'ruh hali';

  @override
  String get journalMoodGlad => 'Mutlu';

  @override
  String get journalMoodCalm => 'Sakin';

  @override
  String get journalMoodLoved => 'Sevilen';

  @override
  String get journalMoodSparkly => 'Parıltılı';

  @override
  String get journalMoodCurious => 'Meraklı';

  @override
  String get journalMoodTired => 'Yorgun';

  @override
  String get journalMoodHeavy => 'Ağır';

  @override
  String get journalMoodRestless => 'Huzursuz';

  @override
  String get journalPrompt1 => 'Bugün seni şaşırtan ne oldu?';

  @override
  String get journalPrompt2 => 'Kendini en çok nerede sen hissettin?';

  @override
  String get journalPrompt3 => 'Neyi bırakıyorsun?';

  @override
  String get journalPrompt4 => 'Bugün gökyüzü nasıl hissettiriyordu?';

  @override
  String get journalEditorHint =>
      'Bugün fark ettiklerini, hissettiklerini veya merak ettiklerini yaz...';

  @override
  String journalSaveFailed(String error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get todaySkyEnergyHighTitle => 'Enerji: yüksek';

  @override
  String get todaySkyEnergyHighBody =>
      'Bir şeye başlamak için iyi bir gün — momentum eylemden yana.';

  @override
  String get todaySkyHeartTitle => 'Kalp ön planda';

  @override
  String get todaySkyHeartBody =>
      'Venüs konuşmaya sıcaklık katıyor. Birine ulaş.';

  @override
  String get todaySkyMindTitle => 'Zihin keskin';

  @override
  String get todaySkyMindBody =>
      'Merkür berrak düşünmeyi destekliyor. Zor maile el at.';

  @override
  String get todaySkyPauseTitle => 'Tepki vermeden önce dur';

  @override
  String get todaySkyPauseBody => 'Gergin açı — büyük kararları yarına bırak.';

  @override
  String get todaySkyRestTitle => 'Dinlenme penceresi';

  @override
  String get todaySkyRestBody =>
      'Yumuşak transitler — bu akşam dinginliğe zaman ayır.';

  @override
  String get todaySkyCreativeTitle => 'Yaratıcı kıvılcım';

  @override
  String get todaySkyCreativeBody =>
      'Hayal gücü yüksek — fikri kaybetmeden yakala.';

  @override
  String get todaySkyRecognitionTitle => 'Tanınma mümkün';

  @override
  String get todaySkyRecognitionBody =>
      'Güneş-Jüpiter üçgeni görünürlüğü artırıyor. İşinin arkasında dur.';

  @override
  String get todaySkyNewGroundTitle => 'Yeni topraklar';

  @override
  String get todaySkyNewGroundBody =>
      'Bir bakış açısı değişimi mümkün. Eve farklı bir yoldan dön.';

  @override
  String get todaySkyBridgesTitle => 'Köprüler, duvarlar değil';

  @override
  String get todaySkyBridgesBody =>
      'Diplomatik enerji — zor bir konuşma beklenenden iyi gidebilir.';

  @override
  String todaySkyIlluminated(String percent) {
    return '%$percent aydınlanmış';
  }

  @override
  String todaySkySunIn(String sign) {
    return 'Güneş $sign burcunda';
  }

  @override
  String get compatibilityTitle => 'Uyum';

  @override
  String get compatibilityAddPerson => 'Kişi ekle';

  @override
  String get compatibilityEmpty => 'Uyumunu görmek için birini ekle.';

  @override
  String get compatibilityViewReport => 'Raporu görüntüle';

  @override
  String get compatibilityName => 'Ad';

  @override
  String get compatibilityRelationship => 'İlişki';

  @override
  String get compatibilityBirthDate => 'Doğum tarihi';

  @override
  String get compatibilityBirthTime => 'Doğum saati';

  @override
  String get compatibilityBirthPlace => 'Doğum yeri';

  @override
  String get compatibilitySave => 'Kaydet';

  @override
  String compatibilitySavedCount(int count) {
    return '$count kayıtlı · uyumunuzu keşfedin';
  }

  @override
  String get compatibilitySeeHow => 'Nasıl Bağlandığını Gör';

  @override
  String get compatibilityEmptyBlurb =>
      'Bir partner, arkadaş veya aile üyesi ekle\nve haritalarınızı karşılaştır.';

  @override
  String get addPersonTitle => 'Birini Ekle';

  @override
  String get addPersonSubtitle =>
      'Onun haritasını seninkiyle karşılaştıracağız.';

  @override
  String get addPersonNameLabel => 'Adı';

  @override
  String get addPersonNameHint => 'ör. Mehmet Yılmaz';

  @override
  String get addPersonRelationship => 'İlişki';

  @override
  String get addPersonBirthDate => 'Doğum tarihi';

  @override
  String get addPersonBirthTime => 'Doğum saati';

  @override
  String get addPersonBirthplace => 'Doğum yeri';

  @override
  String get addPersonGenerate => 'Ekle ve Rapor Oluştur';

  @override
  String get addPersonOptional => '(isteğe bağlı)';

  @override
  String get addPersonSelectDate => 'Tarih seç';

  @override
  String get addPersonSelectTime => 'Saat seç';

  @override
  String get addPersonTimeKnown => 'Biliniyor';

  @override
  String get addPersonTimeUnknown => 'Bilinmiyor';

  @override
  String get compatReportSummary => 'Özet';

  @override
  String get compatReportConflictPatterns => 'Çatışma Örüntüleri';

  @override
  String get compatReportAdvice => 'Öneriler';

  @override
  String get compatScoreMagnetic => 'Manyetik bir hizalanma';

  @override
  String get compatScoreEasy => 'Kolay, üretken bir enerji';

  @override
  String get compatScoreWorthWork => 'Üzerinde çalışmaya değer';

  @override
  String get compatScoreFriction => 'Potansiyelli bir sürtüşme';

  @override
  String get compatScoreOpposites => 'Zıtlıklar üzerine bir çalışma';

  @override
  String get compatDimEmotional => 'Duygusal';

  @override
  String get compatDimCommunication => 'İletişim';

  @override
  String get compatDimChemistry => 'Kimya';

  @override
  String get chartScreenTitle => 'Doğum Haritası';

  @override
  String get chartTabPlanets => 'Gezegenler';

  @override
  String get chartTabHouses => 'Evler';

  @override
  String get chartTabAspects => 'Açılar';

  @override
  String get chartTabElements => 'Elementler';

  @override
  String get chartTabSummary => 'Özet';

  @override
  String get chartViewVedic => 'Vedik Haritayı Gör';

  @override
  String get chartLegendConjunction => 'Kavuşum';

  @override
  String get chartLegendSextile => 'Altmışlık';

  @override
  String get chartLegendSquare => 'Kare';

  @override
  String get chartLegendTrine => 'Üçgen';

  @override
  String get chartLegendOpposition => 'Karşıt';

  @override
  String chartHouseNumber(int n) {
    return '$n. Ev';
  }

  @override
  String get chartHouse1 => 'Benlik ve Kimlik';

  @override
  String get chartHouse2 => 'Değerler ve Kaynaklar';

  @override
  String get chartHouse3 => 'İletişim';

  @override
  String get chartHouse4 => 'Ev ve Kökler';

  @override
  String get chartHouse5 => 'Yaratıcılık ve Neşe';

  @override
  String get chartHouse6 => 'İş ve Sağlık';

  @override
  String get chartHouse7 => 'Ortaklıklar';

  @override
  String get chartHouse8 => 'Dönüşüm';

  @override
  String get chartHouse9 => 'Felsefe ve Yolculuk';

  @override
  String get chartHouse10 => 'Kariyer ve Miras';

  @override
  String get chartHouse11 => 'Topluluk ve Vizyon';

  @override
  String get chartHouse12 => 'Ruh ve Teslimiyet';

  @override
  String get chartNoPlanets => 'Gezegen verisi yok';

  @override
  String get chartNoHouses => 'Ev verisi yok';

  @override
  String get chartNoAspects => 'Açı verisi yok';

  @override
  String get chartNoElements => 'Element verisi yok';

  @override
  String chartHouseLine(String sign, String degree) {
    return '$sign · $degree°';
  }

  @override
  String chartAspectOrb(String value) {
    return 'Orb $value°';
  }

  @override
  String get vedicScreenTitle => 'Vedik Harita';

  @override
  String get vedicAyanamsa => 'Ayanamşa';

  @override
  String get vedicTabOverview => 'Genel';

  @override
  String get vedicTabPlanets => 'Gezegenler';

  @override
  String get vedicTabHouses => 'Evler';

  @override
  String get vedicTabBhavas => 'Bhavalar';

  @override
  String get vedicTabAspects => 'Açılar';

  @override
  String get vedicTabNakshatras => 'Nakşatralar';

  @override
  String get vedicTabVargas => 'Vargalar';

  @override
  String get vedicTabDasha => 'Daşa';

  @override
  String get vedicTabYogas => 'Yogalar';

  @override
  String get vedicTabShadbala => 'Şadbala';

  @override
  String get vedicTabAshtakavarga => 'Aştakavarga';

  @override
  String vedicAtmakarakaLabel(String name) {
    return 'Atmakaraka: $name';
  }

  @override
  String vedicChartCaption(String varga, int divisor, String ayanamsa) {
    return '$varga (D$divisor) · $ayanamsa ayanamşa';
  }

  @override
  String get vedicNoAspects => 'Graha-graha drişti yok';

  @override
  String get vedicNoYogas =>
      'Bu harita için aktif klasik yoga tespit edilmedi.';

  @override
  String get vedicNoShadbala => 'Şadbala verisi yok';

  @override
  String get vedicVargasNote =>
      'Yukarıdaki ana harita seçilen Varga için yeniden çizilir. Her bölünmeli harita hayatın farklı bir yönünü gösterir: D9 evlilik ve dharma, D10 kariyer, D12 ebeveynler, D60 geçmiş karma.';

  @override
  String vedicBhavaOccupants(String planets) {
    return 'Bulunanlar: $planets';
  }

  @override
  String vedicBhavaLord(String sign, String sanskrit, String lord) {
    return '$sign ($sanskrit) · Yöneticisi $lord';
  }

  @override
  String vedicAspectsLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String get vedicRetro => 'Rx';

  @override
  String get vedicCombust => 'Yanık';

  @override
  String get numerologyTitle => 'Numeroloji';

  @override
  String get numerologyTabCore => 'Temel';

  @override
  String get numerologyTabToday => 'Bugün';

  @override
  String get numerologyTabCycles => 'Döngüler';

  @override
  String get numerologyTabKarmic => 'Karmik';

  @override
  String get numerologyTabCompat => 'Uyum';

  @override
  String get numerologyTabCompatibility => 'Uyum';

  @override
  String get numerologyCompareWith => 'Biriyle karşılaştır';

  @override
  String get numerologyNameCalculatorTitle => 'İsim Hesaplayıcı';

  @override
  String get numerologyNameCalculatorBlurb =>
      'Herhangi bir tam ismi gir; İfade, Ruh Dürtüsü ve Kişilik sayıları ile harf harf dökümünü gör.';

  @override
  String get numerologyNameInputHint => 'ör. Mustafa Kemal Atatürk';

  @override
  String get numerologyNameCalculate => 'Hesapla';

  @override
  String get numerologyNameOpenCalculator => 'Herhangi bir ismi hesapla';

  @override
  String get numerologyNameLetterBreakdown => 'Harf dökümü';

  @override
  String get numerologyNameVowels => 'sesli harfler';

  @override
  String get numerologyNameConsonants => 'sessiz harfler';

  @override
  String get numerologyNameHiddenPassion => 'Gizli tutku';

  @override
  String get numerologyNameKarmicLessons => 'Karmik dersler';

  @override
  String get numerologyNameKarmicLessonsNone =>
      'Yok — bu isimde her rakam bulunuyor.';

  @override
  String get errOfflineTitle => 'Bağlantın yok';

  @override
  String get errOfflineBody =>
      'Bağlantını kontrol edip tekrar dene. Bazı ekranlar bağlantısız çalışır ama haritalar için gökyüzü gerek.';

  @override
  String get errAuthTitle => 'Oturum süresi doldu';

  @override
  String get errAuthBody =>
      'Devam etmek için tekrar giriş yap. Verilerin güvende.';

  @override
  String get errRateLimitTitle => 'Biraz yavaşla';

  @override
  String get errRateLimitBody =>
      'Günlük limitine ulaştın. Sonra tekrar dene ya da limiti kaldırmak için yükselt.';

  @override
  String get errChatLimitBody =>
      'Bugünkü ücretsiz astrolog mesajlarını kullandın. Sınırsız için Premium\'a yükselt veya yarın tekrar gel.';

  @override
  String get errNotFoundTitle => 'Bulunamadı';

  @override
  String get errNotFoundBody =>
      'Aradığını bulamadık. Taşınmış veya kaldırılmış olabilir.';

  @override
  String get errServerTitle => 'Bizim tarafımızda bir sorun var';

  @override
  String get errServerBody =>
      'Sunucumuz biraz zorlanıyor. Zaten bakıyoruz — lütfen birazdan tekrar dene.';

  @override
  String get errCacheBody =>
      'Yerel kopya okunamadı. Tekrar dene — taze veriyi getireceğiz.';

  @override
  String get errGenericTitle => 'Bir şeyler ters gitti';

  @override
  String get errGenericBody =>
      'Beklenmeyen bir hatayla karşılaştık. Tekrar dene veya devam ederse uygulamayı yeniden başlat.';

  @override
  String get errRetry => 'Tekrar dene';

  @override
  String get errGoHome => 'Ana sayfaya dön';

  @override
  String get errReportProblem => 'Sorunu bildir';

  @override
  String get errCrashTitle => 'Kozmos hıçkırdı';

  @override
  String get errCrashBody =>
      'Beklenmeyen bir şey oldu. Uygulamayı yeniden başlat — devam ederse bize haber ver.';

  @override
  String get numerologyLifePathBadge => 'YAŞAM YOLU';

  @override
  String get numerologyMasterBadge => 'USTA';

  @override
  String get numerologyCoreLifePath => 'Yaşam Yolu';

  @override
  String get numerologyCoreExpression => 'İfade';

  @override
  String get numerologyCoreSoulUrge => 'Ruh Dürtüsü';

  @override
  String get numerologyCorePersonality => 'Kişilik';

  @override
  String get numerologyCoreMaturity => 'Olgunluk';

  @override
  String get numerologyCoreBirthday => 'Doğum Günü';

  @override
  String get numerologyCompatBlurb =>
      'Karşı tarafın tam doğum adını ve doğum tarihini gir; ilişki açısından önemli üç sayı için numeroloji uyumunu hesaplayalım.';

  @override
  String get numerologyOpenCompat => 'Uyumu aç';

  @override
  String get humanDesignTitle => 'İnsan Tasarımı';

  @override
  String get humanDesignTabBodyGraph => 'Beden Grafiği';

  @override
  String get humanDesignTabCenters => 'Merkezler';

  @override
  String get humanDesignTabChannels => 'Kanallar';

  @override
  String get humanDesignTabGates => 'Kapılar';

  @override
  String get humanDesignTabProfile => 'Profil';

  @override
  String get humanDesignBodyGraphLegend =>
      'Dolu merkezler tanımlı, boş merkezler açıktır. Çizgiler tanımlı kanallardır. Kırmızı noktalar Kişilik kapıları (bilinçli), krem noktalar Tasarım kapılarıdır (bilinçdışı).';

  @override
  String get humanDesignNoChannels =>
      'Tanımlı kanal yok — bir Yansıtıcı olabilirsin ya da yalnızca bireysel aktif kapıların olabilir.';

  @override
  String get humanDesignProfileLabel => 'PROFİL';

  @override
  String get humanDesignProfileDesc =>
      'Kişiliğin bilinçli çizgisi × Tasarımın bilinçdışı çizgisi.';

  @override
  String get yearlyForecastTitle => 'Yıllık Öngörü';

  @override
  String get transitForecastTitle => 'Transit Öngörü';

  @override
  String get lifeTimelineTitle => 'Kozmik Zaman Çizelgesi';

  @override
  String get ritualsTitle => 'Ritüeller';

  @override
  String get ritualsTodayTitle => 'Bugünün Ritüelleri';

  @override
  String ritualsStreak(int days) {
    return '$days günlük seri';
  }

  @override
  String get ritualsTodayHeading => 'Bugünün ritüelleri';

  @override
  String get ritualsTodaySubtitle =>
      'Kozmik bağlantını güçlendirmek için bunları tamamla.';

  @override
  String get ritualMorningTitle => 'Sabah Niyeti';

  @override
  String get ritualMorningDesc => 'Önündeki gün için niyetini belirle.';

  @override
  String get ritualAffirmationTitle => 'Olumlama';

  @override
  String get ritualAffirmationDesc =>
      'Bugünün olumlamasını oku ve içselleştir.';

  @override
  String get ritualEveningTitle => 'Akşam Yansıması';

  @override
  String get ritualEveningDesc =>
      'Gününü değerlendir ve şükran duyduklarını not et.';

  @override
  String get notifEmptyBlurb =>
      'Henüz bildirim yok — insanlar alanlarınla, gönderilerinle veya yorumlarınla etkileşime geçtiğinde burada göreceksin.';

  @override
  String get notifGroupToday => 'BUGÜN';

  @override
  String get notifGroupYesterday => 'DÜN';

  @override
  String get notifGroupThisWeek => 'BU HAFTA';

  @override
  String get notifGroupEarlier => 'DAHA ÖNCE';

  @override
  String get spacePostsHeader => 'Gönderiler';

  @override
  String get spaceNoPosts => 'Henüz gönderi yok — ilk olan sen ol.';

  @override
  String get editSpaceLossWarning =>
      'Tüm gönderiler ve yorumlar kalıcı olarak silinecek.';

  @override
  String get editSpaceSaving => 'Kaydediliyor…';

  @override
  String get editSpaceSave => 'Kaydet';

  @override
  String get editSpaceHandleLabel => 'KULLANICI ADI';

  @override
  String get editSpaceNameLabel => 'AD';

  @override
  String get editSpaceDescLabel => 'AÇIKLAMA';

  @override
  String get homeWelcomeBack => 'Tekrar Hoş Geldin';

  @override
  String get dailyReadingHeading => 'Günlük Okuman';

  @override
  String get dailyReadingResonant => 'Rezonans';

  @override
  String get yfYearTheme => 'YIL TEMAN';

  @override
  String get yfQuarterBreakdown => 'Çeyrek Dökümü';

  @override
  String get yfHeroSubtitle =>
      'Kozmik yol haritan. Bir yıl, dört bölüm — her birinin kendi havası ve hava tahmini.';

  @override
  String yfQuarterLabel(int n) {
    return '$n. Çeyrek';
  }

  @override
  String get yfNoData =>
      'Henüz yıllık öngörü hazır değil. Birazdan tekrar bak.';

  @override
  String get transit30Days => '30 Gün';

  @override
  String get transit3Months => '3 Ay';

  @override
  String get transit12Months => '12 Ay';

  @override
  String get transitHeroTitle => 'Transit Öngörüsü';

  @override
  String get transitHeroSubtitle =>
      'Önündeki gökyüzü — bir pencere seç, ne zaman atılım yapacağını, ne zaman bekleyeceğini ve ne zaman dinleyeceğini gör.';

  @override
  String get transitEnergyPositive => 'Olumlu';

  @override
  String get transitEnergyChallenging => 'Zorlu';

  @override
  String get transitEnergyIntense => 'Yoğun';

  @override
  String get transitEnergyNeutral => 'Nötr';

  @override
  String get transitNoData => 'Bu pencere için henüz transit haritalanmadı.';

  @override
  String get communityTitle => 'Topluluk';

  @override
  String get communityCreateSpace => 'Alan oluştur';

  @override
  String get communityHeroBlurb =>
      'Kendi insanlarını bul. Okumalarını paylaş, soru sor, seni heyecanlandıran sohbetleri takip et.';

  @override
  String get communityFilterAll => 'Tümü';

  @override
  String get communityFilterJoined => 'Katıldıklarım';

  @override
  String get communitySpacesEmpty => 'Henüz alan yok.';

  @override
  String get communityNewPost => 'Yeni gönderi';

  @override
  String get communityWriteSomething => 'Bir şeyler yaz...';

  @override
  String get communityPostSubmit => 'Gönder';

  @override
  String get communityComment => 'Yorum';

  @override
  String get communityReply => 'Cevapla';

  @override
  String get communityLike => 'Beğen';

  @override
  String get communityShare => 'Paylaş';

  @override
  String get communityJoinSpace => 'Katıl';

  @override
  String get communityLeaveSpace => 'Ayrıl';

  @override
  String get communityMembers => 'Üyeler';

  @override
  String get communityNotifications => 'Bildirimler';

  @override
  String get communityNotificationsEmpty => 'Yeni bir şey yok.';

  @override
  String get communityMarkAllRead => 'Tümünü okundu işaretle';

  @override
  String get communityPostTitle => 'Gönderi';

  @override
  String get communityNewSpace => 'Yeni Alan';

  @override
  String get communityEditSpace => 'Alanı Düzenle';

  @override
  String get communityDeleteSpaceConfirm => 'Bu alan silinsin mi?';

  @override
  String get communityProfile => 'Profil';

  @override
  String get communityCategoriesLabel => 'KATEGORİLER';

  @override
  String get communitySearchSpaces => 'Alan ara';

  @override
  String get communityNewPostTitle => 'Yeni gönderi';

  @override
  String get communitySpacesEmptyTap =>
      'Henüz alan yok — ilkini oluşturmak için + simgesine dokun.';

  @override
  String get communityComposeHint => 'Aklında ne var?';

  @override
  String get communityLinkHint => 'İsteğe bağlı bağlantı URL\'si';

  @override
  String get communityNotificationsTooltip => 'Bildirimler';

  @override
  String get communityNewSpaceTooltip => 'Yeni alan';

  @override
  String get lifeTimelineAddMoment => 'An ekle';

  @override
  String lifeTimelineMomentsMapped(int count) {
    return '$count an haritalandı';
  }

  @override
  String get lifeTimelineHeaderTitle => 'Kozmik Zaman Çizelgen';

  @override
  String get lifeTimelineHeaderSubtitle =>
      'Hayatın gökyüzüyle birlikte.\nAnlar ekle. Yukarıda neler olduğunu gör.';

  @override
  String lifeTimelineFelt(String mood) {
    return '$mood hissettim';
  }

  @override
  String get lifeTimelineWhatSky => 'GÖKYÜZÜ NE YAPIYORDU';
}
