import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:flutter/material.dart';

/// Four-arrow PRA strip — Digestion / Environment / Awareness / Perspective.
/// Each arrow points Left (white-on-dark, blue) or Right (white-on-dark, red).
class VariablesStrip extends StatelessWidget {
  const VariablesStrip({required this.variables, super.key});

  final HDVariables variables;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
            'VARIABLES (PRA)',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Arrow(label: 'Digestion', dir: variables.digestion, palette: p),
              const SizedBox(width: 8),
              _Arrow(
                label: 'Environment',
                dir: variables.environment,
                palette: p,
              ),
              const SizedBox(width: 8),
              _Arrow(label: 'Awareness', dir: variables.awareness, palette: p),
              const SizedBox(width: 8),
              _Arrow(
                label: 'Perspective',
                dir: variables.perspective,
                palette: p,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.label,
    required this.dir,
    required this.palette,
  });

  final String label;
  final String dir; // Left | Right
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isLeft = dir.toLowerCase() == 'left';
    final color = isLeft ? const Color(0xFF4DA3FF) : const Color(0xFFE45A5A);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            alignment: Alignment.center,
            child: Icon(
              isLeft ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            dir,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
