import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/chart/presentation/astro_labels.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/vedic_chart.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Detailed nakshatra card with deity, symbol, ruler, and traditional
/// classifications. Use for any planet's birth nakshatra or for the Lagna's
/// nakshatra. Tap to expand the details.
class NakshatraCard extends StatelessWidget {
  const NakshatraCard({
    required this.title,
    required this.nakshatra,
    required this.pada,
    super.key,
  });

  final String title; // e.g. "Moon" or "Lagna"
  final VedicNakshatra nakshatra;
  final int pada;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      // Transparent Material gives the tile's ink ripple a surface to
      // paint on — otherwise the coloured box above hides the tap feedback.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: p.textSecondary,
          collapsedIconColor: p.textTertiary,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: p.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${nakshatra.index}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title — ${nakshatra.name}',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.vedicNakshatraPadaRuler(
                        pada,
                        chartPlanetName(l, nakshatra.ruler),
                      ),
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            _kv(p, l.vedicNakshatraDeity, nakshatra.deity),
            _kv(p, l.vedicNakshatraSymbol, nakshatra.symbol),
            _kv(p, l.vedicNakshatraGana, nakshatra.gana),
            _kv(p, l.vedicNakshatraNadi, nakshatra.nadi),
            _kv(p, l.vedicNakshatraVarna, nakshatra.varna),
            _kv(p, l.vedicNakshatraCaste, nakshatra.caste),
            _kv(p, l.vedicNakshatraAnimal, nakshatra.animal),
            _kv(p, l.vedicNakshatraGender, nakshatra.gender),
          ],
        ),
      ),
    );
  }

  Widget _kv(AppPalette p, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              key,
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(color: p.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
