import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lesson_content_model.dart';
import '../widgets/single_choice_question.dart';
import '../widgets/true_false_question.dart';
import '../widgets/fill_blank_question.dart';
import '../widgets/code_output_question.dart';
import '../widgets/ordering_question.dart';
import '../widgets/code_choice_question.dart';
import '../widgets/find_bug_question.dart';
import '../widgets/matching_question.dart';
import 'results_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final List<QuizData> questions;
  final String lessonTitle;
  final VoidCallback onComplete;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.lessonTitle,
    required this.onComplete,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  final List<bool> _answers = [];
  bool _hasAnswered = false;
  bool _isCorrect = false;

  QuizData get _currentQuestion => widget.questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == widget.questions.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          
          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question number
                  Text(
                    'السؤال ${_currentIndex + 1} من ${widget.questions.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Question text
                  Text(
                    _currentQuestion.question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Question widget based on type
                  _buildQuestionWidget(),
                ],
              ),
            ),
          ),
          
          // Bottom action area
          if (_hasAnswered) _buildFeedbackBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentIndex + 1) / widget.questions.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.dividerLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget() {
    final question = _currentQuestion;
    
    switch (question.questionType) {
      case QuizType.singleChoice:
        return SingleChoiceQuestion(
          options: question.options ?? [],
          correctIndex: question.correctIndex ?? 0,
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
      
      case QuizType.trueFalse:
        return TrueFalseQuestion(
          correctAnswer: question.correctAnswer ?? false,
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
      
      case QuizType.fillBlank:
        return FillBlankQuestion(
          correctText: question.correctText ?? '',
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
      
      case QuizType.codeOutput:
        return CodeOutputQuestion(
          codeSnippet: question.codeSnippet ?? '',
          expectedOutput: question.expectedOutput ?? '',
          options: question.options ?? [],
          correctIndex: question.correctIndex ?? 0,
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
      
      case QuizType.ordering:
        return OrderingQuestion(
          items: question.options ?? [],
          correctOrder: question.correctOrder ?? [],
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
      
      case QuizType.codeChoice:
        return CodeChoiceQuestion(
          options: question.options ?? [],
          correctIndex: question.correctIndex ?? 0,
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
      
      case QuizType.findBug:
        return FindBugQuestion(
          buggyCode: question.buggyCode ?? '',
          options: question.options ?? [],
          correctIndex: question.correctIndex ?? 0,
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
      
      case QuizType.matching:
        return MatchingQuestion(
          pairs: question.matchingPairs ?? {},
          enabled: !_hasAnswered,
          onAnswer: _handleAnswer,
        );
    }
  }

  void _handleAnswer(bool isCorrect) {
    setState(() {
      _hasAnswered = true;
      _isCorrect = isCorrect;
      _answers.add(isCorrect);
    });
    
    // Show feedback bottom sheet
    _showFeedbackSheet();
  }

  void _showFeedbackSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isCorrect
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: _isCorrect ? AppColors.success : AppColors.error,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isCorrect ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isCorrect ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isCorrect ? 'إجابة صحيحة!' : 'إجابة خاطئة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentQuestion.explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _nextQuestion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCorrect ? AppColors.success : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isLastQuestion ? 'عرض النتائج' : 'السؤال التالي'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: _isCorrect ? AppColors.success : AppColors.error,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isCorrect ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            _isCorrect ? 'صحيح!' : 'خطأ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isCorrect ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      _showResults();
    } else {
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _isCorrect = false;
      });
    }
  }

  void _showResults() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          answers: _answers,
          totalQuestions: widget.questions.length,
          onContinue: () {
            Navigator.of(context).pop();
            widget.onComplete();
          },
          onRetry: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  questions: widget.questions,
                  lessonTitle: widget.lessonTitle,
                  onComplete: widget.onComplete,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الخروج من الاختبار؟'),
        content: const Text('سيتم فقدان تقدمك في هذا الاختبار'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متابعة'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}
