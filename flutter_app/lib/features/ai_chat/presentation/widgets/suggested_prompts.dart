import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Six tappable starter prompts shown on the empty-state of a fresh
/// chat thread. All strings localized, all colors palette-aware.
class SuggestedPrompts extends StatelessWidget {
  const SuggestedPrompts({required this.onPromptSelected, super.key});

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final prompts = [
      l.aiChatPrompt1,
      l.aiChatPrompt2,
      l.aiChatPrompt3,
      l.aiChatPrompt4,
      l.aiChatPrompt5,
      l.aiChatPrompt6,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 14, color: p.gold),
            const SizedBox(width: 6),
            Text(
              l.aiChatSuggestedQuestions.toUpperCase(),
              style: TextStyle(
                color: p.gold,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final prompt in prompts)
              _PromptChip(
                label: prompt,
                onTap: () => onPromptSelected(prompt),
              ),
          ],
        ),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: p.glassBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
