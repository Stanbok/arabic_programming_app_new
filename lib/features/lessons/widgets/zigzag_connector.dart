import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ZigzagConnector extends StatelessWidget {
  final bool goingRight;
  final double height;

  const ZigzagConnector({
    super.key,
    required this.goingRight,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _ZigzagPainter(
          goingRight: goingRight,
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  final bool goingRight;
  final Color color;

  _ZigzagPainter({
    required this.goingRight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    final startX = goingRight ? size.width * 0.35 : size.width * 0.65;
    final endX = goingRight ? size.width * 0.65 : size.width * 0.35;
    
    path.moveTo(startX, 0);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      endX,
      size.height,
    );

    canvas.drawPath(path, paint);

    // Draw dot at end
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(endX, size.height), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ZigzagPainter oldDelegate) {
    return oldDelegate.goingRight != goingRight || oldDelegate.color != color;
  }
}
