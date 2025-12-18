import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../providers/lessons_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../widgets/path_header_card.dart';
import '../widgets/lesson_path.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialPath();
  }

  Future<void> _loadInitialPath() async {
    final paths = await ref.read(pathsProvider.future);
    if (paths.isNotEmpty && ref.read(currentPathProvider) == null) {
      ref.read(currentPathProvider.notifier).state = paths.first;
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(pathsProvider);
    ref.invalidate(lessonsProvider);
    ref.invalidate(progressProvider);
  }

  void _navigatePath(int direction) {
    final paths = ref.read(pathsProvider).value ?? [];
    final currentPath = ref.read(currentPathProvider);
    if (paths.isEmpty || currentPath == null) return;

    final currentIndex = paths.indexWhere((p) => p.id == currentPath.id);
    final newIndex = currentIndex + direction;

    if (newIndex >= 0 && newIndex < paths.length) {
      ref.read(currentPathProvider.notifier).state = paths[newIndex];
      ref.invalidate(lessonsProvider);
      ref.invalidate(progressProvider);
    }
  }

  void _onDownloadAllTap() {
    context.push(RouteNames.premium);
  }

  @override
  Widget build(BuildContext context) {
    final pathsAsync = ref.watch(pathsProvider);
    final currentPath = ref.watch(currentPathProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final progressAsync = ref.watch(progressProvider);
    final progress = ref.watch(pathProgressProvider);
    final completedCount = ref.watch(completedLessonsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Path Header
              SliverToBoxAdapter(
                child: pathsAsync.when(
                  data: (paths) {
                    if (currentPath == null) {
                      return const SizedBox.shrink();
                    }
                    final currentIndex =
                        paths.indexWhere((p) => p.id == currentPath.id);
                    return PathHeaderCard(
                      path: currentPath,
                      progress: progress,
                      completedCount: completedCount,
                      totalLessons: lessonsAsync.value?.length ?? 0,
                      canGoBack: currentIndex > 0,
                      canGoForward: currentIndex < paths.length - 1,
                      onNavigateBack: () => _navigatePath(-1),
                      onNavigateForward: () => _navigatePath(1),
                      onDownloadAll: _onDownloadAllTap,
                    );
                  },
                  loading: () => const PathHeaderShimmer(),
                  error: (e, _) => _ErrorWidget(
                    message: 'خطأ في تحميل المسارات',
                    onRetry: _onRefresh,
                  ),
                ),
              ),

              // Lessons Path
              lessonsAsync.when(
                data: (lessons) {
                  if (lessons.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyState(
                        icon: Icons.school_outlined,
                        message: AppStrings.noLessonsAvailable,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    sliver: LessonPath(
                      lessons: lessons,
                      progress: progressAsync.value ?? {},
                      scrollController: _scrollController,
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  sliver: const LessonsPathShimmer(itemCount: 6),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: _ErrorWidget(
                    message: 'خطأ في تحميل الدروس',
                    onRetry: _onRefresh,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppStrings.retry),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.textHint,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
