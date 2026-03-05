import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Reusable avatar widget used across the app
class AvatarWidget extends StatelessWidget {
  final int avatarId;
  final double size;
  final bool showBorder;
  final bool showShadow;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.avatarId,
    this.size = 48,
    this.showBorder = false,
    this.showShadow = false,
    this.onTap,
  });

  static const List<Color> _avatarColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    Color(0xFF9F7AEA),
    Color(0xFF38A169),
    Color(0xFFED8936),
    Color(0xFF3182CE),
    Color(0xFFE53E3E),
    Color(0xFF00B5D8),
    Color(0xFFD69E2E),
  ];

  static const List<IconData> _avatarIcons = [
    Icons.person_rounded,
    Icons.face_rounded,
    Icons.sentiment_satisfied_alt_rounded,
    Icons.emoji_emotions_rounded,
    Icons.psychology_rounded,
    Icons.school_rounded,
    Icons.auto_awesome_rounded,
    Icons.star_rounded,
    Icons.rocket_launch_rounded,
    Icons.code_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[avatarId % _avatarColors.length];
    final icon = _avatarIcons[avatarId % _avatarIcons.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
