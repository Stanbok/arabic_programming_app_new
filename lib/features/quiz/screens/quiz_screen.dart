import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/lesson_model.dart';
import '../widgets/question_card.dart';
import '../widgets/feedback_sheet.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final LessonModel lesson;

  const QuizScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestion = 0;
  int? _selectedAnswer;
  int _correctAnswers = 0;
  bool _hasAnswered = false;

  QuizQuestion get _question => widget.lesson.quiz[_currentQuestion];

  void _onAnswerSelected(int index) {
    if (_hasAnswered) return;
    setState(() => _selectedAnswer = index);
  }

  void _confirmAnswer() {
    if (_selectedAnswer == null) return;

    final isCorrect = _selectedAnswer == _question.correctIndex;
    if (isCorrect) _correctAnswers++;

    setState(() => _hasAnswered = true);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => FeedbackSheet(
        isCorrect: isCorrect,
        correctAnswer: _question.answers[_question.correctIndex],
        explanation: _question.explanation,
        onNext: _nextQuestion,
      ),
    );
  }

  void _nextQuestion() {
    Navigator.pop(context);

    if (_currentQuestion < widget.lesson.quiz.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            lesson: widget.lesson,
            correctAnswers: _correctAnswers,
            totalQuestions: widget.lesson.quiz.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('إنهاء الاختبار؟'),
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
                    child: const Text('إنهاء'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / widget.lesson.quiz.length,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: QuestionCard(
                question: _question,
                questionNumber: _currentQuestion + 1,
                totalQuestions: widget.lesson.quiz.length,
                selectedAnswer: _selectedAnswer,
                onAnswerSelected: _onAnswerSelected,
                hasAnswered: _hasAnswered,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAnswer != null && !_hasAnswered
                      ? _confirmAnswer
                      : null,
                  child: const Text('تأكيد الإجابة'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
