import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:flutter/material.dart';

/// Selectable chip — used in the onboarding focus-areas grid. Idle reads
/// as a quiet glass tile; selected fills with a gold wash + gold border.
class LivelyChip extends StatelessWidget {
  const LivelyChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? p.primary.withValues(alpha: isDark ? 0.14 : 0.12)
              : (isDark ? p.surfaceGlass : p.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? p.primary : p.line),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 17,
                color: selected ? p.primary : p.textMuted,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: LivelyType.body(
                  selected ? p.primary : p.textPrimary,
                ).copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
