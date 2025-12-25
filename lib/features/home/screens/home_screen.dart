import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/content_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/sync_provider.dart';
import '../../../data/models/path_model.dart';
import '../../../data/repositories/progress_repository.dart' show ContentLockState;
import '../../onboarding/widgets/avatar_widget.dart';
import '../widgets/path_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final userName = profile.name ?? 'متعلم';
    final pathsAsync = ref.watch(pathsProvider);
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً $userName!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'اختر مسارك وابدأ رحلة التعلم',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        AvatarWidget(
                          avatarId: profile.avatarId,
                          size: 48,
                          showShadow: true,
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.profile),
                        ),
                      ],
                    ),
                    if (syncState.status == SyncStatus.syncing)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            pathsAsync.when(
              data: (paths) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
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
                child: Center(child: Text('خطأ في تحميل المسارات: $e')),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  void _handlePathTap(
    BuildContext context,
    WidgetRef ref,
    PathModel path,
    ContentLockState lockState, // Use ContentLockState
  ) {
    final profile = ref.read(profileProvider);

    switch (lockState) {
      case ContentLockState.locked:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أكمل المسار السابق أولاً'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case ContentLockState.available:
      case ContentLockState.completed:
        // VIP path requires linking first
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
  final void Function(ContentLockState) onTap; // Use ContentLockState

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
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
