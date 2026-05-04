import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:flutter/material.dart';

/// Result panel for a numerology compatibility comparison.
class CompatScorePanel extends StatelessWidget {
  const CompatScorePanel({required this.report, super.key});

  final NumerologyCompatibility report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        // Score ring
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CircularProgressIndicator(
                value: report.score / 100,
                strokeWidth: 12,
                backgroundColor: p.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  report.score >= 70
                      ? p.success
                      : (report.score >= 50 ? p.gold : p.warning),
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  '${report.score}%',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Match',
                  style: TextStyle(color: p.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          report.summary,
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textPrimary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),
        _row('Life Path', report.lifePathScore, p),
        const SizedBox(height: 8),
        _row('Expression', report.expressionScore, p),
        const SizedBox(height: 8),
        _row('Soul Urge', report.soulUrgeScore, p),
      ],
    );
  }

  Widget _row(String label, int score, AppPalette p) {
    final color = score >= 70 ? p.success : (score >= 50 ? p.gold : p.warning);
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: p.surfaceElevated,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
