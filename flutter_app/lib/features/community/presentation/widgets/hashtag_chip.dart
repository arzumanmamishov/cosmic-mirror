import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HashtagChip extends StatelessWidget {
  const HashtagChip({required this.tag, super.key});
  final String tag;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () => context.push('/community/hashtag/$tag'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.glassBorder),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
