import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HashtagChip extends StatelessWidget {
  const HashtagChip({required this.tag, super.key});
  final String tag;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(LivelyRadius.full),
      child: InkWell(
        onTap: () => context.push('/community/hashtag/$tag'),
        borderRadius: BorderRadius.circular(LivelyRadius.full),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LivelyRadius.full),
            border: Border.all(color: p.line),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '#', style: TextStyle(color: p.primary)),
                TextSpan(text: tag),
              ],
            ),
            style: LivelyType.small(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
