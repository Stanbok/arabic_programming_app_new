import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';

class AchievementSection extends StatelessWidget {
  final UserModel user;

  const AchievementSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final achievements = _getAchievements(user);

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإنجازات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((achievement) {
              return _AchievementBadge(achievement: achievement);
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<_Achievement> _getAchievements(UserModel user) {
    return [
      _Achievement(
        icon: '🎯',
        title: 'البداية',
        description: 'أكمل أول درس',
        isUnlocked: user.completedLessons >= 1,
      ),
      _Achievement(
        icon: '🔥',
        title: 'متحمس',
        description: '3 أيام متتالية',
        isUnlocked: user.streak >= 3,
      ),
      _Achievement(
        icon: '⚡',
        title: 'نشيط',
        description: 'اجمع 100 XP',
        isUnlocked: user.xp >= 100,
      ),
      _Achievement(
        icon: '📚',
        title: 'قارئ',
        description: 'أكمل 5 دروس',
        isUnlocked: user.completedLessons >= 5,
      ),
      _Achievement(
        icon: '🏆',
        title: 'بطل',
        description: 'أكمل 10 دروس',
        isUnlocked: user.completedLessons >= 10,
      ),
      _Achievement(
        icon: '💎',
        title: 'خبير',
        description: 'اجمع 1000 XP',
        isUnlocked: user.xp >= 1000,
      ),
      _Achievement(
        icon: '🌟',
        title: 'ملتزم',
        description: '7 أيام متتالية',
        isUnlocked: user.streak >= 7,
      ),
      _Achievement(
        icon: '👑',
        title: 'أسطورة',
        description: '30 يوم متتالي',
        isUnlocked: user.streak >= 30,
      ),
    ];
  }
}

class _Achievement {
  final String icon;
  final String title;
  final String description;
  final bool isUnlocked;

  const _Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 70,
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achievement.isUnlocked
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 24,
                color: achievement.isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: achievement.isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
