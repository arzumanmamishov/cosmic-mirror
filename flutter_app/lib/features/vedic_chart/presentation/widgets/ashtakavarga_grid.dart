import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/yoga.dart';
import 'package:flutter/material.dart';

/// 12-cell bindu grid for Ashtakavarga. Toggle between Sarva (sum of seven
/// planets, max 56 per sign) and Bhinn (per-planet, max 8 per sign).
class AshtakavargaGrid extends StatefulWidget {
  const AshtakavargaGrid({required this.av, super.key});

  final Ashtakavarga av;

  @override
  State<AshtakavargaGrid> createState() => _AshtakavargaGridState();
}

class _AshtakavargaGridState extends State<AshtakavargaGrid> {
  String? _selectedPlanet; // null = Sarva

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isSarva = _selectedPlanet == null;
    final values = isSarva
        ? widget.av.sarva
        : (widget.av.bhinn[_selectedPlanet!] ?? List.filled(12, 0));
    final maxVal = isSarva ? 56 : 8;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _selector(p),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, i) {
            final v = values[i];
            final intensity = (v / maxVal).clamp(0.0, 1.0);
            return Container(
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.15 + intensity * 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.glassBorder),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _signAbbr[i],
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$v',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          isSarva
              ? 'Sarva Ashtakavarga — total benefic points each sign receives '
                  'from all seven grahas (max $maxVal per sign).'
              : 'Bhinn Ashtakavarga of $_selectedPlanet — bindus contributed '
                  'to each sign by $_selectedPlanet (max $maxVal per sign).',
          style: TextStyle(color: p.textSecondary, fontSize: 12, height: 1.45),
        ),
      ],
    );
  }

  Widget _selector(AppPalette p) {
    final planets = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            p,
            label: 'Sarva',
            selected: _selectedPlanet == null,
            onTap: () => setState(() => _selectedPlanet = null),
          ),
          for (final pl in planets)
            _chip(
              p,
              label: pl,
              selected: _selectedPlanet == pl,
              onTap: () => setState(() => _selectedPlanet = pl),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    AppPalette p, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: selected ? p.primaryGradient : null,
            color: selected ? null : p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.glassBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : p.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

const _signAbbr = [
  'Ar', 'Ta', 'Ge', 'Cn', 'Le', 'Vi',
  'Li', 'Sc', 'Sg', 'Cp', 'Aq', 'Pi',
];
