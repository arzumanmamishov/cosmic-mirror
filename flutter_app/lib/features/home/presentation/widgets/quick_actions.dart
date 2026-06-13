import 'package:cosmic_mirror/config/theme/colors.dart';
import 'package:cosmic_mirror/config/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const _actions = [
    ('AI Chat', Icons.chat_bubble_outline, '/chat', CosmicColors.primary),
    ('Compatibility', Icons.favorite_outline, '/compatibility', CosmicColors.accent),
    ('Full Chart', Icons.auto_awesome, '/chart', CosmicColors.success),
    ('Vedic', Icons.brightness_5_rounded, '/vedic-chart', CosmicColors.gold),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _actions.map((action) {
        final (label, icon, route, color) = action;
        return Expanded(
          child: GestureDetector(
            onTap: () => context.push(route),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: CosmicTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
