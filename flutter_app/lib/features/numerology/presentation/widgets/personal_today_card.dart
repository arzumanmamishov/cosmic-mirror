import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:flutter/material.dart';

/// Stack of Personal Year + Month + Day with current-period descriptions.
class PersonalTodayCard extends StatelessWidget {
  const PersonalTodayCard({required this.cycles, super.key});

  final NumerologyCycles cycles;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: p.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TODAY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _row('Personal Year', cycles.personalYear),
          const SizedBox(height: 12),
          _row('Personal Month', cycles.personalMonth),
          const SizedBox(height: 12),
          _row('Personal Day', cycles.personalDay),
        ],
      ),
    );
  }

  Widget _row(String label, NumerologyNumber n) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            n.display,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                n.description,
                style: const TextStyle(
                  color: Colors.white,
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
