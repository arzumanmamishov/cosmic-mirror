import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({required this.spaceId, super.key});
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final membersAsync = ref.watch(spaceMembersProvider(spaceId));
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Members'),
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
          membersAsync.when(
            loading: () => const ShimmerList(itemCount: 5),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(spaceMembersProvider(spaceId)),
            ),
            data: (members) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = members[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: p.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          m.userName.isNotEmpty
                              ? m.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.userName.isEmpty ? 'Unknown' : m.userName,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _RoleChip(role: m.role, palette: p),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.palette});
  final String role;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final color = role == 'owner'
        ? palette.gold
        : (role == 'mod' ? palette.primary : palette.textTertiary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
