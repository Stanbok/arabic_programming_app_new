import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lesson_model.dart';
import '../../../data/repositories/progress_repository.dart';

class LessonNode extends StatelessWidget {
  final LessonModel lesson;
  final LockState lockState;
  final bool isOfflineAvailable;
  final AlignmentGeometry alignment;
  final VoidCallback onTap;

  const LessonNode({
    super.key,
    required this.lesson,
    required this.lockState,
    required this.isOfflineAvailable,
    required this.alignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = lockState == LockState.locked;
    final isCompleted = lockState == LockState.completed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nodeColor = isCompleted
        ? AppColors.success
        : isLocked
            ? AppColors.locked
            : AppColors.primary;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: nodeColor.withOpacity(isLocked ? 0.3 : 0.5),
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: isLocked
                ? null
                : [
                    BoxShadow(
                      color: nodeColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: Row(
              children: [
                // Lesson number circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: nodeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nodeColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            color: nodeColor,
                            size: 24,
                          )
                        : isLocked
                            ? Icon(
                                Icons.lock_rounded,
                                color: nodeColor,
                                size: 20,
                              )
                            : Text(
                                '${lesson.order}',
                                style: TextStyle(
                                  color: nodeColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Lesson info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOfflineAvailable
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_outlined,
                            size: 14,
                            color: isOfflineAvailable
                                ? AppColors.success
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOfflineAvailable ? 'متاح' : 'يتطلب تحميل',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOfflineAvailable
                                  ? AppColors.success
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                if (!isLocked)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: nodeColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
