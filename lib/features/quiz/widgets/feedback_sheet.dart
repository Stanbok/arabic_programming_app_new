import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FeedbackSheet extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final VoidCallback onNext;

  const FeedbackSheet({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            size: 56,
            color: isCorrect ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect ? 'إجابة صحيحة!' : 'إجابة خاطئة',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isCorrect ? AppColors.success : AppColors.error,
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            Text(
              'الإجابة الصحيحة: $correctAnswer',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? AppColors.success : AppColors.error,
              ),
              child: const Text('التالي'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
