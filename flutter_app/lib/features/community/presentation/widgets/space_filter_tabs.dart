import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Segmented control: All / Joined, with a pill that slides between them.
class SpaceFilterTabs extends ConsumerWidget {
  const SpaceFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final selected = ref.watch(spaceFilterProvider);
    void select(SpaceFilter f) {
      if (f == selected) return;
      HapticFeedback.selectionClick();
      ref.read(spaceFilterProvider.notifier).state = f;
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LivelyRadius.full),
        border: Border.all(color: p.line),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: LivelyMotion.quick,
            curve: Curves.easeOutCubic,
            alignment: selected == SpaceFilter.all
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: p.primaryGradient,
                  borderRadius: BorderRadius.circular(LivelyRadius.full),
                  boxShadow: [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _Tab(
                label: l.communityFilterAll,
                active: selected == SpaceFilter.all,
                onTap: () => select(SpaceFilter.all),
              ),
              _Tab(
                label: l.communityFilterJoined,
                active: selected == SpaceFilter.joined,
                onTap: () => select(SpaceFilter.joined),
              ),
            ],
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
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: LivelyMotion.quick,
            style: LivelyType.small(active ? p.onPrimary : p.textMuted)
                .copyWith(fontWeight: FontWeight.w600),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
