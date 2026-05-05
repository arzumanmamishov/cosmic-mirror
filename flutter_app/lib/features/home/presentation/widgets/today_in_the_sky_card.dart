import 'dart:math' as math;

import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGold = Color(0xFFD4B16A);
const _kGoldLight = Color(0xFFE9D49A);
const _kSurface = Color(0xFF1A1F2E);
const _kSurfaceElevated = Color(0xFF1F2436);
const _kBorder = Color(0xFF2A2F3E);
const _kTextSecondary = Color(0xFFB6BAC4);
const _kTextTertiary = Color(0xFF7E8290);

/// Today in the Sky — daily cosmic snapshot card.
///
/// Computes the live moon phase and the Sun's current tropical zodiac sign
/// locally so the card always shows real data without a backend round-trip.
/// Three additional "highlights" rotate by day-of-year for variety, with a
/// clear path to swap them for real transit data once the backend exposes
/// a `/transits/today` endpoint.
class TodayInTheSkyCard extends StatelessWidget {
  const TodayInTheSkyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final phase = _moonPhase(now);
    final sun = _sunSign(now);
    final highlights = _highlightsFor(now);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).homeTodayInTheSky,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _shortDate(now),
                style: GoogleFonts.poppins(
                  color: _kTextTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MoonGlyph(illumination: phase.illumination, waxing: phase.waxing),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: GoogleFonts.poppins(
                        color: _kGoldLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(phase.illumination * 100).round()}% illuminated',
                      style: GoogleFonts.poppins(
                        color: _kTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sun in ${sun.glyph}  ${sun.name}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: _kBorder,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < highlights.length; i++) ...[
            _HighlightRow(highlight: highlights[i]),
            if (i < highlights.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});
  final _Highlight highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _kSurfaceElevated,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _kBorder),
          ),
          alignment: Alignment.center,
          child: Icon(highlight.icon, color: _kGold, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                highlight.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                highlight.body,
                style: GoogleFonts.poppins(
                  color: _kTextSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Moon glyph rendered as a circle with the lit fraction shown in gold.
/// Lit side switches based on `waxing` (right side waxing, left side waning).
class _MoonGlyph extends StatelessWidget {
  const _MoonGlyph({required this.illumination, required this.waxing});

  final double illumination;
  final bool waxing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _MoonPainter(illumination: illumination, waxing: waxing),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.illumination, required this.waxing});

  final double illumination;
  final bool waxing;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    // Dark base (the unlit side).
    canvas.drawCircle(
      center,
      r,
      Paint()..color = const Color(0xFF2D324A),
    );

    // Lit fraction. illumination is 0..1 where 0=new and 1=full.
    // We draw the lit half-circle, then carve out the "shadow" oval based
    // on illumination so the terminator looks correct. Right side lit
    // when waxing, left side lit when waning.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // Full lit hemisphere on the lit side.
    final litRect = waxing
        ? Rect.fromLTWH(r, 0, r, size.height)
        : Rect.fromLTWH(0, 0, r, size.height);
    canvas.drawRect(
      litRect,
      Paint()..shader = const RadialGradient(
        colors: [_kGoldLight, _kGold],
      ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Shadow ellipse that sweeps across the disk based on illumination.
    // illumination 0.5 → no ellipse (terminator is straight)
    // illumination 0 → ellipse fully covers lit side (new moon)
    // illumination 1 → ellipse subtracts from dark side (full moon)
    final terminator = (0.5 - illumination) * 2 * r;
    final shadowRect = Rect.fromLTWH(
      waxing ? r + terminator : -terminator,
      0,
      r * 2 - terminator.abs() * 2,
      size.height,
    );
    if (shadowRect.width > 0) {
      final isShadowOnLitSide = (waxing && illumination < 0.5) ||
          (!waxing && illumination < 0.5);
      canvas.drawOval(
        shadowRect.deflate(0),
        Paint()
          ..color = isShadowOnLitSide
              ? const Color(0xFF2D324A)
              : _kGoldLight,
      );
    }

    canvas.restore();

    // Thin gold rim.
    canvas.drawCircle(
      center,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kGold.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      oldDelegate.illumination != illumination ||
      oldDelegate.waxing != waxing;
}

// ============================================================================
// Astronomical math.
// ============================================================================

class _Phase {
  const _Phase({
    required this.name,
    required this.illumination,
    required this.waxing,
  });

  final String name;
  final double illumination; // 0..1
  final bool waxing;
}

/// Approximate moon phase — accurate to within a few hours, no ephemeris
/// required. Synodic month = 29.530588853 days, reference new moon at
/// JD 2451549.5 (2000-01-06 18:14 UT).
_Phase _moonPhase(DateTime date) {
  final jd = _julianDay(date);
  const synodic = 29.530588853;
  final age = ((jd - 2451549.5) % synodic + synodic) % synodic;
  final phaseFraction = age / synodic; // 0..1
  // Illumination: 0 at new, 1 at full, back to 0 at next new.
  final illumination = (1 - math.cos(2 * math.pi * phaseFraction)) / 2;
  final waxing = phaseFraction < 0.5;

  String name;
  if (age < 1.0) {
    name = 'New Moon';
  } else if (age < 7.4) {
    name = 'Waxing Crescent';
  } else if (age < 8.4) {
    name = 'First Quarter';
  } else if (age < 14.8) {
    name = 'Waxing Gibbous';
  } else if (age < 15.8) {
    name = 'Full Moon';
  } else if (age < 22.1) {
    name = 'Waning Gibbous';
  } else if (age < 23.1) {
    name = 'Last Quarter';
  } else {
    name = 'Waning Crescent';
  }

  return _Phase(name: name, illumination: illumination, waxing: waxing);
}

double _julianDay(DateTime date) {
  // Standard JD calculation, valid for Gregorian dates after 1582.
  final utc = date.toUtc();
  var y = utc.year;
  var m = utc.month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = y ~/ 100;
  final b = 2 - a + a ~/ 4;
  final dayFraction =
      (utc.hour + utc.minute / 60 + utc.second / 3600) / 24;
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      utc.day +
      b -
      1524.5 +
      dayFraction;
}

class _Sign {
  const _Sign(this.name, this.glyph);
  final String name;
  final String glyph;
}

/// Sun's tropical zodiac sign by date (approximate cusps — cusp days may
/// be off by a day depending on the year, but the trade-off matches what
/// a casual horoscope reader expects).
_Sign _sunSign(DateTime date) {
  final m = date.month;
  final d = date.day;
  if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return const _Sign('Aries', '♈');
  if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return const _Sign('Taurus', '♉');
  if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return const _Sign('Gemini', '♊');
  if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return const _Sign('Cancer', '♋');
  if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return const _Sign('Leo', '♌');
  if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return const _Sign('Virgo', '♍');
  if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return const _Sign('Libra', '♎');
  if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return const _Sign('Scorpio', '♏');
  if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return const _Sign('Sagittarius', '♐');
  if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return const _Sign('Capricorn', '♑');
  if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return const _Sign('Aquarius', '♒');
  return const _Sign('Pisces', '♓');
}

class _Highlight {
  const _Highlight({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

/// Three rotating cosmic-vibe lines keyed off day-of-year so the same day
/// always shows the same set, but the set changes day to day. Replace with
/// a real /transits/today payload when the backend exposes one.
List<_Highlight> _highlightsFor(DateTime now) {
  const pool = <_Highlight>[
    _Highlight(
      icon: Icons.bolt_rounded,
      title: 'Energy: high',
      body: 'A good day to start something — momentum favors action.',
    ),
    _Highlight(
      icon: Icons.favorite_rounded,
      title: 'Heart-forward',
      body: 'Venus angles invite warmth in conversation. Reach out.',
    ),
    _Highlight(
      icon: Icons.psychology_rounded,
      title: 'Mind sharp',
      body: 'Mercury favors clear thinking. Tackle the hard email.',
    ),
    _Highlight(
      icon: Icons.shield_moon_rounded,
      title: 'Pause before reacting',
      body: 'Tense aspect — sleep on big decisions today.',
    ),
    _Highlight(
      icon: Icons.spa_rounded,
      title: 'Restorative window',
      body: 'Soft transits — make time for stillness this evening.',
    ),
    _Highlight(
      icon: Icons.palette_rounded,
      title: 'Creative spark',
      body: 'Imagination runs high — capture the idea before it fades.',
    ),
    _Highlight(
      icon: Icons.workspace_premium_rounded,
      title: 'Recognition possible',
      body: 'Sun-Jupiter trine boosts visibility. Stand in your work.',
    ),
    _Highlight(
      icon: Icons.travel_explore_rounded,
      title: 'New ground',
      body: 'A perspective shift is available. Try a different route home.',
    ),
    _Highlight(
      icon: Icons.handshake_rounded,
      title: 'Bridges, not walls',
      body: 'Diplomatic energy — a hard talk could go better than expected.',
    ),
  ];
  final dayOfYear =
      now.difference(DateTime(now.year)).inDays;
  final start = (dayOfYear * 3) % pool.length;
  return List<_Highlight>.generate(
    3,
    (i) => pool[(start + i) % pool.length],
  );
}
