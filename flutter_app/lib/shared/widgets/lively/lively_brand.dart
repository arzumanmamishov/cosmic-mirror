import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:flutter/material.dart';

/// The Lively mark — an 8-point bronze sparkle inside a hair-thin gold ring.
class LivelyMark extends StatelessWidget {
  const LivelyMark({this.size = 28, this.color, this.ring, super.key});

  final double size;
  final Color? color;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(
          color: color ?? p.primary,
          ring: ring ?? p.glassBorder,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.color, required this.ring});
  final Color color;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // thin outer ring
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, size.width * 0.02)
        ..color = ring,
    );

    // 8-point sparkle — long axes + short diagonals.
    final fill = Paint()..color = color;
    final long = r * 0.82;
    final short = r * 0.30;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final isLong = i.isEven;
      final reach = isLong ? long : short;
      final a = (i / 8) * math.pi * 2 - math.pi / 2;
      final tip = c + Offset(math.cos(a), math.sin(a)) * reach;
      // waist between points
      final wa = a + math.pi / 8;
      final waist = c + Offset(math.cos(wa), math.sin(wa)) * (r * 0.16);
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(waist.dx, waist.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawCircle(c, r * 0.10, fill);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.color != color || old.ring != ring;
}

/// The "Lively" wordmark — Instrument Serif italic.
class LivelyWordmark extends StatelessWidget {
  const LivelyWordmark({this.size = 22, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      'Lively',
      style: LivelyType.d3(color ?? p.textPrimary).copyWith(fontSize: size),
    );
  }
}

/// Mark + wordmark lockup, used top-left on Auth.
class LivelyLockup extends StatelessWidget {
  const LivelyLockup({this.markSize = 26, this.wordSize = 22, super.key});

  final double markSize;
  final double wordSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LivelyMark(size: markSize),
        const SizedBox(width: 10),
        LivelyWordmark(size: wordSize),
      ],
    );
  }
}
