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
        // Stitch Official KinSync Emblem
        Container(
          height: 68,
          width: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF376847), Color(0xFF284E34)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.elev2,
          ),
          child: CustomPaint(
            painter: _KinSyncLogoPainter(),
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.ink,
              ),
            ),
            const Text(
              'Sync',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: Color(0xFF376847),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFE76F51),
                shape: BoxShape.circle,
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

/// Precise CustomPainter recreating the KinSync Two Partners Converging Emblem
class _KinSyncLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale, scale);
    canvas.translate(100, 100);
    canvas.scale(1.4, 1.4);

    // Partner 1 Head (Left)
    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-19, -26), 8.5, headPaint);

    // Partner 2 Head (Right)
    canvas.drawCircle(const Offset(19, -26), 8.5, headPaint);

    // Subtle aura base
    final auraPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final auraPath = Path()
      ..moveTo(-30, 20)
      ..cubicTo(-32, -2, -26, -16, -18, -18)
      ..cubicTo(-12, -19, -6, -12, 0, -4)
      ..cubicTo(6, -12, 12, -19, 18, -18)
      ..cubicTo(26, -16, 32, -2, 30, 20)
      ..cubicTo(28, 32, 16, 38, 0, 38)
      ..cubicTo(-16, 38, -28, 32, -30, 20)
      ..close();
    canvas.drawPath(auraPath, auraPaint);

    // Converging Silhouettes / Roofline / Tote loop
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(-24, 16)
      ..cubicTo(-26, 2, -22, -10, -14, -14)
      ..cubicTo(-8, -16, -3, -10, 0, -2)
      ..cubicTo(3, -10, 8, -16, 14, -14)
      ..cubicTo(22, -10, 26, 2, 24, 16)
      ..cubicTo(22, 28, 12, 34, 0, 34)
      ..cubicTo(-12, 34, -22, 28, -24, 16)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Inner negative space (Heart & leaf shape)
    final innerPaint = Paint()
      ..color = const Color(0xFF376847)
      ..style = PaintingStyle.fill;
    final innerPath = Path()
      ..moveTo(0, 6)
      ..cubicTo(-6, -2, -14, -2, -14, 7)
      ..cubicTo(-14, 15, 0, 24, 0, 24)
      ..cubicTo(0, 24, 14, 15, 14, 7)
      ..cubicTo(14, -2, 6, -2, 0, 6)
      ..close();
    canvas.drawPath(innerPath, innerPaint);

    // Coral accent core (Heart / spark)
    final coralPaint = Paint()
      ..color = const Color(0xFFE76F51)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 11), 5, coralPaint);

    final sparkPath = Path()
      ..moveTo(0, 5)
      ..cubicTo(2.2, 2.5, 5, 3, 5, 6)
      ..cubicTo(5, 8.5, 0, 12, 0, 12)
      ..cubicTo(0, 12, -5, 8.5, -5, 6)
      ..cubicTo(-5, 3, -2.2, 2.5, 0, 5)
      ..close();
    canvas.drawPath(sparkPath, coralPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
