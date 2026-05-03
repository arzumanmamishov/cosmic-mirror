import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/yoga.dart';
import 'package:flutter/material.dart';

/// Card describing one classical yoga (active or dormant). Color-coded by
/// category and shows a strength bar.
class YogaCard extends StatelessWidget {
  const YogaCard({required this.yoga, super.key});

  final VedicYoga yoga;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final categoryColor = _categoryColors[yoga.category] ?? p.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  yoga.category.toUpperCase(),
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (yoga.planets.isNotEmpty)
                Text(
                  yoga.planets.join(' + '),
                  style: TextStyle(color: p.textTertiary, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                yoga.name,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              if (yoga.sanskrit.isNotEmpty && yoga.sanskrit != yoga.name)
                Text(
                  '· ${yoga.sanskrit}',
                  style: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            yoga.description,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'STRENGTH',
                style: TextStyle(
                  color: p.textTertiary,
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: yoga.strength.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: p.surfaceElevated,
                    color: categoryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(yoga.strength * 100).round()}%',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const Map<String, Color> _categoryColors = {
  'Pancha Mahapurusha': Color(0xFFFFB347),
  'Lunar': Color(0xFFE8E8E8),
  'Solar': Color(0xFFF4C542),
  'Wealth': Color(0xFF34D399),
  'Power': Color(0xFFE14B8A),
  'Wisdom': Color(0xFF6C3CE1),
  'Nodal': Color(0xFF8E44AD),
};
