import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TrophyWidget extends StatelessWidget {
  final Color color;
  final double size;

  const TrophyWidget({
    super.key,
    this.color = AppColors.starGold,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.75,
          height: size * 0.75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.starGold.withOpacity(0.4),
                      AppColors.starGold.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              // Trophy icon
              Icon(
                Icons.emoji_events_rounded,
                size: size * 0.45,
                color: AppColors.starGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
