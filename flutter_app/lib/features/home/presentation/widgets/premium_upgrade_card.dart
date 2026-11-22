import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumUpgradeCard extends StatelessWidget {
  const PremiumUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);

    // Foreground on the premium gradient: onPrimary is dark on the gold
    // (dark theme) and white on the blue (light theme). Plain white was
    // low-contrast on the gold gradient.
    final fg = p.onPrimary;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: p.premiumGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: p.accent.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative cosmic watermark
          Positioned(
            right: -24,
            top: -16,
            child: Opacity(
              opacity: 0.18,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 130,
                color: fg,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.homePremiumPlanTitle,
                style: TextStyle(
                  color: fg,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.homePremiumPlanBody,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                child: GestureDetector(
                onTap: () => context.push('/paywall'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: fg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    l.homePremiumPlanCta,
                    style: TextStyle(
                      color: p.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
