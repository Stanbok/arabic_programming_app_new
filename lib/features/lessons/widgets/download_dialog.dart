import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/error_handler.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lessons_provider.dart';

class DownloadDialog extends ConsumerStatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const DownloadDialog({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  ConsumerState<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends ConsumerState<DownloadDialog>
    with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  bool _isWatchingAd = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _downloadWithAd() async {
    HapticFeedback.mediumImpact();
    setState(() => _isWatchingAd = true);

    // Simulate watching ad
    _progressController.forward();
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isWatchingAd = false;
      _isDownloading = true;
    });
    _progressController.reset();
    _progressController.repeat();

    final service = ref.read(lessonsServiceProvider);
    final user = ref.read(currentUserProvider).value;

    if (user != null) {
      try {
        final success = await service.downloadLesson(widget.lessonId, user.uid);
        
        if (mounted) {
          _progressController.stop();
          Navigator.pop(context);
          HapticFeedback.heavyImpact();
          
          if (success) {
            ErrorHandler.showSuccessSnackBar(context, 'تم تحميل الدرس بنجاح');
          } else {
            ErrorHandler.showErrorSnackBar(context, 'فشل تحميل الدرس');
          }

          ref.invalidate(progressProvider);
        }
      } catch (e) {
        if (mounted) {
          _progressController.stop();
          Navigator.pop(context);
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }

  void _goToPremium() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    context.push(RouteNames.premium);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          ScaleBounceIn(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),

          const SizedBox(height: 16),

          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'تحميل الدرس',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: Text(
              widget.lessonTitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          if (_isDownloading || _isWatchingAd)
            FadeSlideIn(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: _isWatchingAd ? _progressController.value : null,
                              strokeWidth: 4,
                              color: AppColors.primary,
                              backgroundColor: AppColors.surfaceVariant,
                            ),
                          ),
                          Icon(
                            _isWatchingAd ? Icons.play_arrow_rounded : Icons.download_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: Text(
                      _isWatchingAd ? 'جاري مشاهدة الإعلان...' : 'جاري التحميل...',
                      key: ValueKey(_isWatchingAd),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _OptionCard(
                icon: Icons.workspace_premium_rounded,
                iconColor: AppColors.premium,
                title: 'اشتراك مميز',
                subtitle: 'تحميل غير محدود بدون إعلانات',
                onTap: _goToPremium,
                isPrimary: true,
              ),
            ),

            const SizedBox(height: 12),

            if (!isPremium)
              FadeSlideIn(
                delay: const Duration(milliseconds: 250),
                child: _OptionCard(
                  icon: Icons.play_circle_outline_rounded,
                  iconColor: AppColors.secondary,
                  title: 'شاهد إعلان',
                  subtitle: 'تحميل هذا الدرس مجاناً',
                  onTap: _downloadWithAd,
                ),
              ),
          ],

          const SizedBox(height: 16),

          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.premium.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? Border.all(color: AppColors.premium.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
