import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:cosmic_mirror/features/human_design/presentation/hd_labels.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class IncarnationCrossCard extends StatelessWidget {
  const IncarnationCrossCard({required this.cross, super.key});

  final HDCross cross;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final hd = HDLabels(l);
    final gateLabels = [
      l.hdCrossPersonalitySun,
      l.hdCrossPersonalityEarth,
      l.hdCrossDesignSun,
      l.hdCrossDesignEarth,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.hdIncarnationCross,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hd.crossName(cross.name),
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.hdQuarterOf(hd.quarter(cross.quarter)),
            style: TextStyle(color: p.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < cross.gates.length; i++) ...[
                _GateBlock(
                  label: gateLabels[i],
                  gate: cross.gates[i],
                  palette: p,
                ),
                if (i < cross.gates.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GateBlock extends StatelessWidget {
  const _GateBlock({
    required this.label,
    required this.gate,
    required this.palette,
  });

  final String label;
  final int gate;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: palette.textTertiary,
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$gate',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
