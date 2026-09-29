import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/config/theme/macos_colors.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/join_button.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Space card — the hero of the spaces list. Avatar + name + verified
/// check + Spicy badge on top, handle underneath, a two-line description,
/// then a footer with the member count and the Join button.
class SpaceCard extends StatelessWidget {
  const SpaceCard({required this.space, super.key});

  final SpaceWithMeta space;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final s = space.space;
    final hasDescription = s.description != null && s.description!.isNotEmpty;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(LivelyRadius.xl),
      child: InkWell(
        onTap: () => context.push('/community/${s.id}'),
        borderRadius: BorderRadius.circular(LivelyRadius.xl),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LivelyRadius.xl),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(name: s.name, url: s.avatarUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.name,
                                style: LivelyType.h2(p.textPrimary)
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (s.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: p.primary,
                              ),
                            ],
                            if (s.isSpicy) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: p.warning.withValues(alpha: 0.16),
                                  borderRadius:
                                      BorderRadius.circular(LivelyRadius.full),
                                ),
                                child: Text(
                                  l.spaceSpicyLabel,
                                  style: TextStyle(
                                    color: p.warning,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${s.handle}',
                          style: LivelyType.small(p.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 12),
                Text(
                  s.description!,
                  style: LivelyType.small(p.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: p.line),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.people_alt_outlined, size: 15, color: p.textDim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _membersLabel(context, l, s.memberCount),
                      style: LivelyType.small(p.textMuted),
                    ),
                  ),
                  JoinButton(
                    spaceId: s.id,
                    initialJoined: space.isJoined,
                    initialPending: space.isPending,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _membersLabel(BuildContext context, AppLocalizations l, int n) {
    if (n < 1000) return l.communityMembersCount(n);
    final compact = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    ).format(n);
    return l.communityMembersCountCompact(compact);
  }
}

/// Space avatar: the uploaded image when there is one, otherwise the
/// initial on a stable per-space macOS hue.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final hue = MacOSColors.of(context).hueFor(name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final resolved = resolveAvatarUrl(url);
    Widget fallback() => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [hue.withValues(alpha: 0.85), hue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(LivelyRadius.lg),
      child: SizedBox(
        width: 46,
        height: 46,
        child: resolved == null
            ? fallback()
            : CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback(),
                errorWidget: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}
