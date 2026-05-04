import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:flutter/material.dart';

/// Two columns of gate activations: Personality (red dot) on the left,
/// Design (black dot) on the right, each grouped by body and labelled
/// "Sun · 41.3" style.
class GateList extends StatelessWidget {
  const GateList({required this.gates, super.key});

  final List<HDGateActivation> gates;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final personality = gates.where((g) => g.isPersonality).toList();
    final design = gates.where((g) => !g.isPersonality).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Column(
            label: 'PERSONALITY',
            dotColor: p.error,
            items: personality,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Column(
            label: 'DESIGN',
            dotColor: p.textPrimary,
            items: design,
          ),
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.label,
    required this.dotColor,
    required this.items,
  });

  final String label;
  final Color dotColor;
  final List<HDGateActivation> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final g in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    g.body,
                    style: TextStyle(
                      color: p.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${g.gate}.${g.line}',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
