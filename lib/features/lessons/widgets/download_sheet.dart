import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/lesson_model.dart';

class DownloadSheet extends StatelessWidget {
  final LessonModel lesson;
  final bool isPremium;
  final VoidCallback onSubscribe;
  final VoidCallback onWatchAd;

  const DownloadSheet({
    super.key,
    required this.lesson,
    required this.isPremium,
    required this.onSubscribe,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Download Icon with gradient background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primaryLight.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'تحميل الدرس',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            lesson.title,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          const Text(
            'حمّل الدرس للوصول إليه بدون إنترنت',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Premium Subscribe Option
          _OptionCard(
            icon: Icons.workspace_premium,
            iconColor: AppColors.premium,
            title: 'اشترك في Premium',
            subtitle: 'تحميل غير محدود + بدون إعلانات',
            isPrimary: true,
            onTap: () {
              Navigator.pop(context);
              onSubscribe();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Watch Ad Option
          _OptionCard(
            icon: Icons.play_circle_outline,
            iconColor: AppColors.textSecondary,
            title: 'شاهد إعلان',
            subtitle: 'تحميل هذا الدرس مجاناً',
            isPrimary: false,
            onTap: () {
              Navigator.pop(context);
              onWatchAd();
            },
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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
  final bool isPrimary;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [AppColors.premium, Color(0xFFE8C547)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrimary
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPrimary ? Colors.white : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
