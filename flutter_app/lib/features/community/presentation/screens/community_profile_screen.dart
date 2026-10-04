import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/domain/entities/user_profile.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/moderation_actions.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/post_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_card.dart';
import 'package:cosmic_mirror/features/profile/presentation/screens/profile_screen.dart'
    show ProfileScreen;
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Community-context profile of any user. Pass `userIdOrMe` = a user UUID
/// or the literal "me" (handy for the bottom-nav avatar / app-bar avatar
/// shortcut). The screen does NOT replace the existing astrology
/// [ProfileScreen] — that one is reachable from the bottom nav and shows
/// the astrology bio. This one is the forum view.
class CommunityProfileScreen extends ConsumerWidget {
  const CommunityProfileScreen({required this.userIdOrMe, super.key});

  final String userIdOrMe;

  /// Report / block (or unblock) for someone else's profile. Blocking
  /// leaves the screen — there's nothing left to show.
  List<ContentAction> _actions(
    BuildContext context,
    UserCommunityProfile profile,
  ) {
    final l = AppLocalizations.of(context);
    void leave() {
      if (context.mounted) Navigator.of(context).maybePop();
    }

    if (profile.isBlockedByMe) {
      return [
        ContentAction(
          icon: Icons.flag_outlined,
          label: l.reportUser,
          onSelected: () => showReportSheet(
            context,
            target: ReportTarget.user,
            targetId: profile.userId,
          ),
        ),
        ContentAction(
          icon: Icons.lock_open_rounded,
          label: l.blockUnblock,
          onSelected: () => unblockUser(
            context,
            userId: profile.userId,
            name: profile.name,
          ),
        ),
      ];
    }
    return reportAndBlockActions(
      context,
      target: ReportTarget.user,
      targetId: profile.userId,
      authorId: profile.userId,
      authorName: profile.name,
      onBlocked: leave,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final profileAsync = ref.watch(userCommunityProfileProvider(userIdOrMe));
    final myId = ref.watch(currentUserProvider.select((s) => s.id));
    bool isMe(UserCommunityProfile profile) =>
        userIdOrMe == 'me' || (myId != null && profile.userId == myId);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(l.communityProfile),
        actions: [
          profileAsync.maybeWhen(
            orElse: () => const SizedBox.shrink(),
            data: (profile) => isMe(profile)
                ? const SizedBox.shrink()
                : ContentMoreButton(
                    size: 22,
                    actions: () => _actions(context, profile),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.6,
            ),
          ),
          profileAsync.when(
            loading: () => const ShimmerList(itemCount: 5),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () =>
                  ref.invalidate(userCommunityProfileProvider(userIdOrMe)),
            ),
            data: (profile) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userCommunityProfileProvider(userIdOrMe));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                children: [
                  _ProfileHero(name: profile.name, palette: p),
                  if (profile.isBlockedByMe) ...[
                    const SizedBox(height: 20),
                    _BlockedNotice(profile: profile, palette: p),
                  ],
                  const SizedBox(height: 24),
                  _SectionHeader(
                    label: l.communityProfileJoinedSpaces(
                      profile.joinedSpaces.length,
                    ),
                    palette: p,
                  ),
                  const SizedBox(height: 8),
                  if (profile.joinedSpaces.isEmpty)
                    _EmptyHint(
                      message: l.communityProfileNoSpaces,
                      palette: p,
                    )
                  else ...[
                    for (final s in profile.joinedSpaces) ...[
                      SpaceCard(space: s),
                      const SizedBox(height: 8),
                    ],
                  ],
                  const SizedBox(height: 24),
                  _SectionHeader(
                    label: l.communityProfileRecentPosts(
                      profile.recentPosts.length,
                    ),
                    palette: p,
                  ),
                  const SizedBox(height: 8),
                  if (profile.recentPosts.isEmpty)
                    _EmptyHint(message: l.communityProfileNoPosts, palette: p)
                  else ...[
                    for (final post in profile.recentPosts) ...[
                      PostCard(post: post),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name, required this.palette});
  final String name;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: palette.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name.isEmpty
              ? AppLocalizations.of(context).communityUnknownUser
              : name,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Shown on the profile of someone the viewer blocked, with a quick way
/// to undo it.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({required this.profile, required this.palette});
  final UserCommunityProfile profile;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.glassBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.block_rounded, size: 18, color: palette.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.blockProfileNotice,
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => unblockUser(
              context,
              userId: profile.userId,
              name: profile.name,
            ),
            child: Text(l.blockUnblock),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.palette});
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message, required this.palette});
  final String message;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.glassBorder),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
