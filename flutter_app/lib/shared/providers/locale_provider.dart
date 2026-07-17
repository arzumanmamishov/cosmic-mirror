import 'package:cosmic_mirror/core/network/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocalePrefsKey = 'app.localeCode';

/// App locale, persisted to SharedPreferences. `null` means "follow the
/// device" — Flutter uses the system locale and falls back to English
/// for unsupported languages.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier()..load();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null);

  /// Restore any previously-saved locale on app start. Silently no-ops if
  /// nothing is saved — we let Flutter pick the device locale.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocalePrefsKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
      setCurrentLocaleCode(code);
    } else {
      // No override — mirror the platform locale into the module global so
      // the Accept-Language header still tracks the user's device setting.
      setCurrentLocaleCode(null);
    }
  }

  /// Persist and apply [locale]. Pass `null` to clear the override and
  /// fall back to the device locale.
  Future<void> set(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kLocalePrefsKey);
    } else {
      await prefs.setString(_kLocalePrefsKey, locale.languageCode);
    }
    state = locale;
    setCurrentLocaleCode(locale?.languageCode);
  }
}
