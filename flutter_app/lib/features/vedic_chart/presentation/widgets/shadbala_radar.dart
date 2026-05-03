import 'dart:math' as math;

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/yoga.dart';
import 'package:flutter/material.dart';

/// Six-axis radar chart showing the breakdown of a planet's Shadbala.
/// Each axis = one of the six Balas, scaled relative to the classical
/// "required" threshold for that planet.
class ShadbalaRadar extends StatelessWidget {
  const ShadbalaRadar({
    required this.planet,
    required this.bala,
    this.size = 240,
    super.key,
  });

  final String planet;
  final ShadbalaBreakdown bala;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(
          planet,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${bala.total.toStringAsFixed(0)} / ${bala.required.toStringAsFixed(0)} Virupas — '
          '${bala.sufficient ? "STRONG" : "WEAK"}',
          style: TextStyle(
            color: bala.sufficient ? p.success : p.warning,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RadarPainter(
              values: [
                bala.sthana,
                bala.dig,
                bala.kala,
                bala.chesta,
                bala.naisargika,
                bala.drik,
              ],
              labels: const [
                'Sthana',
                'Dig',
                'Kala',
                'Chesta',
                'Naisargika',
                'Drik',
              ],
              max: 60,
              gridColor: p.glassBorder,
              fillColor: p.primary.withValues(alpha: 0.25),
              strokeColor: p.primary,
              labelColor: p.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.labels,
    required this.max,
    required this.gridColor,
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
  });

  final List<double> values;
  final List<String> labels;
  final double max;
  final Color gridColor;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final n = values.length;
    const twoPi = math.pi * 2;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Concentric grid rings.
    for (var i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      final path = Path();
      for (var k = 0; k < n; k++) {
        final theta = -math.pi / 2 + twoPi * k / n;
        final pt = Offset(
          center.dx + r * math.cos(theta),
          center.dy + r * math.sin(theta),
        );
        if (k == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis lines + labels
    for (var k = 0; k < n; k++) {
      final theta = -math.pi / 2 + twoPi * k / n;
      final outer = Offset(
        center.dx + radius * math.cos(theta),
        center.dy + radius * math.sin(theta),
      );
      canvas.drawLine(center, outer, gridPaint);
      final labelPos = Offset(
        center.dx + (radius + 16) * math.cos(theta),
        center.dy + (radius + 16) * math.sin(theta),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[k],
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }

    // Data polygon
    final dataPath = Path();
    for (var k = 0; k < n; k++) {
      final theta = -math.pi / 2 + twoPi * k / n;
      final v = (values[k].clamp(-max, max)) / max;
      final r = radius * v.abs();
      final pt = Offset(
        center.dx + r * math.cos(theta),
        center.dy + r * math.sin(theta),
      );
      if (k == 0) {
        dataPath.moveTo(pt.dx, pt.dy);
      } else {
        dataPath.lineTo(pt.dx, pt.dy);
      }
    }
    dataPath.close();
    canvas
      ..drawPath(dataPath, Paint()..color = fillColor)
      ..drawPath(
        dataPath,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values || old.max != max;
}
