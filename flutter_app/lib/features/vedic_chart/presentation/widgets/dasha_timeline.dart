import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/dasha.dart';
import 'package:flutter/material.dart';

/// Vimshottari Dasha timeline. Shows the active Maha → Antar → Pratyantar
/// path in a hero card at the top, then a scrollable list of all 9
/// Mahadashas with their Antardasha sub-periods expandable.
class DashaTimeline extends StatelessWidget {
  const DashaTimeline({required this.tree, super.key});

  final DashaTree tree;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _CurrentCard(path: tree.current, palette: p),
        const SizedBox(height: 16),
        Text(
          'Mahadashas (120-year cycle)',
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...tree.mahadashas.map(
          (m) => _MahaTile(
            period: m,
            isActive: m.containsMoment(now),
          ),
        ),
      ],
    );
  }
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.path, required this.palette});

  final DashaPath path;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: palette.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT DASHA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${path.maha} — ${path.antar} — ${path.pratyantar}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Maha · Antar · Pratyantar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MahaTile extends StatelessWidget {
  const _MahaTile({required this.period, required this.isActive});

  final DashaPeriod period;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? p.primary : p.glassBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        iconColor: p.textSecondary,
        collapsedIconColor: p.textTertiary,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? p.primary.withValues(alpha: 0.2)
                    : p.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _grahaAbbr[period.lord] ?? period.lord.substring(0, 2),
                style: TextStyle(
                  color: isActive ? p.primary : p.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.lord,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_fmtDate(period.startDate)} — ${_fmtDate(period.endDate)}',
                    style: TextStyle(color: p.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'NOW',
                  style: TextStyle(
                    color: p.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
          ],
        ),
        children: period.sub.map((a) => _AntarRow(period: a)).toList(),
      ),
    );
  }
}

class _AntarRow extends StatelessWidget {
  const _AntarRow({required this.period});

  final DashaPeriod period;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final active = period.containsMoment(now);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? p.primary : p.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              period.lord,
              style: TextStyle(
                color: active ? p.textPrimary : p.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_fmtDate(period.startDate)} — ${_fmtDate(period.endDate)}',
            style: TextStyle(color: p.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

const _grahaAbbr = {
  'Sun': 'Su',
  'Moon': 'Mo',
  'Mars': 'Ma',
  'Mercury': 'Me',
  'Jupiter': 'Ju',
  'Venus': 'Ve',
  'Saturn': 'Sa',
  'Rahu': 'Ra',
  'Ketu': 'Ke',
};

String _fmtDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
