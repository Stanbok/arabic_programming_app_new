import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/path_model.dart';
import '../../../data/repositories/progress_repository.dart';

class PathCard extends StatelessWidget {
  final PathModel path;
  final LockState lockState;
  final double progress;
  final VoidCallback onTap;

  const PathCard({
    super.key,
    required this.path,
    required this.lockState,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = lockState == LockState.locked;
    final isCompleted = lockState == LockState.completed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.5)
                : isLocked
                    ? AppColors.dividerLight
                    : AppColors.primary.withOpacity(0.3),
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: (isCompleted ? AppColors.success : AppColors.primary)
                        .withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Opacity(
          opacity: isLocked ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Path icon/thumbnail
                _buildThumbnail(context, isLocked, isCompleted),
                const SizedBox(width: 16),
                
                // Path info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              path.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (path.isVIP) _buildVIPBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        path.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress bar and level
                      Row(
                        children: [
                          _buildLevelChip(context),
                          const SizedBox(width: 12),
                          Expanded(child: _buildProgressBar(context)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Lock/Arrow icon
                _buildStatusIcon(isLocked, isCompleted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isLocked, bool isCompleted) {
    final color = isCompleted
        ? AppColors.success
        : isLocked
            ? AppColors.locked
            : AppColors.primary;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          _getPathIcon(),
          color: color,
          size: 32,
        ),
      ),
    );
  }

  IconData _getPathIcon() {
    switch (path.order) {
      case 1:
        return Icons.play_circle_outline_rounded;
      case 2:
        return Icons.alt_route_rounded;
      case 3:
        return Icons.functions_rounded;
      case 4:
        return Icons.data_array_rounded;
      default:
        return Icons.code_rounded;
    }
  }

  Widget _buildVIPBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.vipGold, AppColors.vipGoldLight],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 12),
          SizedBox(width: 2),
          Text(
            'VIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        path.level,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'التقدم',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.dividerLight,
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0 ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(bool isLocked, bool isCompleted) {
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.locked.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: AppColors.locked,
          size: 20,
        ),
      );
    }

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.success,
          size: 20,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }
}
