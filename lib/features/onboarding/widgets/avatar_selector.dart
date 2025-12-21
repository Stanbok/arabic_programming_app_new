import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AvatarSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AvatarSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  // Avatar colors for variety
  static const List<Color> _avatarColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    Color(0xFF9F7AEA), // Purple
    Color(0xFF38A169), // Green
    Color(0xFFED8936), // Orange
    Color(0xFF3182CE), // Blue
    Color(0xFFE53E3E), // Red
    Color(0xFF00B5D8), // Cyan
    Color(0xFFD69E2E), // Yellow
  ];

  // Avatar icons for variety
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: AppConstants.avatarCount,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;
        final color = _avatarColors[index % _avatarColors.length];
        final icon = _avatarIcons[index % _avatarIcons.length];

        return GestureDetector(
          onTap: () => onSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: color, width: 3)
                  : null,
              boxShadow: isSelected
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
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}
