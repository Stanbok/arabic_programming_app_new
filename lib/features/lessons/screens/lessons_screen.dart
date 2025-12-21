import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/content_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../data/models/path_model.dart';
import '../../../data/models/lesson_model.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/content_repository.dart';
import '../../../data/services/ad_service.dart';
import '../../lesson_viewer/screens/lesson_viewer_screen.dart';
import '../widgets/lesson_node.dart';
import '../widgets/zigzag_connector.dart';
import '../../../core/navigation/app_router.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  final PathModel path;

  const LessonsScreen({super.key, required this.path});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  bool _isDownloading = false;
  String? _downloadingLessonId;

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider(widget.path.id));
    final downloadStatusAsync = ref.watch(pathDownloadStatusProvider(widget.path.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path.name),
        centerTitle: true,
        actions: [
          // Download all button (hidden for Path 1)
          if (!widget.path.bundled)
            downloadStatusAsync.when(
              data: (status) {
                final (downloaded, total) = status;
                final allDownloaded = downloaded == total;
                return IconButton(
                  onPressed: allDownloaded || _isDownloading
                      ? null
                      : () => _downloadAll(context),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          allDownloaded
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_download_rounded,
                          color: allDownloaded ? AppColors.success : null,
                        ),
                  tooltip: allDownloaded ? 'تم التحميل' : 'تحميل الكل',
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: lessonsAsync.when(
        data: (lessons) => _buildLessonsPath(context, lessons),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildLessonsPath(BuildContext context, List<LessonModel> lessons) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Path header
          _buildPathHeader(context),
          const SizedBox(height: 32),
          
          // Zigzag lessons path
          ...List.generate(lessons.length, (index) {
            final lesson = lessons[index];
            final isLast = index == lessons.length - 1;
            final isEven = index % 2 == 0;

            return Column(
              children: [
                _LessonNodeWrapper(
                  lesson: lesson,
                  isEven: isEven,
                  pathBundled: widget.path.bundled,
                  onTap: (lockState) => _handleLessonTap(
                    context,
                    lesson,
                    lockState,
                  ),
                ),
                if (!isLast)
                  ZigzagConnector(
                    goingRight: isEven,
                    height: 48,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPathHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPathIcon(),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.path.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.path.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPathIcon() {
    switch (widget.path.order) {
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

  Future<void> _handleLessonTap(
    BuildContext context,
    LessonModel lesson,
    LockState lockState,
  ) async {
    if (lockState == LockState.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أكمل الدرس السابق أولاً'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Path 1 lessons are always available
    if (widget.path.bundled) {
      _openLesson(lesson);
      return;
    }

    // Check if lesson is cached
    final isAvailable = ContentRepository.instance.isLessonAvailableOffline(
      lesson.id,
      lesson.pathId,
    );

    if (isAvailable) {
      _openLesson(lesson);
      return;
    }

    // Show download dialog for uncached lessons
    final profile = ref.read(profileProvider);
    if (profile.isPremium) {
      await _downloadAndOpenLesson(lesson);
    } else {
      _showAdOrPremiumDialog(context, lesson);
    }
  }

  void _showAdOrPremiumDialog(BuildContext context, LessonModel lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.cloud_download_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'تحميل الدرس',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'شاهد إعلاناً قصيراً لتحميل هذا الدرس مجاناً',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _watchAdAndDownload(lesson);
                },
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text('شاهد الإعلان'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.premium);
                },
                icon: const Icon(Icons.star_rounded, color: AppColors.vipGold),
                label: const Text('اشترك في Premium'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _watchAdAndDownload(LessonModel lesson) async {
    final adService = AdService.instance;
    
    // Show loading
    setState(() => _isDownloading = true);
    
    try {
      final adWatched = await adService.showRewardedAd();
      if (adWatched) {
        await _downloadAndOpenLesson(lesson);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم مشاهدة الإعلان بالكامل'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadAndOpenLesson(LessonModel lesson) async {
    setState(() {
      _isDownloading = true;
      _downloadingLessonId = lesson.id;
    });

    try {
      final content = await ContentRepository.instance.downloadAndCacheLesson(
        lessonId: lesson.id,
        pathId: lesson.pathId,
      );

      if (!mounted) return;

      if (content != null) {
        // Refresh the offline status
        ref.invalidate(lessonOfflineAvailableProvider((
          lessonId: lesson.id,
          pathId: lesson.pathId,
        )));
        ref.invalidate(pathDownloadStatusProvider(lesson.pathId));
        
        _openLesson(lesson);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحميل الدرس. تحقق من اتصال الإنترنت'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحميل: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingLessonId = null;
        });
      }
    }
  }

  void _openLesson(LessonModel lesson) {
    Navigator.of(context).pushNamed(
      AppRoutes.lessonViewer,
      arguments: {
        'lesson': lesson,
        'pathId': widget.path.id,
      },
    );
  }

  Future<void> _downloadAll(BuildContext context) async {
    final profile = ref.read(profileProvider);
    if (!profile.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذه الميزة متاحة للمشتركين فقط'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);
    
    try {
      final downloadedCount = await ContentRepository.instance.downloadAllLessonsForPath(
        pathId: widget.path.id,
        onProgress: (downloaded, total) {
          // Could update UI with progress here if needed
        },
      );

      if (mounted) {
        // Refresh download status
        ref.invalidate(pathDownloadStatusProvider(widget.path.id));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحميل $downloadedCount درس بنجاح'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحميل: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
}

/// Wrapper to handle async lesson lock state
class _LessonNodeWrapper extends ConsumerWidget {
  final LessonModel lesson;
  final bool isEven;
  final bool pathBundled;
  final void Function(LockState) onTap;

  const _LessonNodeWrapper({
    required this.lesson,
    required this.isEven,
    required this.pathBundled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockStateAsync = ref.watch(lessonLockStateProvider(lesson));
    final isOffline = ref.watch(lessonOfflineAvailableProvider((
      lessonId: lesson.id,
      pathId: lesson.pathId,
    )));

    return lockStateAsync.when(
      data: (lockState) => LessonNode(
        lesson: lesson,
        lockState: lockState,
        isOfflineAvailable: isOffline,
        alignment: isEven ? Alignment.centerRight : Alignment.centerLeft,
        onTap: () => onTap(lockState),
      ),
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
