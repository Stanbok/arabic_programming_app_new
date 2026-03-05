import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ResultsScreen extends StatelessWidget {
  final List<bool> answers;
  final int totalQuestions;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const ResultsScreen({
    super.key,
    required this.answers,
    required this.totalQuestions,
    required this.onContinue,
    required this.onRetry,
  });

  int get correctCount => answers.where((a) => a).length;
  double get percentage => correctCount / totalQuestions;
  bool get passed => percentage >= 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Result icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: (passed ? AppColors.success : AppColors.error).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                    color: passed ? AppColors.success : AppColors.error,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Result title
              Text(
                passed ? 'أحسنت!' : 'حاول مرة أخرى',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: passed ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 12),
              
              // Result message
              Text(
                passed
                    ? 'لقد اجتزت الاختبار بنجاح!'
                    : 'تحتاج إلى 50% على الأقل للنجاح',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Score card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Percentage circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 8,
                            backgroundColor: AppColors.dividerLight,
                            valueColor: AlwaysStoppedAnimation(
                              passed ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toInt()}%',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          context,
                          Icons.check_circle_rounded,
                          AppColors.success,
                          '$correctCount',
                          'صحيحة',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.dividerLight,
                        ),
                        _buildStatItem(
                          context,
                          Icons.cancel_rounded,
                          AppColors.error,
                          '${totalQuestions - correctCount}',
                          'خاطئة',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.dividerLight,
                        ),
                        _buildStatItem(
                          context,
                          Icons.quiz_rounded,
                          AppColors.primary,
                          '$totalQuestions',
                          'الإجمالي',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action buttons
              if (passed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('متابعة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onContinue,
                    child: const Text('العودة للدرس'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
