import 'package:shared_preferences/shared_preferences.dart';

/// Runtime override for the dev API base URL.
///
/// `String.fromEnvironment` is compile-time, so the LAN IP baked into
/// `env.dart` survives a hot reload but not a WiFi reassignment — every
/// time the dev machine's IP changes the app needs a full rebuild
/// before it can talk to the backend again. This class persists a
/// user-supplied override in SharedPreferences so a stale binary can
/// be redirected at runtime via the Settings screen.
///
/// Loaded once at app start (see `main.dart`) and then read
/// synchronously from [current]; writes go straight to disk via [set].
class ApiUrlOverride {
  ApiUrlOverride._();

  static const _key = 'api_base_url_override';

  static String? _cached;

  /// Last-loaded override, or null if none is set. Synchronously
  /// readable so callers like [ApiClient] don't need to be async.
  static String? get current => _cached;

  /// Hydrate from disk. Call once at startup before constructing
  /// anything that reads the API base URL.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v != null && v.trim().isNotEmpty) {
      _cached = v.trim();
    }
  }

  /// Persist a new override. Pass null or an empty string to clear it
  /// (so the app falls back to the compile-time default in env.dart).
  static Future<void> set(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final v = value?.trim();
    if (v == null || v.isEmpty) {
      await prefs.remove(_key);
      _cached = null;
      return;
    }
    await prefs.setString(_key, v);
    _cached = v;
  }
}
