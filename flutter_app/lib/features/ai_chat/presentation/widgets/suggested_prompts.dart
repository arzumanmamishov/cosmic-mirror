import 'package:flutter/material.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';

class SuggestedPrompts extends StatelessWidget {
  const SuggestedPrompts({required this.onPromptSelected, super.key});

  final ValueChanged<String> onPromptSelected;

  static const _prompts = [
    'What should I focus on today?',
    'Tell me about my Venus placement',
    'How will this week unfold for me?',
    'What are my biggest strengths?',
    'How can I improve my relationships?',
    'What career paths suit my chart?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Questions',
          style: CosmicTypography.labelLarge.copyWith(
            color: CosmicColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _prompts.map((prompt) {
            return GestureDetector(
              onTap: () => onPromptSelected(prompt),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: CosmicColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CosmicColors.glassBorder),
                ),
                child: Text(prompt, style: CosmicTypography.bodySmall),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
