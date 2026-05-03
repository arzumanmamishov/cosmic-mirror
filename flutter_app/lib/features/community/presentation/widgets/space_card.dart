import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/join_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Space card — the hero of the spaces list. Mirrors the screenshot:
/// avatar + name + verified check + Spicy badge on top row, handle/members
/// on second row, description on third, Join button trailing.
class SpaceCard extends StatelessWidget {
  const SpaceCard({required this.space, super.key});

  final SpaceWithMeta space;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = space.space;
    return InkWell(
      onTap: () => context.push('/community/${s.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(name: s.name, palette: p),
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
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (s.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
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
                            color: p.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Spicy',
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
                    '@${s.handle} · ${_formatCount(s.memberCount)} members',
                    style: TextStyle(color: p.textSecondary, fontSize: 11),
                  ),
                  if (s.description != null && s.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      s.description!,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            JoinButton(
              spaceId: s.id,
              initialJoined: space.isJoined,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
    return '$n';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.palette});
  final String name;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: palette.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
