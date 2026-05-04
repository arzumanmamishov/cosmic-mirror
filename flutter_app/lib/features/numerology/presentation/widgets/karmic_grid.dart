import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// 1..9 grid showing which numbers are missing from the user's name
/// (karmic lessons) and which is the dominant one (hidden passion).
class KarmicGrid extends StatelessWidget {
  const KarmicGrid({
    required this.karmicLessons,
    required this.hiddenPassion,
    super.key,
  });

  final List<int> karmicLessons;
  final int hiddenPassion;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final missing = karmicLessons.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KARMIC LESSONS',
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          missing.isEmpty
              ? 'Your name carries every digit — no missing lessons.'
              : 'Numbers missing from your name show areas you came to learn.',
          style: TextStyle(color: p.textSecondary, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 9,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 1; i <= 9; i++)
              _Cell(
                digit: i,
                missing: missing.contains(i),
                isHiddenPassion: i == hiddenPassion,
                palette: p,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'HIDDEN PASSION',
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hiddenPassion == 0
              ? 'No dominant digit — your name is balanced across the spectrum.'
              : 'Your strongest gift is the energy of $hiddenPassion — '
                  'the digit that appears most often in your name.',
          style: TextStyle(color: p.textPrimary, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.digit,
    required this.missing,
    required this.isHiddenPassion,
    required this.palette,
  });

  final int digit;
  final bool missing;
  final bool isHiddenPassion;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (isHiddenPassion) {
      bg = palette.gold;
      fg = Colors.white;
    } else if (missing) {
      bg = palette.surfaceElevated;
      fg = palette.textTertiary;
    } else {
      bg = palette.primary.withValues(alpha: 0.18);
      fg = palette.primary;
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: missing && !isHiddenPassion
            ? Border.all(color: palette.glassBorder)
            : null,
      ),
      child: Text(
        '$digit',
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
