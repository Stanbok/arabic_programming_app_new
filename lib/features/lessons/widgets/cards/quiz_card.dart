import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/card_model.dart';
import '../../../../providers/lesson_viewer_provider.dart';
import '../quiz/quiz_question_widget.dart';
import '../quiz/feedback_bottom_sheet.dart';

class QuizCard extends ConsumerStatefulWidget {
  final LessonCard card;
  final VoidCallback onComplete;

  const QuizCard({
    super.key,
    required this.card,
    required this.onComplete,
  });

  @override
  ConsumerState<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends ConsumerState<QuizCard> {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _isAnswered = false;

  List<QuizQuestion> get questions => widget.card.questions ?? [];

  void _onAnswerSubmitted(bool isCorrect) {
    setState(() {
      _isAnswered = true;
      if (isCorrect) _correctAnswers++;
    });

    _showFeedback(isCorrect);
  }

  void _showFeedback(bool isCorrect) {
    final currentQuestion = questions[_currentQuestionIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => FeedbackBottomSheet(
        isCorrect: isCorrect,
        explanation: currentQuestion.explanation,
        onContinue: () {
          Navigator.pop(context);
          _goToNextQuestion();
        },
      ),
    );
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
      });
    } else {
      // Quiz completed
      ref.read(quizResultProvider.notifier).state = QuizResult(
        correct: _correctAnswers,
        total: questions.length,
      );
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد أسئلة',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختبر معلوماتك',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'السؤال ${_currentQuestionIndex + 1} من ${questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / questions.length,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),
            // Question
            QuizQuestionWidget(
              question: currentQuestion,
              onAnswerSubmitted: _onAnswerSubmitted,
              isAnswered: _isAnswered,
            ),
          ],
        ),
      ),
    );
  }
}
