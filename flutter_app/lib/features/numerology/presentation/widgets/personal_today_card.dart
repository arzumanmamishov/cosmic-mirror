import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Stack of Personal Year + Month + Day with current-period descriptions.
class PersonalTodayCard extends StatelessWidget {
  const PersonalTodayCard({required this.cycles, super.key});

  final NumerologyCycles cycles;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: p.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.numerologyTodayHeader,
            style: TextStyle(
              color: p.onPrimary.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _row(l.numerologyPersonalYear, cycles.personalYear, p.onPrimary),
          const SizedBox(height: 12),
          _row(l.numerologyPersonalMonth, cycles.personalMonth, p.onPrimary),
          const SizedBox(height: 12),
          _row(l.numerologyPersonalDay, cycles.personalDay, p.onPrimary),
        ],
      ),
    );
  }

  /// [fg] is the on-gradient ink (palette.onPrimary).
  Widget _row(String label, NumerologyNumber n, Color fg) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          // Master numbers ("11/2") shrink instead of wrapping inside the
          // fixed tile at large text sizes.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              n.display,
              style: TextStyle(
                color: fg,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.7),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                n.description,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
