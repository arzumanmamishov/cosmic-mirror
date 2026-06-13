import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Unicode zodiac glyphs, keyed by lowercase English sign name.
const zodiacGlyphs = <String, String>{
  'aries': '♈',
  'taurus': '♉',
  'gemini': '♊',
  'cancer': '♋',
  'leo': '♌',
  'virgo': '♍',
  'libra': '♎',
  'scorpio': '♏',
  'sagittarius': '♐',
  'capricorn': '♑',
  'aquarius': '♒',
  'pisces': '♓',
};

String glyphForSign(String? sign) =>
    zodiacGlyphs[(sign ?? '').toLowerCase().trim()] ?? '✵';

/// A small, decorative natal-chart wheel — two hair-thin gold rings, 12
/// ticks, a soft central glow, and three luminary medallions (Sun, Moon,
/// Rising) carrying their zodiac glyphs. Used as the centrepiece of the
/// Welcome reveal.
class MiniWheel extends StatelessWidget {
  const MiniWheel({
    this.size = 220,
    this.sun = 'leo',
    this.moon = 'pisces',
    this.rising = 'scorpio',
    super.key,
  });

  final double size;
  final String sun;
  final String moon;
  final String rising;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WheelPainter(
          primary: p.primary,
          medallionFill: p.background,
          sun: sun,
          moon: moon,
          rising: rising,
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.primary,
    required this.medallionFill,
    required this.sun,
    required this.moon,
    required this.rising,
  });

  final Color primary;
  final Color medallionFill;
  final String sun;
  final String moon;
  final String rising;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2 - 4;
    final inner = outer - 22;

    canvas
      // soft central glow
      ..drawCircle(
        c,
        outer,
        Paint()
          ..shader = RadialGradient(
            colors: [
              primary.withValues(alpha: 0.08),
              primary.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.8],
          ).createShader(Rect.fromCircle(center: c, radius: outer)),
      )
      // outer + inner rings
      ..drawCircle(
        c,
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = primary.withValues(alpha: 0.6),
      )
      ..drawCircle(
        c,
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = primary.withValues(alpha: 0.4),
      );

    // 12 ticks between the rings
    final tick = Paint()
      ..strokeWidth = 0.5
      ..color = primary.withValues(alpha: 0.5);
    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * inner, c + dir * outer, tick);
    }

    // center dot
    canvas.drawCircle(c, 2, Paint()..color = primary);

    // three luminary medallions
    final medR = (inner + outer) / 2 - 30;
    final luminaries = <(double, String)>[
      (-math.pi / 3, sun),
      (math.pi / 2.4, moon),
      (math.pi - 0.3, rising),
    ];
    for (final (angle, sign) in luminaries) {
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * medR;
      canvas
        ..drawCircle(pos, 14, Paint()..color = medallionFill)
        ..drawCircle(
        pos,
        14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = primary.withValues(alpha: 0.7),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: glyphForSign(sign),
          style: TextStyle(fontSize: 15, color: primary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.primary != primary ||
      old.sun != sun ||
      old.moon != moon ||
      old.rising != rising;
}
