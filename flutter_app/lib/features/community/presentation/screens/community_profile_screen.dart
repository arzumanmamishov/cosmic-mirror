import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/post_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_card.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final profileAsync =
        ref.watch(userCommunityProfileProvider(userIdOrMe));
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(AppLocalizations.of(context).communityProfile),
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
              message: e.toString(),
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
                  const SizedBox(height: 24),
                  _SectionHeader(
                    label: 'JOINED SPACES (${profile.joinedSpaces.length})',
                    palette: p,
                  ),
                  const SizedBox(height: 8),
                  if (profile.joinedSpaces.isEmpty)
                    _EmptyHint(
                      message: 'Not in any spaces yet.',
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
                    label: 'RECENT POSTS (${profile.recentPosts.length})',
                    palette: p,
                  ),
                  const SizedBox(height: 8),
                  if (profile.recentPosts.isEmpty)
                    _EmptyHint(message: 'No posts yet.', palette: p)
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
          name.isEmpty ? 'Unknown user' : name,
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
