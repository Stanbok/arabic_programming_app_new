import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'shimmer_widget.dart';

/// Lesson card shimmer for loading state
class LessonCardShimmer extends StatelessWidget {
  const LessonCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: ShimmerWidget.circular(size: 48),
      ),
    );
  }
}

/// Path header shimmer for loading state
class PathHeaderShimmer extends StatelessWidget {
  const PathHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerWidget.circular(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerWidget.rectangular(
                      width: 120,
                      height: 20,
                      borderRadius: 6,
                    ),
                    SizedBox(height: 8),
                    ShimmerWidget.rectangular(
                      width: 80,
                      height: 14,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              const ShimmerWidget.rectangular(
                width: 32,
                height: 32,
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ShimmerWidget.rectangular(
            width: double.infinity,
            height: 8,
            borderRadius: 4,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerWidget.rectangular(
                width: 60,
                height: 14,
                borderRadius: 4,
              ),
              ShimmerWidget.rectangular(
                width: 40,
                height: 14,
                borderRadius: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lessons path shimmer showing multiple lesson cards
class LessonsPathShimmer extends StatelessWidget {
  final int itemCount;

  const LessonsPathShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final alignmentIndex = index % 3;
          final alignment = switch (alignmentIndex) {
            0 => Alignment.centerRight,
            1 => Alignment.center,
            2 => Alignment.centerLeft,
            _ => Alignment.center,
          };

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Align(
              alignment: alignment,
              child: const LessonCardShimmer(),
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }
}

/// Profile header shimmer
class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const ShimmerWidget.circular(size: 100),
          const SizedBox(height: 16),
          const ShimmerWidget.rectangular(
            width: 120,
            height: 24,
            borderRadius: 8,
          ),
          const SizedBox(height: 8),
          const ShimmerWidget.rectangular(
            width: 80,
            height: 16,
            borderRadius: 6,
          ),
        ],
      ),
    );
  }
}

/// Stats grid shimmer
class StatsGridShimmer extends StatelessWidget {
  const StatsGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index > 0 ? 8 : 0,
              right: index < 2 ? 8 : 0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                ShimmerWidget.rectangular(
                  width: 40,
                  height: 32,
                  borderRadius: 8,
                ),
                SizedBox(height: 8),
                ShimmerWidget.rectangular(
                  width: 60,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Achievement section shimmer
class AchievementSectionShimmer extends StatelessWidget {
  const AchievementSectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerWidget.rectangular(
          width: 100,
          height: 20,
          borderRadius: 6,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 70,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  ShimmerWidget.circular(size: 40),
                  SizedBox(height: 8),
                  ShimmerWidget.rectangular(
                    width: 50,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Card content shimmer for lesson viewer
class CardContentShimmer extends StatelessWidget {
  const CardContentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget.rectangular(
            width: 200,
            height: 28,
            borderRadius: 8,
          ),
          const SizedBox(height: 24),
          ...List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerWidget.rectangular(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
              ),
            );
          }),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: ShimmerWidget.rectangular(
                width: 200,
                height: 100,
                borderRadius: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full profile shimmer placeholder
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          ProfileHeaderShimmer(),
          SizedBox(height: 24),
          StatsGridShimmer(),
          SizedBox(height: 24),
          AchievementSectionShimmer(),
        ],
      ),
    );
  }
}
