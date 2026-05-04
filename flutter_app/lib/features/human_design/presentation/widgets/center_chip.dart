import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:flutter/material.dart';

/// Card describing one of the 9 centers — defined or undefined, gates active.
class CenterCard extends StatelessWidget {
  const CenterCard({required this.center, super.key});

  final HDCenter center;

  static const Map<String, String> _centerThemes = {
    'Head': 'Inspiration · pressure to know',
    'Ajna': 'Conceptualization · certainty vs doubt',
    'Throat': 'Manifestation · expression',
    'G': 'Identity · love · direction',
    'Heart': 'Willpower · ego · resources',
    'Sacral': 'Life force · sustainable work · sexuality',
    'SolarPlexus': 'Emotional wave · feelings · clarity',
    'Spleen': 'Intuition · health · survival',
    'Root': 'Pressure · adrenaline · drive',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = center.defined ? p.primary : p.textTertiary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: center.defined ? p.primary.withValues(alpha: 0.5) : p.glassBorder,
          width: center.defined ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                center.name == 'SolarPlexus' ? 'Solar Plexus' : center.name,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  center.defined ? 'DEFINED' : 'OPEN',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _centerThemes[center.name] ?? '',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (center.gates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in center.gates)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Gate $g',
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
