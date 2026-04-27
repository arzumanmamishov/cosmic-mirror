import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/cosmic_card.dart';

class AffirmationCard extends StatelessWidget {
  const AffirmationCard({super.key});

  @override
  Widget build(BuildContext context) {
    // In production, this comes from the daily reading provider
    const affirmation =
        'I trust the timing of my life. What is meant for me will find me.';

    return CosmicCard(
      showGradientBorder: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY AFFIRMATION',
                style: CosmicTypography.overline.copyWith(
                  color: CosmicColors.gold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Share.share(
                    '"$affirmation"\n\n~ Lively',
                  );
                },
                child: const Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: CosmicColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            affirmation,
            style: CosmicTypography.affirmation,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
