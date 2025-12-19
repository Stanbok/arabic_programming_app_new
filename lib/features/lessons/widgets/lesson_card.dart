import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/lesson_model.dart';
import '../../../core/services/cache_service.dart';

enum LessonState { locked, available, downloaded, completed }

class LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final LessonState state;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.state,
    required this.index,
    required this.onTap,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = state == LessonState.locked;
    final isCompleted = state == LessonState.completed;
    final isContentCached = CacheService.isLessonContentCached(lesson.id);

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted ? AppColors.success : AppColors.border,
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: isLocked
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Lesson Number/Status
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCircleColor(),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _getCircleContent(),
                ),
              ),
              const SizedBox(width: 16),
              
              // Lesson Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.cards.length} بطاقة • ${lesson.quiz.length} سؤال',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!isLocked && !isCompleted && !isContentCached && onDownload != null)
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(
                    Icons.download,
                    color: AppColors.primary,
                  ),
                  tooltip: 'تحميل للعمل دون إنترنت',
                )
              else if (isContentCached && !isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.offline_pin,
                        size: 14,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'محمّل',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCircleColor() {
    switch (state) {
      case LessonState.locked:
        return AppColors.locked.withOpacity(0.2);
      case LessonState.available:
        return AppColors.primary.withOpacity(0.1);
      case LessonState.downloaded:
        return AppColors.primary.withOpacity(0.1);
      case LessonState.completed:
        return AppColors.success;
    }
  }

  Widget _getCircleContent() {
    switch (state) {
      case LessonState.locked:
        return const Icon(
          Icons.lock,
          color: AppColors.locked,
          size: 20,
        );
      case LessonState.available:
      case LessonState.downloaded:
        return Text(
          index.toString(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        );
      case LessonState.completed:
        return const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        );
    }
  }
}
