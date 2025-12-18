import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/quiz_result_model.dart';

class QuestionReviewCard extends StatelessWidget {
  final int index;
  final QuestionResult result;

  const QuestionReviewCard({
    super.key,
    required this.index,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = result.isSkipped
        ? AppColors.textSecondary
        : result.isCorrect
            ? AppColors.success
            : AppColors.error;

    final IconData statusIcon = result.isSkipped
        ? Icons.remove_circle_outline
        : result.isCorrect
            ? Icons.check_circle
            : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with question number and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${AppStrings.question} $index',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(statusIcon, color: statusColor, size: 24),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Question text
          Text(
            result.questionText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User answer
          if (!result.isSkipped) ...[
            _buildAnswerRow(
              label: AppStrings.yourAnswer,
              answer: result.userAnswer,
              isCorrect: result.isCorrect,
            ),
            const SizedBox(height: 8),
          ],
          
          // Correct answer (show if wrong or skipped)
          if (!result.isCorrect)
            _buildAnswerRow(
              label: AppStrings.correctAnswer,
              answer: result.correctAnswer,
              isCorrect: true,
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow({
    required String label,
    required String answer,
    required bool isCorrect,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              answer,
              style: TextStyle(
                color: isCorrect ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
