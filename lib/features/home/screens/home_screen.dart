import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/content_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/app_startup_provider.dart';
import '../../../data/models/path_model.dart';
import '../../../data/repositories/progress_repository.dart' show ContentLockState;
import '../../onboarding/widgets/avatar_widget.dart';
import '../widgets/path_card.dart';
import '../widgets/update_notification_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Run startup tasks after first frame (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStartupService.initialize(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final userName = profile.name ?? 'متعلم';
    final pathsAsync = ref.watch(pathsProvider);

    return Scaffold(
      body: Container(
        // Subtle gradient background for depth
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.primaryDark.withOpacity(0.05)
                  : AppColors.primary.withOpacity(0.02),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: UpdateNotificationBanner(),
              ),

              // Enhanced Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Greeting with gradient text effect
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'مرحباً $userName!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'اختر مسارك وابدأ رحلة التعلم',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Enhanced avatar with glow effect
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: AvatarWidget(
                              avatarId: profile.avatarId,
                              size: 56,
                              showShadow: true,
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.profile),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Quick stats card
                      _buildStatsCard(context, pathsAsync),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'المسارات التعليمية',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Enhanced paths list
              pathsAsync.when(
                data: (paths) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _PathCardWrapper(
                          path: paths[index],
                          onTap: (lockState) => _handlePathTap(
                            context,
                            ref,
                            paths[index],
                            lockState,
                          ),
                        ),
                      ),
                      childCount: paths.length,
                    ),
                  ),
                ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: AppColors.error.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'خطأ في تحميل المسارات',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AsyncValue pathsAsync) {
    return pathsAsync.when(
      data: (paths) {
        final totalPaths = paths.length;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildStatItem(
                context,
                icon: Icons.route_rounded,
                label: 'المسارات',
                value: totalPaths.toString(),
                color: AppColors.primary,
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 40,
                color: AppColors.dividerLight.withOpacity(0.3),
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                context,
                icon: Icons.emoji_events_rounded,
                label: 'في انتظارك',
                value: '🚀',
                color: AppColors.secondary,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePathTap(
    BuildContext context,
    WidgetRef ref,
    PathModel path,
    ContentLockState lockState,
  ) {
    final profile = ref.read(profileProvider);

    switch (lockState) {
      case ContentLockState.locked:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('أكمل المسار السابق أولاً')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.locked,
          ),
        );
        break;
      case ContentLockState.available:
      case ContentLockState.completed:
        if (path.isVIP && !profile.isLinked) {
          Navigator.of(context).pushNamed(AppRoutes.premium);
          return;
        }
        Navigator.of(context).pushNamed(
          AppRoutes.lessons,
          arguments: {'path': path},
        );
        break;
    }
  }
}

/// Wrapper to handle async lock state
class _PathCardWrapper extends ConsumerWidget {
  final PathModel path;
  final void Function(ContentLockState) onTap;

  const _PathCardWrapper({
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockStateAsync = ref.watch(pathLockStateProvider(path));
    final progressAsync = ref.watch(pathProgressProvider(path.id));

    return lockStateAsync.when(
      data: (lockState) => progressAsync.when(
        data: (progress) => PathCard(
          path: path,
          lockState: lockState,
          progress: progress,
          onTap: () => onTap(lockState),
        ),
        loading: () => PathCard(
          path: path,
          lockState: lockState,
          progress: 0,
          onTap: () => onTap(lockState),
        ),
        error: (_, __) => PathCard(
          path: path,
          lockState: lockState,
          progress: 0,
          onTap: () => onTap(lockState),
        ),
      ),
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
