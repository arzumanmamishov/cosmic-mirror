import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:cosmic_mirror/features/human_design/presentation/hd_labels.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Hero card showing Type, Strategy, Authority, Profile, Definition, and the
/// Not-Self theme. Primary-gradient background — the headline of the chart.
class TypeCard extends StatelessWidget {
  const TypeCard({required this.chart, super.key});

  final HumanDesignChart chart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final hd = HDLabels(l);
    // On-gradient ink: dark on the gold dark-theme gradient, white on the
    // blue light-theme gradient.
    final fg = p.onPrimary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: p.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.hdYouAre,
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hd.type(chart.type),
            style: TextStyle(
              color: fg,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _row(l.hdStrategy, hd.strategy(chart.strategy), fg),
          const SizedBox(height: 10),
          _row(l.hdAuthority, hd.authority(chart.authority), fg),
          const SizedBox(height: 10),
          _row(l.humanDesignTabProfile, chart.profile, fg),
          const SizedBox(height: 10),
          _row(l.hdDefinition, hd.definition(chart.definition), fg),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l.hdNotSelfTheme(hd.notSelf(chart.notSelfTheme)),
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color fg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
