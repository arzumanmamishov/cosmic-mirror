import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGold = Color(0xFFD4B16A);

/// Featured Discussions on the home Discover tab — pulls real Community
/// spaces from the backend and shows the top few as glass cards. Tapping
/// a card opens that space; tapping "See all" jumps to the Spaces list.
class DiscussionsSection extends ConsumerWidget {
  const DiscussionsSection({super.key, this.maxItems = 4});

  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final spacesAsync = ref.watch(spacesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Discussions',
                style: GoogleFonts.poppins(
                  color: p.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/community'),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    color: _kGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        spacesAsync.when(
          loading: () => const _SpacesSkeleton(),
          error: (e, _) => _Message(
            text: "Couldn't load spaces just now.",
            palette: p,
          ),
          data: (spaces) {
            if (spaces.isEmpty) {
              return _Message(
                text: 'No spaces yet — be the first to start one.',
                palette: p,
              );
            }
            final featured = spaces.take(maxItems).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _SpaceCard(item: featured[i]),
            );
          },
        ),
      ],
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({required this.item});
  final SpaceWithMeta item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = item.space;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/community/${s.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.categoryName!,
                        style: GoogleFonts.poppins(
                          color: _kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  if (s.isVerified) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: _kGold.withValues(alpha: 0.85),
                    ),
                  ],
                  const Spacer(),
                  if (item.isJoined)
                    Text(
                      'Joined',
                      style: GoogleFonts.poppins(
                        color: p.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.name,
                style: GoogleFonts.poppins(
                  color: p.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (s.description != null && s.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  s.description!,
                  style: GoogleFonts.poppins(
                    color: p.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    size: 13,
                    color: p.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _memberCountLabel(s.memberCount),
                    style: GoogleFonts.poppins(
                      color: p.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.alternate_email_rounded,
                    size: 13,
                    color: p.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.handle,
                      style: GoogleFonts.poppins(
                        color: p.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _memberCountLabel(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k members';
    return '$n ${n == 1 ? 'member' : 'members'}';
  }
}

class _SpacesSkeleton extends StatelessWidget {
  const _SpacesSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(2, (_) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 92,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.glassBorder),
            ),
          );
        }),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.palette});
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
