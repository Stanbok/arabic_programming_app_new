import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/animations.dart';
import '../../../models/lesson_model.dart';
import '../../../models/progress_model.dart';
import '../../../providers/lessons_provider.dart';
import 'download_dialog.dart';

class LessonCard extends ConsumerStatefulWidget {
  final LessonModel lesson;
  final LessonProgress? progress;
  final int index;
  final bool isCurrentLesson;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.progress,
    required this.index,
    required this.isCurrentLesson,
  });

  @override
  ConsumerState<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends ConsumerState<LessonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: AppDurations.fastest,
    );
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: AppCurves.standard),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonStateProvider(widget.lesson.id));
    final isDownloading =
        ref.watch(lessonDownloadingProvider).contains(widget.lesson.id);

    final isLocked = state == LessonState.locked;
    final isCompleted = state == LessonState.completed;
    final isDownloaded =
        state == LessonState.downloaded || state == LessonState.completed;

    final cardColor = switch (state) {
      LessonState.locked => AppColors.lessonLocked,
      LessonState.available => AppColors.lessonAvailable,
      LessonState.downloaded => AppColors.lessonDownloaded,
      LessonState.completed => AppColors.lessonCompleted,
    };

    final opacity = isLocked ? 0.5 : 1.0;

    return StaggeredListItem(
      index: widget.index,
      baseDelay: const Duration(milliseconds: 200),
      staggerDelay: const Duration(milliseconds: 80),
      child: GestureDetector(
        onTapDown: isLocked ? null : (_) => _tapController.forward(),
        onTapUp: isLocked
            ? null
            : (_) {
                _tapController.reverse();
                HapticFeedback.lightImpact();
                ref.read(currentLessonProvider.notifier).state = widget.lesson;
                context.push(RouteNames.lessonViewer, extra: widget.lesson.id);
              },
        onTapCancel: isLocked ? null : () => _tapController.reverse(),
        child: ScaleTransition(
          scale: _tapScaleAnimation,
          child: AnimatedScale(
            scale: widget.isCurrentLesson ? 1.08 : 1.0,
            duration: AppDurations.normal,
            curve: AppCurves.spring,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: AppDurations.fast,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cardColor,
                    width: isCompleted ? 4 : 3,
                  ),
                  boxShadow: widget.isCurrentLesson
                      ? [
                          BoxShadow(
                            color: cardColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIcon(state, isDownloading),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.index + 1}',
                            style: TextStyle(
                              color: isLocked
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state == LessonState.available && !isDownloading)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: TapScale(
                          onTap: () => _showDownloadDialog(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    if (isDownloaded && !isDownloading)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.offline_pin_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if (isCompleted)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: ScaleBounceIn(
                          delay: Duration(milliseconds: 300 + widget.index * 50),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(LessonState state, bool isDownloading) {
    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    final icon = switch (state) {
      LessonState.locked => Icons.lock_rounded,
      LessonState.available => Icons.play_arrow_rounded,
      LessonState.downloaded => Icons.play_arrow_rounded,
      LessonState.completed => Icons.check_rounded,
    };

    final color = switch (state) {
      LessonState.locked => AppColors.textHint,
      LessonState.available => AppColors.primary,
      LessonState.downloaded => AppColors.lessonDownloaded,
      LessonState.completed => AppColors.success,
    };

    return AnimatedSwitcher(
      duration: AppDurations.fast,
      child: Icon(
        icon,
        key: ValueKey(state),
        color: color,
        size: 28,
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DownloadDialog(
        lessonId: widget.lesson.id,
        lessonTitle: widget.lesson.title,
      ),
    );
  }
}
