import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/config/theme/macos_colors.dart';
import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/compose_post_sheet.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/join_button.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/moderation_actions.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/post_card.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// A single space: avatar header, stats, join action,
/// then the members-only post feed (or a locked placeholder).
class SpaceDetailScreen extends ConsumerWidget {
  const SpaceDetailScreen({required this.spaceId, super.key});

  final String spaceId;

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComposePostSheet(spaceId: spaceId),
    );
    ref.invalidate(spacePostsProvider(spaceId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final spaceAsync = ref.watch(spaceDetailProvider(spaceId));
    final currentUserId = ref.watch(
      currentUserProvider.select((s) => s.id),
    );

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const _GlassIconButton(back: true),
        actions: [
          spaceAsync.maybeWhen(
            orElse: () => const SizedBox.shrink(),
            data: (s) {
              final isOwner =
                  currentUserId != null && currentUserId == s.space.createdBy;
              // Always shown: everyone but the owner can report the space.
              return _GlassIconButton(
                icon: Icons.more_horiz_rounded,
                tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                onPressed: () => _showOverflow(
                  context,
                  s.space.id,
                  isOwner: isOwner,
                  isJoined: s.isJoined,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // The compose-post FAB is only shown to approved members. Pending
      // requesters and non-members would hit a 403 on submit, so we hide
      // the affordance entirely rather than let them tap into a dead end.
      floatingActionButton: spaceAsync.maybeWhen(
        orElse: () => null,
        data: (s) => s.isJoined
            ? _ComposeFab(onPressed: () => _compose(context, ref))
            : null,
      ),
      body: LivelyBackdrop(
        seed: 31,
        intensity: 0.6,
        child: spaceAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 120),
            child: ShimmerList(itemCount: 4),
          ),
          error: (e, _) => Center(
            child: ErrorView(
              error: e,
              onRetry: () => ref.invalidate(spaceDetailProvider(spaceId)),
            ),
          ),
          data: (s) => RefreshIndicator(
            color: p.primary,
            backgroundColor: p.surface,
            edgeOffset: 100,
            onRefresh: () async {
              ref.invalidate(spaceDetailProvider(spaceId));
              if (s.isJoined) {
                ref.invalidate(spacePostsProvider(spaceId));
              }
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _Header(space: s)),
                // Content is gated: posts are only fetched + shown to
                // approved members. Pending and never-joined users see
                // a locked-content placeholder explaining what to do.
                if (s.isJoined) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _ComposePrompt(
                        onTap: () => _compose(context, ref),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        AppLocalizations.of(context)
                            .spacePostsHeader
                            .toUpperCase(),
                        style: LivelyType.kicker(p.textMuted),
                      ),
                    ),
                  ),
                  _PostList(spaceId: spaceId),
                ] else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    sliver: SliverToBoxAdapter(
                      child: _LockedContent(space: s),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOverflow(
    BuildContext context,
    String spaceId, {
    required bool isOwner,
    required bool isJoined,
  }) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    Widget item(IconData icon, String label, String route) => ListTile(
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(LivelyRadius.md),
            ),
            child: Icon(icon, color: p.primary, size: 19),
          ),
          title: Text(
            label,
            style: LivelyType.body(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: p.textDim),
          onTap: () {
            Navigator.pop(context);
            context.push(route);
          },
        );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(LivelyRadius.xl2)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isJoined || isOwner)
                item(
                  Icons.group_rounded,
                  l.communityMembers,
                  '/community/$spaceId/members',
                ),
              if (!isOwner)
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(LivelyRadius.md),
                    ),
                    child: Icon(Icons.flag_outlined, color: p.error, size: 19),
                  ),
                  title: Text(
                    l.reportSpace,
                    style: LivelyType.body(p.error)
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showReportSheet(
                      context,
                      target: ReportTarget.space,
                      targetId: spaceId,
                    );
                  },
                ),
              if (isOwner) ...[
                item(
                  Icons.how_to_reg_rounded,
                  l.spaceManageRequests,
                  '/community/$spaceId/requests',
                ),
                item(
                  Icons.edit_rounded,
                  l.communityEditSpace,
                  '/community/$spaceId/edit',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar, then name / handle / stats / description / actions.
class _Header extends ConsumerWidget {
  const _Header({required this.space});
  final SpaceWithMeta space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final s = space.space;
    final hue = MacOSColors.of(context).hueFor(s.name);
    final topInset = MediaQuery.paddingOf(context).top;
    const avatarSize = 84.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 64, 20, 0),
          child: _SpaceAvatar(
            name: s.name,
            url: s.avatarUrl,
            hue: hue,
            size: avatarSize,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      s.name,
                      style: LivelyType.d3(p.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (s.isVerified) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 20, color: p.primary),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text('@${s.handle}', style: LivelyType.small(p.textMuted)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    icon: Icons.people_alt_rounded,
                    label: _membersLabel(context, l, s.memberCount),
                    // Member lists are members-only on the server.
                    onTap: space.isJoined
                        ? () => context.push('/community/${s.id}/members')
                        : null,
                  ),
                  if (s.isSpicy)
                    _StatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: l.spaceSpicyLabel,
                      color: p.warning,
                    ),
                ],
              ),
              if (s.description != null && s.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(s.description!, style: LivelyType.body(p.textMuted)),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  JoinButton(
                    spaceId: s.id,
                    initialJoined: space.isJoined,
                    initialPending: space.isPending,
                    compact: false,
                    // Re-fetch so the feed / locked placeholder below
                    // follows the new membership state.
                    onChanged: (_) => ref.invalidate(spaceDetailProvider(s.id)),
                  ),
                  if (space.isJoined) ...[
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      icon: Icons.group_outlined,
                      tooltip: l.communityMembers,
                      onPressed: () =>
                          context.push('/community/${s.id}/members'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
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

class _SpaceAvatar extends StatelessWidget {
  const _SpaceAvatar({
    required this.name,
    required this.url,
    required this.hue,
    required this.size,
  });

  final String name;
  final String? url;
  final Color hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final resolved = resolveAvatarUrl(url);
    Widget fallback() => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [hue.withValues(alpha: 0.85), hue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(LivelyRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: hue.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LivelyRadius.xl2 - 3),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.textMuted;
    return Material(
      color: color == null ? p.surface : c.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(LivelyRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LivelyRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: c),
              const SizedBox(width: 6),
              Text(
                label,
                style: LivelyType.small(color ?? p.textPrimary)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round translucent icon button that stays legible over the banner.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    this.icon,
    this.onPressed,
    this.tooltip,
    this.back = false,
  });

  final IconData? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Material(
        color: p.surface.withValues(alpha: 0.7),
        shape: CircleBorder(side: BorderSide(color: p.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: back ? () => Navigator.maybePop(context) : onPressed,
          child: Tooltip(
            message: back
                ? MaterialLocalizations.of(context).backButtonTooltip
                : (tooltip ?? ''),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                back ? Icons.arrow_back_ios_new_rounded : icon,
                size: back ? 17 : 20,
                color: p.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "What's on your mind?" row that opens the compose sheet.
class _ComposePrompt extends ConsumerWidget {
  const _ComposePrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final user = ref.watch(currentUserProvider);
    final name = user.name ?? '';
    final url = resolveAvatarUrl(user.avatarUrl);
    final hue = MacOSColors.of(context).hueFor(name);
    Widget fallback() => ColoredBox(
          color: hue.withValues(alpha: 0.2),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: hue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(LivelyRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LivelyRadius.full),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LivelyRadius.full),
            border: Border.all(color: p.line),
          ),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: url == null
                      ? fallback()
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => fallback(),
                          errorWidget: (_, __, ___) => fallback(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).communityComposeHint,
                  style: LivelyType.body(p.textDim),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_rounded, size: 17, color: p.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeFab extends StatelessWidget {
  const _ComposeFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: AppLocalizations.of(context).communityNewPost,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: p.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(Icons.edit_rounded, color: p.onPrimary, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Posts list for approved members. Pulled into its own widget so the
/// gated branch in `build` doesn't even subscribe to spacePostsProvider
/// — that way pending viewers don't burn a 403 round-trip just by
/// opening the space.
class _PostList extends ConsumerWidget {
  const _PostList({required this.spaceId});
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final postsAsync = ref.watch(spacePostsProvider(spaceId));
    return postsAsync.when(
      loading: () => const SliverToBoxAdapter(child: ShimmerList()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(
          error: e,
          onRetry: () => ref.invalidate(spacePostsProvider(spaceId)),
        ),
      ),
      data: (posts) => posts.isEmpty
          ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 36,
                      color: p.textDim,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).spaceNoPosts,
                      style: LivelyType.small(p.textMuted),
                    ),
                  ],
                ),
              ),
            )
          : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => PostCard(post: posts[i]),
              ),
            ),
    );
  }
}

/// Locked-content placeholder shown to non-approved viewers. Two
/// states: the user hasn't requested yet (prompt to request), or the
/// request is pending the owner's review.
class _LockedContent extends StatelessWidget {
  const _LockedContent({required this.space});
  final SpaceWithMeta space;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final isPending = space.isPending;
    final title = isPending ? l.spacePendingTitle : l.spaceLockedTitle;
    final body = isPending ? l.spacePendingBody : l.spaceLockedBody;
    final icon =
        isPending ? Icons.hourglass_top_rounded : Icons.lock_outline_rounded;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LivelyRadius.xl),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: p.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: LivelyType.h1(p.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: LivelyType.small(p.textMuted),
          ),
        ],
      ),
    );
  }
}
