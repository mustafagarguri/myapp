import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DropLogoPainter(),
      ),
    );
  }
}

class _DropLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final dropPath = Path()
      ..moveTo(centerX, size.height * 0.05)
      ..cubicTo(size.width * 0.85, size.height * 0.35, size.width * 0.9, size.height * 0.65, centerX,
          size.height * 0.95)
      ..cubicTo(size.width * 0.1, size.height * 0.65, size.width * 0.15, size.height * 0.35, centerX,
          size.height * 0.05)
      ..close();

    final redPaint = Paint()..color = const Color(0xFFD7192D);
    canvas.drawPath(dropPath, redPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(centerX + size.width * 0.12, size.height * 0.76), size.width * 0.18, shadowPaint);

    final pulsePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final y = size.height * 0.62;
    final pulse = Path()
      ..moveTo(size.width * 0.22, y)
      ..lineTo(size.width * 0.36, y)
      ..lineTo(size.width * 0.44, y - size.height * 0.1)
      ..lineTo(size.width * 0.5, y + size.height * 0.12)
      ..lineTo(size.width * 0.58, y - size.height * 0.16)
      ..lineTo(size.width * 0.66, y)
      ..lineTo(size.width * 0.8, y);

    canvas.drawPath(pulse, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

