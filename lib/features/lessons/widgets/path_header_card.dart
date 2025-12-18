import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';
import '../../../models/path_model.dart';

class PathHeaderCard extends StatelessWidget {
  final PathModel path;
  final double progress;
  final int completedCount;
  final int totalLessons;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onNavigateBack;
  final VoidCallback onNavigateForward;
  final VoidCallback onDownloadAll;

  const PathHeaderCard({
    super.key,
    required this.path,
    required this.progress,
    required this.completedCount,
    required this.totalLessons,
    required this.canGoBack,
    required this.canGoForward,
    required this.onNavigateBack,
    required this.onNavigateForward,
    required this.onDownloadAll,
  });

  @override
  Widget build(BuildContext context) {
    final pathColor = Color(
      int.parse(path.color.replaceFirst('#', '0xFF')),
    );

    return FadeSlideIn(
      beginOffset: const Offset(0, -0.2),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              pathColor,
              pathColor.withOpacity(0.8),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: pathColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    path.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TapScale(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDownloadAll();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              path.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: AppDurations.slow,
              curve: AppCurves.standard,
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedCount / $totalLessons درس مكتمل',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: (progress * 100).toInt()),
                  duration: AppDurations.slow,
                  builder: (context, value, child) {
                    return Text(
                      '$value%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  enabled: canGoForward,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onNavigateForward();
                  },
                ),
                const SizedBox(width: 24),
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  enabled: canGoBack,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onNavigateBack();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: enabled ? 1.0 : 0.4,
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
