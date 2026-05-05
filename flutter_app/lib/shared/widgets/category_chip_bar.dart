import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Horizontal scrolling row of pill-shaped category chips. Selected chip
/// gets the primary purple gradient; the rest stay translucent with a
/// subtle border.
class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          return _CategoryChip(
            label: c,
            active: c == selected,
            onTap: () => onSelected(c),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active ? p.primaryGradient : null,
          color: active ? null : p.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? Colors.transparent
                : p.glassBorder,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: p.primary.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : p.textSecondary,
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
