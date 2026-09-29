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
  String get spaceLockedTitle => 'Sadece üyelere özel alan';

  @override
  String get spaceLockedBody =>
      'Erişim talebi göndermek için Katıl\'a dokun. Yönetici talebini onaylayacak ya da reddedecek; her iki durumda da bildirim alacaksın.';

  @override
  String get spacePendingTitle => 'Talep onay bekliyor';

  @override
  String get spacePendingBody =>
      'Yönetici henüz talebini incelemedi. Onayladığı an buradaki gönderileri görebileceksin.';

  @override
  String get spaceManageRequests => 'Katılım taleplerini yönet';

  @override
  String get spaceRequestsTitle => 'Katılım talepleri';

  @override
  String get spaceRequestsEmpty => 'Şu anda bekleyen talep yok.';

  @override
  String get spaceRequestsAccept => 'Kabul et';

  @override
  String get spaceRequestsDecline => 'Reddet';

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
  String get onboardingNameReassure =>
      'Bunu asla paylaşmayız. İstediğin zaman Profil\'den değiştirebilirsin.';

  @override
  String onboardingFocusCount(int count) {
    return '$count / 3 seçildi';
  }

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
  String get welcomeEnter => 'Lively\'e Gir';

  @override
  String get welcomeAligning => 'Yıldızlar hizalanıyor…';

  @override
  String welcomeKicker(Object name) {
    return 'Hoş geldin, $name';
  }

  @override
  String get welcomeChartReady => 'Haritan';

  @override
  String get welcomeChartReady2 => 'hazır.';

  @override
  String get welcomeSun => 'Güneş';

  @override
  String get welcomeMoon => 'Ay';

  @override
  String get welcomeRising => 'Yükselen';

  @override
  String get authHeroSignIn => 'Gökyüzü,\nsana özel.';

  @override
  String get authHeroSignUp => 'Kozmik profilini\noluştur.';

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

  @override
  String get commonJustNow => 'Az önce';

  @override
  String commonMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String commonHoursAgo(int count) {
    return '$count sa önce';
  }

  @override
  String commonDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String get commonGoodMorning => 'Günaydın';

  @override
  String get commonGoodAfternoon => 'İyi günler';

  @override
  String get commonGoodEvening => 'İyi akşamlar';

  @override
  String get commonSomethingWentWrong =>
      'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get commonShowPassword => 'Şifreyi göster';

  @override
  String get commonHidePassword => 'Şifreyi gizle';

  @override
  String get validationNameRequired => 'Lütfen adını gir';

  @override
  String get validationNameTooShort => 'Ad en az 2 karakter olmalı';

  @override
  String get validationNameTooLong => 'Ad 50 karakterden kısa olmalı';

  @override
  String get validationEmailRequired => 'Lütfen e-posta adresini gir';

  @override
  String get validationEmailInvalid => 'Lütfen geçerli bir e-posta adresi gir';

  @override
  String get validationPasswordRequired => 'Lütfen bir şifre gir';

  @override
  String get validationBirthDateRequired => 'Lütfen doğum tarihini seç';

  @override
  String get validationBirthDateFuture => 'Doğum tarihi gelecekte olamaz';

  @override
  String get validationMinAge => 'En az 13 yaşında olmalısın';

  @override
  String get validationBirthDateInvalid =>
      'Lütfen geçerli bir doğum tarihi gir';

  @override
  String get validationBirthPlaceRequired => 'Lütfen doğum yerini seç';

  @override
  String get validationMessageRequired => 'Lütfen bir mesaj yaz';

  @override
  String get validationMessageTooLong => 'Mesaj 500 karakterden kısa olmalı';

  @override
  String get authInvalidEmail => 'Geçerli bir e-posta adresi gir';

  @override
  String get authNoAccountTapCreate =>
      'Bu e-postayla kayıtlı bir hesap yok. Kaydolmak için Hesap oluştur\'a dokun.';

  @override
  String get authNoAccountCheckAddress =>
      'Bu e-postayla kayıtlı bir hesap yok. Adresi kontrol et ya da yeni bir hesap oluştur.';

  @override
  String get authTooManyCodeRequests =>
      'Çok fazla kod istedin. Lütfen bir dakika bekle.';

  @override
  String get authTooManyAttemptsShort =>
      'Çok fazla deneme yapıldı. Birazdan tekrar dene.';

  @override
  String get authTooManyAttemptsWait =>
      'Çok fazla deneme yapıldı. Lütfen bir dakika bekle.';

  @override
  String get authKickerWelcomeBack => 'TEKRAR HOŞ GELDİN';

  @override
  String get authKickerCreateAccount => 'HESAP OLUŞTUR';

  @override
  String get authBeginJourney => 'Yolculuğuna başla';

  @override
  String get authSignInSubtitle =>
      'Kozmik aynan seni bekliyor. Devam etmek için giriş yap.';

  @override
  String get authRegisterSubtitle =>
      'Birkaç küçük bilgi ve yıldızlar keşfetmen için senin.';

  @override
  String get authSignInWithCode => 'Bunun yerine kodla giriş yap';

  @override
  String get authForgotYourPassword => 'Şifreni mi unuttun?';

  @override
  String get authResetPasswordKicker => 'ŞİFRE SIFIRLAMA';

  @override
  String get authForgotPasswordBody =>
      'E-posta adresini gir, yeni bir şifre belirlemen için sana bir kod gönderelim.';

  @override
  String get authSendResetCode => 'Sıfırlama kodu gönder';

  @override
  String get authBackToSignIn => 'Girişe dön';

  @override
  String get authPasswordUpdated => 'Şifren güncellendi. Lütfen giriş yap.';

  @override
  String get authOtpInvalidCode =>
      'Bu kod işe yaramadı. Tekrar dene ya da yeniden gönder.';

  @override
  String get authOtpKickerConfirmEmail => 'E-POSTANI DOĞRULA';

  @override
  String get authOtpKickerSignIn => 'GİRİŞ YAP';

  @override
  String get authOtpKickerResetPassword => 'ŞİFRENİ SIFIRLA';

  @override
  String get authOtpCheckEmail => 'E-postanı kontrol et';

  @override
  String authOtpSentTo(String email) {
    return '$email adresine 6 haneli bir kod gönderdik.';
  }

  @override
  String get authNewPassword => 'Yeni şifre';

  @override
  String get authResetPasswordButton => 'Şifreyi sıfırla';

  @override
  String authOtpResendIn(String time) {
    return '$time sonra kodu yeniden gönder';
  }

  @override
  String get authOtpResend => 'Kodu yeniden gönder';

  @override
  String get onboardingRevealTitle => 'Kozmik planın';

  @override
  String get onboardingRevealSubtitle => 'İşte Büyük Üçlün.';

  @override
  String get onboardingRevealSunSign => 'Güneş Burcu';

  @override
  String get onboardingRevealMoonSign => 'Ay Burcu';

  @override
  String get onboardingRevealRisingSign => 'Yükselen Burç';

  @override
  String get onboardingSignUnknown => 'Bilinmiyor';

  @override
  String premiumUnlockFeature(String feature) {
    return '$feature kilidini aç';
  }

  @override
  String get premiumUnlockThisFeature => 'Bu özelliğin kilidini aç';

  @override
  String get premiumUpgradeBody =>
      'Sana özel öngörülere tam erişim için Premium\'a yükselt.';

  @override
  String get premiumViewPlans => 'Planları gör';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/ay';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/yıl';
  }

  @override
  String get chartSignAries => 'Koç';

  @override
  String get chartSignTaurus => 'Boğa';

  @override
  String get chartSignGemini => 'İkizler';

  @override
  String get chartSignCancer => 'Yengeç';

  @override
  String get chartSignLeo => 'Aslan';

  @override
  String get chartSignVirgo => 'Başak';

  @override
  String get chartSignLibra => 'Terazi';

  @override
  String get chartSignScorpio => 'Akrep';

  @override
  String get chartSignSagittarius => 'Yay';

  @override
  String get chartSignCapricorn => 'Oğlak';

  @override
  String get chartSignAquarius => 'Kova';

  @override
  String get chartSignPisces => 'Balık';

  @override
  String get chartSignAbbrAries => 'Koç';

  @override
  String get chartSignAbbrTaurus => 'Boğ';

  @override
  String get chartSignAbbrGemini => 'İki';

  @override
  String get chartSignAbbrCancer => 'Yen';

  @override
  String get chartSignAbbrLeo => 'Asl';

  @override
  String get chartSignAbbrVirgo => 'Baş';

  @override
  String get chartSignAbbrLibra => 'Ter';

  @override
  String get chartSignAbbrScorpio => 'Akr';

  @override
  String get chartSignAbbrSagittarius => 'Yay';

  @override
  String get chartSignAbbrCapricorn => 'Oğl';

  @override
  String get chartSignAbbrAquarius => 'Kov';

  @override
  String get chartSignAbbrPisces => 'Bal';

  @override
  String get chartPlanetSun => 'Güneş';

  @override
  String get chartPlanetMoon => 'Ay';

  @override
  String get chartPlanetMercury => 'Merkür';

  @override
  String get chartPlanetVenus => 'Venüs';

  @override
  String get chartPlanetMars => 'Mars';

  @override
  String get chartPlanetJupiter => 'Jüpiter';

  @override
  String get chartPlanetSaturn => 'Satürn';

  @override
  String get chartPlanetUranus => 'Uranüs';

  @override
  String get chartPlanetNeptune => 'Neptün';

  @override
  String get chartPlanetPluto => 'Plüton';

  @override
  String get chartPlanetNorthNode => 'Kuzey Ay Düğümü';

  @override
  String get chartPlanetSouthNode => 'Güney Ay Düğümü';

  @override
  String get chartPlanetChiron => 'Kiron';

  @override
  String get chartAspectQuincunx => 'Yüzellilik';

  @override
  String chartAspectTitle(String planet1, String aspect, String planet2) {
    return '$planet1 $aspect $planet2';
  }

  @override
  String get chartElementFire => 'Ateş';

  @override
  String get chartElementEarth => 'Toprak';

  @override
  String get chartElementAir => 'Hava';

  @override
  String get chartElementWater => 'Su';

  @override
  String chartPercent(String value) {
    return '%$value';
  }

  @override
  String get vedicLagnaLabel => 'LAGNA';

  @override
  String get vedicChandraLabel => 'ÇANDRA';

  @override
  String get vedicSuryaLabel => 'SURYA';

  @override
  String get vedicLagna => 'Lagna';

  @override
  String vedicPlanetPosition(
      String sign, String sanskrit, String degree, int house) {
    return '$sign ($sanskrit) · $degree° · $house. Ev';
  }

  @override
  String vedicNakshatraPada(String nakshatra, int pada) {
    return '$nakshatra · $pada. pada';
  }

  @override
  String get vedicDignityExalted => 'Yücelmiş';

  @override
  String get vedicDignityDebilitated => 'Düşüşte';

  @override
  String get vedicDignityMooltrikona => 'Mulatrikona';

  @override
  String get vedicDignityOwn => 'Kendi burcunda';

  @override
  String get vedicDignityFriend => 'Dost burçta';

  @override
  String get vedicDignityEnemy => 'Düşman burçta';

  @override
  String get vedicDignityNeutral => 'Nötr';

  @override
  String vedicAspectOrdinal(String n) {
    return '$n.';
  }

  @override
  String get vedicMahadashasHeader => 'Mahadaşalar (120 yıllık döngü)';

  @override
  String get vedicCurrentDasha => 'ŞU ANKİ DAŞA';

  @override
  String get vedicDashaLevels => 'Maha · Antar · Pratyantar';

  @override
  String get vedicDashaNow => 'ŞİMDİ';

  @override
  String get vedicYogaStrength => 'GÜÇ';

  @override
  String get vedicYogaCategoryPanchaMahapurusha => 'Pança Mahapuruşa';

  @override
  String get vedicYogaCategoryLunar => 'Ay';

  @override
  String get vedicYogaCategorySolar => 'Güneş';

  @override
  String get vedicYogaCategoryWealth => 'Bolluk';

  @override
  String get vedicYogaCategoryPower => 'Güç';

  @override
  String get vedicYogaCategoryWisdom => 'Bilgelik';

  @override
  String get vedicYogaCategoryNodal => 'Ay Düğümü';

  @override
  String vedicNakshatraPadaRuler(int pada, String ruler) {
    return '$pada. pada · Yöneticisi $ruler';
  }

  @override
  String get vedicNakshatraDeity => 'Tanrı';

  @override
  String get vedicNakshatraSymbol => 'Sembol';

  @override
  String get vedicNakshatraGana => 'Gana';

  @override
  String get vedicNakshatraNadi => 'Nadi';

  @override
  String get vedicNakshatraVarna => 'Varna';

  @override
  String get vedicNakshatraCaste => 'Kast';

  @override
  String get vedicNakshatraAnimal => 'Hayvan';

  @override
  String get vedicNakshatraGender => 'Cinsiyet';

  @override
  String vedicShadbalaSummary(String total, String required, String verdict) {
    return '$total / $required Virupa — $verdict';
  }

  @override
  String get vedicShadbalaStrong => 'GÜÇLÜ';

  @override
  String get vedicShadbalaWeak => 'ZAYIF';

  @override
  String get vedicShadbalaChesta => 'Çeşta';

  @override
  String get vedicAshtakavargaSarva => 'Sarva';

  @override
  String vedicAshtakavargaSarvaNote(int max) {
    return 'Sarva Aştakavarga — her burcun yedi grahanın tamamından aldığı toplam hayırlı puan (burç başına en fazla $max).';
  }

  @override
  String vedicAshtakavargaBhinnNote(String planet, int max) {
    return '$planet için Bhinn Aştakavarga — $planet tarafından her burca verilen bindular (burç başına en fazla $max).';
  }

  @override
  String communityMembersCount(int count) {
    return '$count üye';
  }

  @override
  String get communityCategoryFallback => 'Kategori';

  @override
  String get communityCategoryEmpty => 'Bu kategoride henüz alan yok.';

  @override
  String postInSpace(String handle) {
    return '@$handle içinde';
  }

  @override
  String get postCommentsHeader => 'Yorumlar';

  @override
  String get postNoComments => 'Henüz yorum yok.';

  @override
  String postReplyingTo(String name) {
    return '$name kişisine yanıt veriyorsun';
  }

  @override
  String get postWriteCommentHint => 'Bir yorum yaz';

  @override
  String get spaceCreateAction => 'Oluştur';

  @override
  String get spaceNameHint => 'ör. Yıldız Gözlemcileri Kulübü';

  @override
  String get spaceHandleHint => 'yildizgozlemcileri';

  @override
  String get spaceDescriptionHint => 'Bu alan ne hakkında?';

  @override
  String get spaceCategoryLabel => 'KATEGORİ';

  @override
  String get spaceSpicyLabel => 'Cesur';

  @override
  String get spaceSpicyDescription =>
      'Yetişkin konular — Cesur rozetiyle gösterilir.';

  @override
  String get communityHashtagComingSoon =>
      'Etikete göre gönderiler çok yakında.';

  @override
  String get communityHashtagComingSoonBody =>
      'Şimdilik alanlara göz at ve gönderilerin içindeki etiketleri keşfet.';

  @override
  String get postTimeNow => 'şimdi';

  @override
  String postTimeMinutesShort(int n) {
    return '$n dk';
  }

  @override
  String postTimeHoursShort(int n) {
    return '$n sa';
  }

  @override
  String postTimeDaysShort(int n) {
    return '$n g';
  }

  @override
  String postTimeWeeksShort(int n) {
    return '$n hf';
  }

  @override
  String get notificationTimeJustNow => 'az önce';

  @override
  String notificationTimeMinutesAgo(int n) {
    return '$n dk önce';
  }

  @override
  String notificationTimeHoursAgo(int n) {
    return '$n sa önce';
  }

  @override
  String notificationTimeDaysAgo(int n) {
    return '$n gün önce';
  }

  @override
  String notificationTimeWeeksAgo(int n) {
    return '$n hafta önce';
  }

  @override
  String get notificationPostLiked => 'gönderini beğendi';

  @override
  String get notificationCommentLiked => 'yorumunu beğendi';

  @override
  String get notificationPostCommented => 'gönderine yorum yaptı';

  @override
  String get notificationCommentReplied => 'yorumuna yanıt verdi';

  @override
  String get notificationSpaceMemberJoined => 'alanına katıldı';

  @override
  String get notificationSpaceFollowed => 'alanını takip etmeye başladı';

  @override
  String get notificationSpaceJoinRequested =>
      'alanına katılmak için talep gönderdi';

  @override
  String get notificationSpaceJoinApproved => 'katılım talebini kabul etti';

  @override
  String get notificationSpaceJoinDeclined => 'katılım talebini reddetti';

  @override
  String get notificationPostInSpace =>
      'takip ettiğin bir alanda paylaşım yaptı';

  @override
  String get notificationMentioned => 'senden bahsetti';

  @override
  String get notificationGeneric => 'sana bir bildirim gönderdi';

  @override
  String communityProfileJoinedSpaces(int count) {
    return 'KATILDIĞI ALANLAR ($count)';
  }

  @override
  String get communityProfileNoSpaces => 'Henüz hiçbir alanda değil.';

  @override
  String communityProfileRecentPosts(int count) {
    return 'SON GÖNDERİLER ($count)';
  }

  @override
  String get communityProfileNoPosts => 'Henüz gönderi yok.';

  @override
  String get communityUnknownUser => 'Bilinmeyen kullanıcı';

  @override
  String get communityUnknownMember => 'Bilinmiyor';

  @override
  String get spaceRoleOwner => 'SAHİP';

  @override
  String get spaceRoleMod => 'MODERATÖR';

  @override
  String get spaceRoleMember => 'ÜYE';

  @override
  String get spaceJoinPending => 'Beklemede';

  @override
  String communityMembersCountCompact(String count) {
    return '$count üye';
  }

  @override
  String get aiChatSuggestedQuestionsCaps => 'ŞUNLARI SORABİLİRSİN…';

  @override
  String chatThreadsDeleteBody(String title) {
    return '\"$title\" ve tüm mesajları silinecek. Bu işlem geri alınamaz.';
  }

  @override
  String get chatThreadsHeaderTitle => 'Kozmik Sohbetler';

  @override
  String chatThreadsHeaderSubtitle(int count) {
    return '$count sohbet · haritandan besleniyor';
  }

  @override
  String get chatThreadsTapToContinue => 'Okumana devam etmek için dokun';

  @override
  String get chatThreadsEmptyTitle => 'Kozmik Bir Diyalog Başlat';

  @override
  String get chatThreadsEmptyBody =>
      'Haritan, transitler ya da anlamak istediğin\nbir an hakkında dilediğini sor.';

  @override
  String get aiMemoryTitle => 'Kozmik Hafıza';

  @override
  String get aiMemorySubtitle => 'Senin hakkında hatırladıklarım';

  @override
  String get aiMemoryLive => 'canlı';

  @override
  String get aiMemorySaturnReturnLabel => 'Satürn dönüşü (1. geçiş)';

  @override
  String get aiMemorySaturnReturnDetail => 'Şubat\'tan beri bunu 4 kez sordun.';

  @override
  String get aiMemoryCareerLabel => 'Kariyer geçişi';

  @override
  String get aiMemoryCareerDetail => 'Ürün tasarımına geçmeyi tartıyorsun.';

  @override
  String get aiMemoryPartnerLabel => 'Theo, Balık';

  @override
  String get aiMemoryPartnerDetail => 'Uyum sinastrisi kaydedildi · Eki 2024.';

  @override
  String get aiMemorySelfTrustLabel => 'Kendine güven teması';

  @override
  String get aiMemorySelfTrustDetail => '6 sohbette tekrar eden bir soru.';

  @override
  String get compatSomeone => 'Biri';

  @override
  String compatShareText(String name, int score) {
    return '$name ile kozmik uyumum %$score! Seninkini Lively\'de keşfet.';
  }

  @override
  String get compatYou => 'Sen';

  @override
  String compatYouAnd(String name) {
    return 'Sen & $name';
  }

  @override
  String get compatRelPartner => 'Partner';

  @override
  String get compatRelFriend => 'Arkadaş';

  @override
  String get compatRelFamily => 'Aile';

  @override
  String get compatRelCoworker => 'İş arkadaşı';

  @override
  String get compatRelCrush => 'Hoşlandığın kişi';

  @override
  String get compatRelOther => 'Diğer';

  @override
  String get timelineFeatureName => 'Zaman Çizelgesi Öngörüleri';

  @override
  String get lifeTimelineCatCareer => 'Kariyer';

  @override
  String get lifeTimelineCatLove => 'Aşk';

  @override
  String get lifeTimelineCatGrowth => 'Gelişim';

  @override
  String get lifeTimelineCatLoss => 'Kayıp';

  @override
  String get lifeTimelineCatTravel => 'Seyahat';

  @override
  String get lifeTimelineCatFamily => 'Aile';

  @override
  String get lifeTimelineCatReflection => 'İçe Bakış';

  @override
  String get lifeTimelineMoodElated => 'Coşkulu';

  @override
  String get lifeTimelineMoodGrounded => 'Dengede';

  @override
  String get lifeTimelineMoodOpen => 'Açık';

  @override
  String get lifeTimelineMoodPressured => 'Baskı altında';

  @override
  String get lifeTimelineMoodFree => 'Özgür';

  @override
  String get lifeTimelineMoodCleansed => 'Arınmış';

  @override
  String get lifeTimelineMoodTender => 'Hassas';

  @override
  String get lifeTimelineMoodResolved => 'Kararlı';

  @override
  String get lifeTimelineAddTitle => 'Bir An Ekle';

  @override
  String get lifeTimelineAddSubtitle => 'Hatırlamaya değer bir dönüm noktası.';

  @override
  String get lifeTimelineFieldTitle => 'Başlık';

  @override
  String get lifeTimelineFieldTitleHint => 'ör. Teklifi aldım';

  @override
  String get lifeTimelineFieldWhen => 'Ne zaman';

  @override
  String get lifeTimelineFieldCategory => 'Kategori';

  @override
  String get lifeTimelineFieldMood => 'Nasıl hissettirdi?';

  @override
  String get lifeTimelineFieldNotes => 'Notlar';

  @override
  String get lifeTimelineFieldNotesHint => 'Neler oluyordu, ne değişti...';

  @override
  String get lifeTimelineSaveMoment => 'Anı Kaydet';

  @override
  String get lifeTimelineTransitPending => 'Transit hesaplaması bekleniyor';

  @override
  String get lifeTimelineMock1Title => 'Teklifi aldım';

  @override
  String get lifeTimelineMock1Desc =>
      'Tasarım stüdyosundaki kıdemli pozisyonu kabul ettim. Uğruna çalıştığım her şey birden yerine oturmuş gibi hissettim.';

  @override
  String get lifeTimelineMock1Transit1 => 'Jüpiter, natal MC ile üçgen';

  @override
  String get lifeTimelineMock1Transit2 => 'Venüs 10. evde';

  @override
  String get lifeTimelineMock2Title => 'Yengeç Yeni Ayı inzivası';

  @override
  String get lifeTimelineMock2Desc =>
      'Joshua Tree\'de şebekeden uzak üç gün. 40 sayfa günlük yazdım. Gerçekten ne istediğime dair berrak bir netlikle döndüm.';

  @override
  String get lifeTimelineMock2Transit1 => 'Yeni Ay, natal Ay ile kavuşumda';

  @override
  String get lifeTimelineMock2Transit2 => 'Merkür 4. evde retro';

  @override
  String get lifeTimelineMock3Title => 'Theo ile tanıştım';

  @override
  String get lifeTimelineMock3Desc =>
      'Saat 4\'teki kahve akşam yemeğine, akşam yemeği uzun bir yürüyüşe dönüştü. Taklit edilemeyecek türden bir tanışıklık hissettim.';

  @override
  String get lifeTimelineMock3Transit1 => 'Venüs, natal Güneş ile üçgen';

  @override
  String get lifeTimelineMock3Transit2 => 'Güneş 7. evde';

  @override
  String get lifeTimelineMock4Title => 'Satürn dönüşü başlıyor';

  @override
  String get lifeTimelineMock4Desc =>
      'İlk dalga vurdu. Her bağlılığımı yeniden değerlendiriyorum. Hangi yapıların yıkılması gerektiğini hissetmeye başlıyorum.';

  @override
  String get lifeTimelineMock4Transit1 =>
      'Satürn, natal Satürn ile kavuşumda (1. geçiş)';

  @override
  String get lifeTimelineMock5Title => 'Lizbon yolculuğu';

  @override
  String get lifeTimelineMock5Desc =>
      'Defterimle baş başa iki hafta. Kaygımın ne kadarının sadece sürekli bağlı olmaktan geldiğini fark ettim.';

  @override
  String get lifeTimelineMock5Transit1 => 'Jüpiter 9. evde';

  @override
  String get lifeTimelineMock5Transit2 => 'Mars, Merkür ile üçgen';

  @override
  String get lifeTimelineMock6Title => 'Kira sözleşmesini bitirdim';

  @override
  String get lifeTimelineMock6Desc =>
      'Daireden taşındım. Daha az alana ve daha az bağlılığa ihtiyacım olduğuna karar verdim. Satürn haklıydı.';

  @override
  String get lifeTimelineMock6Transit1 => 'Satürn, natal Ay ile kare';

  @override
  String get lifeTimelineMock6Transit2 => 'Plüton, natal Venüs ile karşıt';

  @override
  String get destinyMatrixTitle => 'Kader Matrisi';

  @override
  String get destinyYourOctagram => 'Oktagramın';

  @override
  String get destinyPurpose => 'Amaç';

  @override
  String get destinyTheLines => 'Çizgiler';

  @override
  String get destinyYourCoreArcana => 'ÇEKİRDEK ARKANAN';

  @override
  String destinyBirthDate(String date) {
    return 'Doğum tarihi $date';
  }

  @override
  String get destinyComfortCore => 'Konfor / Çekirdek';

  @override
  String get destinyMaleGenerationLine => 'erkek soy hattı';

  @override
  String get destinyFemaleGenerationLine => 'kadın soy hattı';

  @override
  String get destinyTapNodeHint =>
      'Arkanasını okumak için herhangi bir noktaya dokun.';

  @override
  String destinyArcanaNumber(int n) {
    return 'Arkana $n';
  }

  @override
  String get destinySkyPurpose => 'Gökyüzü Amacı';

  @override
  String get destinyEarthPurpose => 'Dünya Amacı';

  @override
  String get destinyPersonalPurpose => 'Kişisel Amaç';

  @override
  String get psychoTitle => 'Pisagor Karesi';

  @override
  String get psychoYourMatrix => 'Matrisin';

  @override
  String get psychoLinesStrengths => 'Çizgiler ve Güçler';

  @override
  String get psychoWorkingNumbers => 'ÇALIŞMA SAYILARI';

  @override
  String psychoBirthDate(String date) {
    return 'Doğum tarihi $date';
  }

  @override
  String psychoWorkingShort(int n) {
    return 'Ç$n';
  }

  @override
  String get psychoTapCellHint =>
      'Anlamını okumak için herhangi bir hücreye dokun.';

  @override
  String get psychoAbsent => 'Yok';

  @override
  String psychoCellCount(String digits, int count) {
    return '$digits  ·  $count kez';
  }

  @override
  String psychoCellsList(String cells) {
    return 'Hücreler $cells';
  }

  @override
  String get numerologyCompatPartnerNameLabel => 'PARTNERİNİN TAM DOĞUM ADI';

  @override
  String get numerologyCompatPartnerNameHint => 'ör. Ayşe Nur Yılmaz';

  @override
  String get numerologyCompatPartnerBirthDateLabel =>
      'PARTNERİNİN DOĞUM TARİHİ';

  @override
  String get numerologyCompatTapToPick => 'Seçmek için dokun';

  @override
  String get numerologyCompatCalculating => 'Hesaplanıyor…';

  @override
  String get numerologyCompatCompute => 'Uyumu hesapla';

  @override
  String get numerologyCompatMatch => 'Uyum';

  @override
  String get numerologyKarmicLessonsHeader => 'KARMİK DERSLER';

  @override
  String get numerologyKarmicNoneMissing =>
      'İsmin her rakamı taşıyor — eksik ders yok.';

  @override
  String get numerologyKarmicMissingBlurb =>
      'İsminde eksik olan sayılar, bu hayatta öğrenmeye geldiğin alanları gösterir.';

  @override
  String get numerologyHiddenPassionHeader => 'GİZLİ TUTKU';

  @override
  String get numerologyHiddenPassionNone =>
      'Baskın bir rakam yok — ismin tüm yelpazede dengeli.';

  @override
  String numerologyHiddenPassionBlurb(int number) {
    return 'En güçlü armağanın $number enerjisi — isminde en sık görünen rakam.';
  }

  @override
  String get numerologyTodayHeader => 'BUGÜN';

  @override
  String get numerologyPersonalYear => 'Kişisel Yıl';

  @override
  String get numerologyPersonalMonth => 'Kişisel Ay';

  @override
  String get numerologyPersonalDay => 'Kişisel Gün';

  @override
  String get numerologyPinnaclesHeader => 'ZİRVELER — hayatının temaları';

  @override
  String numerologyPinnacleN(int n) {
    return 'Zirve $n';
  }

  @override
  String get numerologyChallengesHeader => 'ZORLUKLAR — büyüme alanların';

  @override
  String numerologyChallengeN(int n) {
    return 'Zorluk $n';
  }

  @override
  String numerologyCurrentAgeNote(int age) {
    return '$age yaşındasın — aktif döngü vurgulandı.';
  }

  @override
  String numerologyAgeFrom(int start) {
    return '$start+ yaş';
  }

  @override
  String numerologyAgeRange(int start, int end) {
    return '$start–$end yaş';
  }

  @override
  String get numerologyNowBadge => 'ŞİMDİ';

  @override
  String get numerologyMasterChip => 'Usta';

  @override
  String numerologyKarmicChip(int number) {
    return 'Karmik $number';
  }

  @override
  String get hdYouAre => 'SENİN TİPİN';

  @override
  String get hdStrategy => 'Strateji';

  @override
  String get hdAuthority => 'Otorite';

  @override
  String get hdDefinition => 'Tanım';

  @override
  String hdNotSelfTheme(String theme) {
    return 'Öz-olmayan teması: $theme';
  }

  @override
  String get hdVariablesHeader => 'DEĞİŞKENLER (PRA)';

  @override
  String get hdVarDigestion => 'Sindirim';

  @override
  String get hdVarEnvironment => 'Çevre';

  @override
  String get hdVarAwareness => 'Farkındalık';

  @override
  String get hdVarPerspective => 'Perspektif';

  @override
  String get hdDirectionLeft => 'Sol';

  @override
  String get hdDirectionRight => 'Sağ';

  @override
  String get hdCenterDefinedBadge => 'TANIMLI';

  @override
  String get hdCenterOpenBadge => 'AÇIK';

  @override
  String hdGateN(int n) {
    return 'Kapı $n';
  }

  @override
  String get hdIncarnationCross => 'ENKARNASYON HAÇI';

  @override
  String hdQuarterOf(String quarter) {
    return '$quarter Çeyreği';
  }

  @override
  String hdCrossOf(String gates) {
    return '$gates Haçı';
  }

  @override
  String get hdCrossPersonalitySun => 'K-Güneş';

  @override
  String get hdCrossPersonalityEarth => 'K-Dünya';

  @override
  String get hdCrossDesignSun => 'T-Güneş';

  @override
  String get hdCrossDesignEarth => 'T-Dünya';

  @override
  String get hdPersonalityHeader => 'KİŞİLİK';

  @override
  String get hdDesignHeader => 'TASARIM';

  @override
  String get hdTypeManifestor => 'Manifestör';

  @override
  String get hdTypeGenerator => 'Jeneratör';

  @override
  String get hdTypeManifestingGenerator => 'Manifeste Eden Jeneratör';

  @override
  String get hdTypeProjector => 'Projektör';

  @override
  String get hdTypeReflector => 'Yansıtıcı';

  @override
  String get hdStrategyInform => 'Harekete geçmeden önce bilgilendir';

  @override
  String get hdStrategyRespond => 'Yanıt vermeyi bekle';

  @override
  String get hdStrategyRespondInform =>
      'Yanıt vermeyi bekle, sonra bilgilendir';

  @override
  String get hdStrategyInvitation => 'Davet edilmeyi bekle';

  @override
  String get hdStrategyLunarCycle => 'Bir ay döngüsü bekle (28 gün)';

  @override
  String get hdAuthorityEmotional => 'Duygusal';

  @override
  String get hdAuthoritySacral => 'Sakral';

  @override
  String get hdAuthoritySplenic => 'Dalak';

  @override
  String get hdAuthorityEgo => 'Ego';

  @override
  String get hdAuthoritySelfProjected => 'Kendinden Yansıtılan';

  @override
  String get hdAuthorityMental => 'Zihinsel';

  @override
  String get hdAuthorityLunar => 'Ay';

  @override
  String get hdDefinitionNone => 'Yok';

  @override
  String get hdDefinitionSingle => 'Tekli';

  @override
  String get hdDefinitionSplit => 'Bölünmüş';

  @override
  String get hdDefinitionTripleSplit => 'Üçlü Bölünmüş';

  @override
  String get hdDefinitionQuadrupleSplit => 'Dörtlü Bölünmüş';

  @override
  String get hdNotSelfAnger => 'Öfke';

  @override
  String get hdNotSelfFrustration => 'Hüsran';

  @override
  String get hdNotSelfFrustrationAnger => 'Hüsran ve Öfke';

  @override
  String get hdNotSelfBitterness => 'Burukluk';

  @override
  String get hdNotSelfDisappointment => 'Hayal kırıklığı';

  @override
  String get hdCenterHead => 'Baş';

  @override
  String get hdCenterAjna => 'Ajna';

  @override
  String get hdCenterThroat => 'Boğaz';

  @override
  String get hdCenterG => 'G/Kimlik';

  @override
  String get hdCenterHeart => 'Kalp/Ego';

  @override
  String get hdCenterSacral => 'Sakral';

  @override
  String get hdCenterSolarPlexus => 'Solar Pleksus';

  @override
  String get hdCenterSpleen => 'Dalak';

  @override
  String get hdCenterRoot => 'Kök';

  @override
  String get hdCenterThemeHead => 'İlham · bilme baskısı';

  @override
  String get hdCenterThemeAjna => 'Kavramsallaştırma · kesinlik ve şüphe';

  @override
  String get hdCenterThemeThroat => 'Tezahür · ifade';

  @override
  String get hdCenterThemeG => 'Kimlik · sevgi · yön';

  @override
  String get hdCenterThemeHeart => 'İrade gücü · ego · kaynaklar';

  @override
  String get hdCenterThemeSacral =>
      'Yaşam gücü · sürdürülebilir emek · cinsellik';

  @override
  String get hdCenterThemeSolarPlexus => 'Duygusal dalga · hisler · berraklık';

  @override
  String get hdCenterThemeSpleen => 'Sezgi · sağlık · hayatta kalma';

  @override
  String get hdCenterThemeRoot => 'Baskı · adrenalin · itici güç';

  @override
  String get hdQuarterInitiation => 'İnisiyasyon';

  @override
  String get hdQuarterCivilization => 'Medeniyet';

  @override
  String get hdQuarterDuality => 'Dualite';

  @override
  String get hdQuarterMutation => 'Mutasyon';

  @override
  String get hdBodySun => 'Güneş';

  @override
  String get hdBodyEarth => 'Dünya';

  @override
  String get hdBodyNorthNode => 'Kuzey Ay Düğümü';

  @override
  String get hdBodySouthNode => 'Güney Ay Düğümü';

  @override
  String get hdBodyMoon => 'Ay';

  @override
  String get hdBodyMercury => 'Merkür';

  @override
  String get hdBodyVenus => 'Venüs';

  @override
  String get hdBodyMars => 'Mars';

  @override
  String get hdBodyJupiter => 'Jüpiter';

  @override
  String get hdBodySaturn => 'Satürn';

  @override
  String get hdBodyUranus => 'Uranüs';

  @override
  String get hdBodyNeptune => 'Neptün';

  @override
  String get hdBodyPluto => 'Plüton';

  @override
  String get hdChannelInspiration => 'İlham';

  @override
  String get hdChannelTheBeat => 'Nabız';

  @override
  String get hdChannelMutation => 'Mutasyon';

  @override
  String get hdChannelLogic => 'Mantık';

  @override
  String get hdChannelRhythm => 'Ritim';

  @override
  String get hdChannelMating => 'Çiftleşme';

  @override
  String get hdChannelAlpha => 'Alfa (Liderlik)';

  @override
  String get hdChannelConcentration => 'Konsantrasyon';

  @override
  String get hdChannelAwakening => 'Uyanış';

  @override
  String get hdChannelExploration => 'Keşif';

  @override
  String get hdChannelPerfectedForm => 'Kusursuz Form';

  @override
  String get hdChannelCuriosity => 'Merak';

  @override
  String get hdChannelOpenness => 'Açıklık';

  @override
  String get hdChannelTheProdigal => 'Müsrif Evlat';

  @override
  String get hdChannelTheWavelength => 'Dalga Boyu';

  @override
  String get hdChannelAcceptance => 'Kabul';

  @override
  String get hdChannelJudgement => 'Yargı';

  @override
  String get hdChannelSynthesis => 'Sentez';

  @override
  String get hdChannelCharisma => 'Karizma';

  @override
  String get hdChannelTheBrainWave => 'Beyin Dalgası';

  @override
  String get hdChannelMoneyLine => 'Para Hattı';

  @override
  String get hdChannelStructuring => 'Yapılandırma';

  @override
  String get hdChannelAwareness => 'Farkındalık';

  @override
  String get hdChannelInitiation => 'İnisiyasyon';

  @override
  String get hdChannelSurrender => 'Teslimiyet';

  @override
  String get hdChannelPreservation => 'Koruma';

  @override
  String get hdChannelStruggle => 'Mücadele';

  @override
  String get hdChannelDiscovery => 'Buluş';

  @override
  String get hdChannelRecognition => 'Tanınma';

  @override
  String get hdChannelTransformation => 'Dönüşüm';

  @override
  String get hdChannelPower => 'Güç';

  @override
  String get hdChannelTransitoriness => 'Geçicilik';

  @override
  String get hdChannelCommunity => 'Topluluk';

  @override
  String get hdChannelEmoting => 'Duygulanım';

  @override
  String get hdChannelMaturation => 'Olgunlaşma';

  @override
  String get hdChannelAbstraction => 'Soyutlama';

  @override
  String get homeChartPsychomatrix => 'Pisagor Karesi';

  @override
  String get homeChartPsychomatrixSubtitle =>
      'Doğum tarihine göre psikomatriksin';

  @override
  String get homeChartDestinyMatrix => 'Kader Matrisi';

  @override
  String get homeChartDestinyMatrixSubtitle => '22 arkanalı oktagramın';

  @override
  String get homePremiumPlanTitle => 'Premium Plan';

  @override
  String get homePremiumPlanBody =>
      'Sınırsız AI öngörüleri, öncelikli\nrezervasyon ve özel içeriklerin kilidini aç.';

  @override
  String get homePremiumPlanCta => 'Planı Yükselt';

  @override
  String get homePopularAstrologers => 'Popüler Astrologlar';

  @override
  String get homeTodaysEnergyLabel => 'BUGÜNÜN ENERJİSİ';

  @override
  String get homeDailyEnergyHeadline =>
      'İçsel yansıma ve yaratıcı ifade için bir gün';

  @override
  String get homeDailyEnergyBody =>
      'Balık burcundaki Ay sezgilerini güçlendiriyor. Bugün içgüdülerine güven, özellikle de önemli konuşmalarda.';

  @override
  String get homeModerateEnergy => 'Orta Enerji';

  @override
  String get homeQuickAiChat => 'AI Sohbet';

  @override
  String get homeQuickFullChart => 'Tam Harita';

  @override
  String get homeKeepItUp => 'Böyle devam!';

  @override
  String get homeWeekdayInitialMon => 'P';

  @override
  String get homeWeekdayInitialTue => 'S';

  @override
  String get homeWeekdayInitialWed => 'Ç';

  @override
  String get homeWeekdayInitialThu => 'P';

  @override
  String get homeWeekdayInitialFri => 'C';

  @override
  String get homeWeekdayInitialSat => 'C';

  @override
  String get homeWeekdayInitialSun => 'P';

  @override
  String get homeSampleAffirmation =>
      'Hayatımın zamanlamasına güveniyorum. Bana ait olan beni bulacak.';

  @override
  String get homeDailyAffirmationLabel => 'GÜNLÜK OLUMLAMA';

  @override
  String get skyMoonNew => 'Yeni Ay';

  @override
  String get skyMoonWaxingCrescent => 'Büyüyen Hilal';

  @override
  String get skyMoonFirstQuarter => 'İlk Dördün';

  @override
  String get skyMoonWaxingGibbous => 'Büyüyen Şişkin Ay';

  @override
  String get skyMoonFull => 'Dolunay';

  @override
  String get skyMoonWaningGibbous => 'Küçülen Şişkin Ay';

  @override
  String get skyMoonLastQuarter => 'Son Dördün';

  @override
  String get skyMoonWaningCrescent => 'Küçülen Hilal';

  @override
  String get dailyEnergyRingLabel => 'enerji';

  @override
  String profileBirthDataLoadError(String error) {
    return 'Doğum bilgilerin yüklenemedi: $error';
  }

  @override
  String get ritualsDailyRitualsFeature => 'Günlük Ritüeller';

  @override
  String dailyShareText(String affirmation, String color) {
    return '\"$affirmation\"\n\nBugünkü şans rengim: $color\n\n~ Lively';
  }
}
