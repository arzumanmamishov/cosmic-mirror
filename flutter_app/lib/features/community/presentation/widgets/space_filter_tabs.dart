import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Segmented control: All / Joined.
class SpaceFilterTabs extends ConsumerWidget {
  const SpaceFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final selected = ref.watch(spaceFilterProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'All',
            active: selected == SpaceFilter.all,
            onTap: () => ref.read(spaceFilterProvider.notifier).state =
                SpaceFilter.all,
          ),
          _Tab(
            label: 'Joined',
            active: selected == SpaceFilter.joined,
            onTap: () => ref.read(spaceFilterProvider.notifier).state =
                SpaceFilter.joined,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active ? p.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : p.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
