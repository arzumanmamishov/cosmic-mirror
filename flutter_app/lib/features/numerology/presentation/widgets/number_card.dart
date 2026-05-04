import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:flutter/material.dart';

/// A single numerology number card. Big value on the left, label + small
/// description on the right. Master numbers and karmic-debt numbers get
/// distinct colored badges.
class NumberCard extends StatelessWidget {
  const NumberCard({
    required this.title,
    required this.number,
    this.icon,
    super.key,
  });

  final String title;
  final NumerologyNumber number;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = number.isMaster
        ? p.gold
        : (number.isKarmicDebt ? p.warning : p.primary);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              number.display,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: p.textSecondary),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (number.isMaster) ...[
                      const SizedBox(width: 6),
                      _badge('Master', p.gold, p),
                    ],
                    if (number.isKarmicDebt) ...[
                      const SizedBox(width: 6),
                      _badge('Karmic ${number.rawSum}', p.warning, p),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  number.description,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
