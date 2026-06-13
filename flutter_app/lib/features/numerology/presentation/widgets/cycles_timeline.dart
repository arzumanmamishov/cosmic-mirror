import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:flutter/material.dart';

/// Vertical timeline of the four Pinnacle cycles + four Challenge cycles.
/// The active cycle is highlighted with a primary-gradient border.
class CyclesTimeline extends StatelessWidget {
  const CyclesTimeline({
    required this.pinnacles,
    required this.challenges,
    required this.currentAge,
    super.key,
  });

  final List<PinnacleCycle> pinnacles;
  final List<ChallengeCycle> challenges;
  final int currentAge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PINNACLES — life's themes",
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final cycle in pinnacles)
          _CycleBand(
            label: 'Pinnacle ${cycle.index}',
            startAge: cycle.startAge,
            endAge: cycle.endAge,
            number: cycle.number,
            isActive: cycle.isActive,
            isPositive: true,
          ),
        const SizedBox(height: 20),
        Text(
          'CHALLENGES — areas to grow',
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final cycle in challenges)
          _CycleBand(
            label: 'Challenge ${cycle.index}',
            startAge: cycle.startAge,
            endAge: cycle.endAge,
            number: cycle.number,
            isActive: cycle.isActive,
            isPositive: false,
          ),
        const SizedBox(height: 12),
        Text(
          'You are $currentAge — active cycle is highlighted.',
          style: TextStyle(color: p.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}

class _CycleBand extends StatelessWidget {
  const _CycleBand({
    required this.label,
    required this.startAge,
    required this.endAge,
    required this.number,
    required this.isActive,
    required this.isPositive,
  });

  final String label;
  final int startAge;
  final int endAge;
  final NumerologyNumber number;
  final bool isActive;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = isPositive ? p.primary : p.warning;
    final ageRange = endAge == -1
        ? 'age $startAge+'
        : 'ages $startAge–$endAge';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? accent : p.glassBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number.display,
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ageRange,
                      style: TextStyle(color: p.textTertiary, fontSize: 10),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NOW',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  number.description,
                  style: TextStyle(color: p.textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
