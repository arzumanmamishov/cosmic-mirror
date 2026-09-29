import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/config/theme/macos_colors.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.category, this.onTap, super.key});

  final SpaceCategory category;

  /// Overrides the default tap (open the category), e.g. so a carousel
  /// can centre an off-centre card first.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hue = MacOSColors.of(context).hueFor(category.name);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(LivelyRadius.xl),
      child: InkWell(
        onTap: onTap ??
            () => context.push('/community/category/${category.id}'),
        borderRadius: BorderRadius.circular(LivelyRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LivelyRadius.xl),
            border: Border.all(color: p.line),
            gradient: LinearGradient(
              colors: [hue.withValues(alpha: 0.14), hue.withValues(alpha: 0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(LivelyRadius.md),
                ),
                child: Icon(iconFor(category.icon), color: hue, size: 18),
              ),
              const Spacer(),
              Text(
                category.name,
                style: LivelyType.small(p.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Maps a category's stored icon name to its Material icon.
  static IconData iconFor(String? name) {
    switch (name) {
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'brightness_5_rounded':
        return Icons.brightness_5_rounded;
      case 'style_rounded':
        return Icons.style_rounded;
      case 'pin_rounded':
        return Icons.pin_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      case 'self_improvement_rounded':
        return Icons.self_improvement_rounded;
      case 'nightlight_round':
        return Icons.nightlight_round;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      default:
        return Icons.tag_rounded;
    }
  }
}
