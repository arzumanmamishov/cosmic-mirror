import 'package:cosmic_mirror/config/env.dart';

/// Resolves a stored `avatar_url` value to an absolute URL safe to
/// hand to [CachedNetworkImage] or [Image.network].
///
/// The backend stores avatars as relative paths like
/// `/uploads/avatars/{id}_{ts}.jpg?v=...` (the `?v=...` is our
/// cache-buster). The image widgets need an absolute URL, so we
/// prefix the active API base. Already-absolute http(s) URLs are
/// returned as-is so this still works the day storage moves to
/// S3 / GCS / a CDN.
///
/// Returns null on an empty input so callers can do
/// `if (url != null) CachedNetworkImage(imageUrl: url)` without
/// guarding the empty case themselves.
String? resolveAvatarUrl(String? urlOrPath) {
  if (urlOrPath == null || urlOrPath.isEmpty) return null;
  if (urlOrPath.startsWith('http://') ||
      urlOrPath.startsWith('https://')) {
    return urlOrPath;
  }
  final base = Env.apiBaseUrl;
  final trimmed =
      base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$trimmed$urlOrPath';
}
