import 'dart:ui';

/// Module-level current locale code, stamped on every outgoing API request
/// via the Dio Accept-Language header. Kept as a plain global so the
/// interceptor can read it synchronously without threading a provider ref
/// through every service constructor.
///
/// [LocaleNotifier] writes to this on load and on user change; before
/// either fires, we fall back to the platform's UI locale, then English.
String _currentLocaleCode = _initialFromPlatform();

String get currentLocaleCode => _currentLocaleCode;

void setCurrentLocaleCode(String? code) {
  final normalized = _normalize(code);
  if (normalized != null) {
    _currentLocaleCode = normalized;
    return;
  }
  _currentLocaleCode = _initialFromPlatform();
}

String _initialFromPlatform() {
  final tag = PlatformDispatcher.instance.locale.languageCode;
  return _normalize(tag) ?? 'en';
}

/// Only 'en' and 'tr' are supported today. Anything else collapses to null
/// so we fall back rather than sending an unsupported code to the backend.
String? _normalize(String? code) {
  if (code == null || code.isEmpty) return null;
  final lower = code.toLowerCase().split(RegExp('[-_]')).first;
  if (lower == 'tr' || lower == 'en') return lower;
  return null;
}
