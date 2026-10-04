import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/community/domain/entities/blocked_user.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/moderation_actions.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Blocked users: everyone the current user blocked in the
/// Community, each with an Unblock button.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final blockedAsync = ref.watch(blockedUsersProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l.blockedUsersTitle),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 40,
              intensity: 0.5,
            ),
          ),
          blockedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 100),
              child: ShimmerList(itemCount: 4),
            ),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(blockedUsersProvider),
            ),
            data: (users) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(blockedUsersProvider),
              child: users.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(32, 160, 32, 32),
                      children: [
                        Icon(Icons.block_rounded, size: 40, color: p.textDim),
                        const SizedBox(height: 14),
                        Text(
                          l.blockedUsersEmptyTitle,
                          textAlign: TextAlign.center,
                          style: LivelyType.h1(p.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.blockedUsersEmptyBody,
                          textAlign: TextAlign.center,
                          style: LivelyType.small(p.textMuted),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _BlockedUserTile(user: users[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUserTile extends StatefulWidget {
  const _BlockedUserTile({required this.user});
  final BlockedUser user;

  @override
  State<_BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends State<_BlockedUserTile> {
  bool _busy = false;

  Future<void> _unblock() async {
    setState(() => _busy = true);
    // On success the list refetches and this tile goes away.
    final ok = await unblockUser(
      context,
      userId: widget.user.userId,
      name: widget.user.name,
    );
    if (!ok && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final u = widget.user;
    final name = u.name.isEmpty ? l.communityUnknownUser : u.name;
    final avatar = resolveAvatarUrl(u.avatarUrl);
    Widget initial() => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: p.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.glassBorder),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 38,
              height: 38,
              child: avatar == null
                  ? initial()
                  : CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => initial(),
                      errorWidget: (_, __, ___) => initial(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LivelyType.body(p.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _unblock,
            child: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.blockUnblock),
          ),
        ],
      ),
    );
  }
}
