import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeHeaderBar extends ConsumerWidget {
  const HomeHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Avatar with gradient ring — shows the user's uploaded
          // photo when one is set, falls back to their initial inside
          // a tinted circle. Tapping opens Profile.
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: p.primaryGradient,
              ),
              child: ClipOval(
                child: _AvatarImage(
                  avatarUrl: user.avatarUrl,
                  initial: _initial(user.name),
                  palette: p,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? AppLocalizations.of(context).stargazer,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).homeWelcomeBack,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('✨', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          _IconButton(
            icon: Icons.notifications_rounded,
            onTap: () => context.push('/community/notifications'),
            hasBadge: true,
          ),
        ],
      ),
    );
  }

  String _initial(String? name) {
    if (name == null || name.isEmpty) return '✨';
    return name.trim().substring(0, 1).toUpperCase();
  }
}

/// The actual avatar image (network) with a graceful fallback to the
/// user's initial inside a tinted circle when no photo is set OR the
/// network fetch fails (offline / 404 / broken URL).
class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.avatarUrl,
    required this.initial,
    required this.palette,
  });

  final String? avatarUrl;
  final String initial;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAvatarUrl(avatarUrl);
    if (resolved == null) return _initialFallback();
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: BoxFit.cover,
      width: 44,
      height: 44,
      placeholder: (_, __) => _initialFallback(),
      errorWidget: (_, __, ___) => _initialFallback(),
    );
  }

  Widget _initialFallback() {
    return Container(
      color: palette.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: p.glassBorder),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: p.textPrimary, size: 20),
          ),
          if (hasBadge)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.background, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
