import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class QuizStartCard extends StatelessWidget {
  final int questionCount;
  final VoidCallback onStart;

  const QuizStartCard({
    super.key,
    required this.questionCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedMinutes = (questionCount * 0.5).ceil();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz,
              size: 48,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'حان وقت الاختبار!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'اختبر معلوماتك فيما تعلمته',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoItem(
                  icon: Icons.help_outline,
                  value: '$questionCount',
                  label: 'سؤال',
                ),
                Container(
                  height: 40,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: AppColors.border,
                ),
                _InfoItem(
                  icon: Icons.timer_outlined,
                  value: '$estimatedMinutes',
                  label: 'دقيقة',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'ابدأ الاختبار',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
