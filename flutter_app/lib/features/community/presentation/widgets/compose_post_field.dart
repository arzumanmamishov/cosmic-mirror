import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Multi-line text composer with a small toolbar (link toggle). Used in the
/// ComposePostSheet and the PostDetailScreen comment composer (without the
/// link toolbar — pass [showLinkAction] = false for comments).
class ComposePostField extends StatelessWidget {
  const ComposePostField({
    required this.controller,
    required this.linkController,
    this.hintText = "What's on your mind?",
    this.showLinkAction = true,
    this.minLines = 4,
    this.maxLines = 8,
    super.key,
  });

  final TextEditingController controller;
  final TextEditingController linkController;
  final String hintText;
  final bool showLinkAction;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.glassBorder),
          ),
          child: TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            style: TextStyle(color: p.textPrimary, fontSize: 14, height: 1.45),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: p.textTertiary, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        if (showLinkAction) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: p.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: linkController,
                    style: TextStyle(color: p.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Optional link URL',
                      hintStyle: TextStyle(color: p.textTertiary, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
