import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/models/quiz.dart';
import '../../../core/providers/content_providers.dart';
import '../../../core/providers/scores_provider.dart';
import '../../home/state/gamification_provider.dart';
import '../../home/state/progress_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const QuizScreen({super.key, required this.lessonId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool _lastCorrect = false;
  String _explanation = '';
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizForLessonProvider(widget.lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: quizAsync.when(
        data: (quiz) {
          if (quiz == null || quiz.questions.isEmpty) {
            return const Center(child: Text('No quiz available'));
          }
          final question = quiz.questions[_currentIndex];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(question.when(
                    multipleChoice: (prompt, options, answer, explanation) => prompt,
                    fillBlank: (prompt, answer, explanation) => prompt,
                    codeCompletion: (prompt, answer, explanation) => prompt,
                    trueFalse: (prompt, answer, explanation) => prompt)),
                const SizedBox(height: 12),
                // Multiple Choice
                if (question is MultipleChoiceQuestion) ...[
                  for (var option in question.options)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ElevatedButton(
                        onPressed: _answered
                            ? null
                            : () {
                                final correct = option == question.answer;
                                _processAnswer(correct, question.explanation ?? '');
                              },
                        child: Text(option),
                      ),
                    ),
                ],

                // Fill in the blank
                if (question is FillBlankQuestion) ...[
                  TextField(
                    controller: _answerController,
                    decoration: const InputDecoration(labelText: 'Your answer'),
                    enabled: !_answered,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _answered
                        ? null
                        : () {
                            final input = _answerController.text.trim();
                            final correct = input == question.answer;
                            _processAnswer(correct, question.explanation ?? '');
                          },
                    child: const Text('Submit'),
                  ),
                ],

                // Code completion (simple text compare)
                if (question is CodeCompletionQuestion) ...[
                  TextField(
                    controller: _answerController,
                    decoration: const InputDecoration(labelText: 'Complete the code'),
                    enabled: !_answered,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _answered
                        ? null
                        : () {
                            final input = _answerController.text.trim();
                            final correct = input == question.answer;
                            _processAnswer(correct, question.explanation ?? '');
                          },
                    child: const Text('Submit'),
                  ),
                ],

                // True/False
                if (question is TrueFalseQuestion) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _answered ? null : () => _processAnswer(true == question.answer, question.explanation ?? ''),
                          child: const Text('True'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _answered ? null : () => _processAnswer(false == question.answer, question.explanation ?? ''),
                          child: const Text('False'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                if (_answered) ...[
                  Text(_lastCorrect ? 'Correct!' : 'Incorrect', style: TextStyle(color: _lastCorrect ? Colors.green : Colors.red)),
                  const SizedBox(height: 8),
                  if (_explanation.isNotEmpty) MarkdownBody(data: _explanation),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _nextQuestion(quiz),
                    child: const Text('Next'),
                  ),
                ]
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading quiz')),
      ),
    );
  }

  void _handleAnswer(bool correct) {
    // legacy handler (unused)
  }

  void _processAnswer(bool correct, String explanation) {
    setState(() {
      _answered = true;
      _lastCorrect = correct;
      _explanation = explanation;
      if (correct) _score++;
    });
  }

  void _nextQuestion(Quiz quiz) async {
    final total = quiz.questions.length;
    final nextIndex = _currentIndex + 1;
    if (nextIndex >= total) {
      // quiz finished
      final percent = (total == 0) ? 0 : ((_score / total) * 100).round();
      // persist score
      ref.read(scoresProvider.notifier).setScore(widget.lessonId, percent);

      const passingThreshold = 70; // configurable later per-quiz
      final passed = percent >= passingThreshold;
      if (passed) {
        // mark lesson complete, award XP & streak
        ref.read(progressProvider.notifier).markLessonComplete(widget.lessonId);
        ref.read(gamificationProvider.notifier).addXp(20 + (percent ~/ 5));
        ref.read(gamificationProvider.notifier).incrementStreak();
      }

      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => QuizResultScreen(success: passed, xp: passed ? (20 + (percent ~/ 5)) : 0)));
    } else {
      setState(() {
        _currentIndex = nextIndex;
        _answered = false;
        _lastCorrect = false;
        _explanation = '';
        _answerController.clear();
      });
    }
  }
}

class QuizResultScreen extends StatefulWidget {
  final bool success;
  final int xp;

  const QuizResultScreen({super.key, required this.success, required this.xp});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.success) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz result')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.success ? Icons.check_circle : Icons.error,
                    color: widget.success ? Colors.green : Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(widget.success ? 'You passed!' : 'Try again', style: const TextStyle(fontSize: 24)),
                if (widget.success) Text('XP +${widget.xp}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                )
              ],
            ),
          ),
          if (widget.success)
            ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
        ],
      ),
    );
  }
}
