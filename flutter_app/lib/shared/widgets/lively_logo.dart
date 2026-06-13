import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LIVELY brand mark.
///
/// Tries to render `assets/images/lively_logo.png` first (the official
/// gold ram-horns + LIVELY wordmark). If the asset isn't available, falls
/// back to a programmatic gold mark + serif wordmark drawn entirely with
/// Flutter painting primitives so the screen still looks branded.
class LivelyLogo extends StatelessWidget {
  const LivelyLogo({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/lively_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _PaintedFallback(size: size),
    );
  }
}

class _PaintedFallback extends StatelessWidget {
  const _PaintedFallback({required this.size});
  final double size;

  static const _goldStart = Color(0xFFE9D49A);
  static const _goldMid = Color(0xFFD4B16A);
  static const _goldEnd = Color(0xFFB58A4A);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 0.78,
          child: CustomPaint(painter: _RamHornsPainter()),
        ),
        SizedBox(height: size * 0.06),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [_goldStart, _goldMid, _goldEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect),
          child: Text(
            'LIVELY',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white,
              fontSize: size * 0.30,
              fontWeight: FontWeight.w600,
              letterSpacing: size * 0.04,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RamHornsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final goldShader = const LinearGradient(
      colors: [
        Color(0xFFF1DDA8),
        Color(0xFFD8B26C),
        Color(0xFF9F7637),
      ],
      stops: [0, 0.55, 1],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    final cx = w * 0.50;
    final bottomY = h * 0.96;
    final topY = h * 0.14;
    final outerLeftX = w * 0.22;
    final outerRightX = w * 0.78;
    final innerLeftX = w * 0.40;
    final innerRightX = w * 0.60;

    path
      ..moveTo(cx, bottomY)
      ..cubicTo(
        cx - w * 0.05, h * 0.65,
        outerLeftX - w * 0.04, h * 0.45,
        outerLeftX, topY + h * 0.05,
      )
      ..cubicTo(
        outerLeftX + w * 0.02, topY - h * 0.05,
        outerLeftX + w * 0.10, topY - h * 0.02,
        outerLeftX + w * 0.13, topY + h * 0.04,
      )
      ..cubicTo(
        outerLeftX + w * 0.10, topY + h * 0.10,
        innerLeftX - w * 0.02, h * 0.50,
        innerLeftX, h * 0.78,
      )
      ..lineTo(cx, bottomY - h * 0.02)
      ..lineTo(innerRightX, h * 0.78)
      ..cubicTo(
        innerRightX + w * 0.02, h * 0.50,
        outerRightX - w * 0.10, topY + h * 0.10,
        outerRightX - w * 0.13, topY + h * 0.04,
      )
      ..cubicTo(
        outerRightX - w * 0.10, topY - h * 0.02,
        outerRightX - w * 0.02, topY - h * 0.05,
        outerRightX, topY + h * 0.05,
      )
      ..cubicTo(
        outerRightX + w * 0.04, h * 0.45,
        cx + w * 0.05, h * 0.65,
        cx, bottomY,
      )
      ..close();

    canvas
      ..drawPath(
        path,
        Paint()
          ..shader = goldShader
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12),
      )
      ..drawPath(path, Paint()..shader = goldShader)
      ..drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFF4D6).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
  }

  @override
  bool shouldRepaint(covariant _RamHornsPainter oldDelegate) => false;
}
