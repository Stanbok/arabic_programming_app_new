import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> _particles;

  ConfettiPainter({required this.progress})
      : _particles = List.generate(60, (index) => _ConfettiParticle(index));

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(
          (1 - progress * 0.5).clamp(0.3, 1.0),
        )
        ..style = PaintingStyle.fill;

      // Calculate position based on progress
      final x = particle.startX * size.width +
          math.sin(progress * math.pi * 2 + particle.wobble) * 30;
      final y = (particle.startY + progress * 1.5) * size.height;

      // Skip if particle is off screen
      if (y > size.height) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * particle.rotationSpeed);

      // Draw different shapes
      switch (particle.shape) {
        case 0: // Rectangle
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            paint,
          );
          break;
        case 1: // Circle
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case 2: // Triangle
          final path = Path();
          path.moveTo(0, -particle.size / 2);
          path.lineTo(particle.size / 2, particle.size / 2);
          path.lineTo(-particle.size / 2, particle.size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double size;
  final Color color;
  final int shape;
  final double rotationSpeed;
  final double wobble;

  static final _random = math.Random();
  static final _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.starGold,
    AppColors.info,
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFE66D),
  ];

  _ConfettiParticle(int index)
      : startX = _random.nextDouble(),
        startY = _random.nextDouble() * -0.5,
        size = _random.nextDouble() * 8 + 6,
        color = _colors[_random.nextInt(_colors.length)],
        shape = _random.nextInt(3),
        rotationSpeed = (_random.nextDouble() - 0.5) * 10,
        wobble = _random.nextDouble() * math.pi * 2;
}
