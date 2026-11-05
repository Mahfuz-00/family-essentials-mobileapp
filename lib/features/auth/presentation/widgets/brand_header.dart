import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stitch Official Emblem
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF376847), Color(0xFF2D553A)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.elev2,
          ),
          child: CustomPaint(
            painter: _BrandLogoPainter(),
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Family',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppTheme.ink,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Essentials',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: Color(0xFF376847),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle ?? 'Household Logistics',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

/// Precise CustomPainter recreating the Stitch Brand Emblem
class _BrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Handle loop
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final handlePath = Path()
      ..moveTo(78, 68)
      ..cubicTo(78, 54, 88, 44, 100, 44)
      ..cubicTo(112, 44, 122, 54, 122, 68);
    canvas.drawPath(handlePath, handlePaint);

    // White bag & home body
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bodyPath = Path()
      ..moveTo(100, 52)
      ..lineTo(150, 86)
      ..lineTo(144, 146)
      ..cubicTo(143, 152, 138, 157, 131, 157)
      ..lineTo(69, 157)
      ..cubicTo(62, 157, 57, 152, 56, 146)
      ..lineTo(47, 95)
      ..lineTo(100, 52)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = const Color(0xFF376847)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(84, 110)
      ..lineTo(98, 124)
      ..lineTo(132, 88);
    canvas.drawPath(checkPath, checkPaint);

    // Coral sprout accent
    final accentPaint = Paint()
      ..color = const Color(0xFFE76F51)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(132, 74), 9, accentPaint);

    final sproutPath = Path()
      ..moveTo(132, 83)
      ..cubicTo(138, 83, 144, 79, 144, 73)
      ..cubicTo(144, 67, 132, 58, 132, 58)
      ..cubicTo(132, 58, 120, 67, 120, 73)
      ..cubicTo(120, 79, 126, 83, 132, 83)
      ..close();
    canvas.drawPath(sproutPath, accentPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
