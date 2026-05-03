import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.category, super.key});

  final SpaceCategory category;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () => context.push('/community/category/${category.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: p.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconFor(category.icon),
              color: Colors.white.withValues(alpha: 0.9),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? name) {
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
