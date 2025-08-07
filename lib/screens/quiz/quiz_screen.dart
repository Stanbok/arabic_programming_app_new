import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../providers/lesson_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_result_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/custom_button.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;

  const QuizScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  List<int> _selectedAnswers = [];
  Timer? _timer;
  int _timeRemaining = 300; // 5 minutes
  bool _isCompleted = false;
  QuizResultModel? _result;

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await lessonProvider.loadLesson(widget.lessonId, authProvider.user!.uid);
      
      // Initialize selected answers
      final lesson = lessonProvider.currentLesson;
      if (lesson != null) {
        setState(() {
          _selectedAnswers = List.filled(lesson.quiz.length, -1);
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    final lesson = _getCurrentLesson();
    if (lesson != null && _currentQuestionIndex < lesson.quiz.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    
    final lesson = _getCurrentLesson();
    if (lesson == null) return;

    // Calculate results
    int correctAnswers = 0;
    for (int i = 0; i < lesson.quiz.length; i++) {
      if (_selectedAnswers[i] == lesson.quiz[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final score = ((correctAnswers / lesson.quiz.length) * 100).round();
    
    _result = QuizResultModel(
      lessonId: widget.lessonId,
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: lesson.quiz.length,
      answers: _selectedAnswers,
      completedAt: DateTime.now(),
    );

    // Save result to Firebase
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await lessonProvider.saveQuizResult(
        authProvider.user!.uid,
        widget.lessonId,
        _result!,
      );
      
      // Check and update level
      await FirebaseService.checkAndUpdateLevel(authProvider.user!.uid);
    }

    setState(() {
      _isCompleted = true;
    });
  }

  LessonModel? _getCurrentLesson() {
    return Provider.of<LessonProvider>(context, listen: false).currentLesson;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاختبار'),
        actions: [
          if (!_isCompleted)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeRemaining < 60 
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _timeRemaining < 60 ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: TextStyle(
                      color: _timeRemaining < 60 ? Colors.red : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Consumer<LessonProvider>(
        builder: (context, lessonProvider, child) {
          if (lessonProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final lesson = lessonProvider.currentLesson;
          if (lesson == null || lesson.quiz.isEmpty) {
            return const Center(
              child: Text('لا يوجد اختبار لهذا الدرس'),
            );
          }

          if (_isCompleted && _result != null) {
            return _buildResultScreen(lesson, _result!);
          }

          return Column(
            children: [
              // Progress Bar
              _buildProgressBar(lesson),
              
              // Questions
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestionIndex = index;
                    });
                  },
                  itemCount: lesson.quiz.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionContent(lesson.quiz[index], index);
                  },
                ),
              ),
              
              // Navigation Controls
              _buildNavigationControls(lesson),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(LessonModel lesson) {
    final progress = (_currentQuestionIndex + 1) / lesson.quiz.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${_currentQuestionIndex + 1} من ${lesson.quiz.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(QuizQuestionModel question, int questionIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Options
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isSelected = _selectedAnswers[questionIndex] == optionIndex;
            
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectAnswer(optionIndex),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Text(
                            optionText,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(LessonModel lesson) {
    final isLastQuestion = _currentQuestionIndex == lesson.quiz.length - 1;
    final hasAnswered = _selectedAnswers[_currentQuestionIndex] != -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentQuestionIndex > 0)
            Expanded(
              child: CustomButton(
                text: 'السابق',
                onPressed: _previousQuestion,
                isOutlined: true,
                icon: Icons.arrow_back_ios,
              ),
            ),
          
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          
          // Next/Submit Button
          Expanded(
            flex: 2,
            child: CustomButton(
              text: isLastQuestion ? 'إنهاء الاختبار' : 'التالي',
              onPressed: hasAnswered
                  ? (isLastQuestion ? _submitQuiz : _nextQuestion)
                  : null,
              icon: isLastQuestion ? Icons.check : Icons.arrow_forward_ios,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(LessonModel lesson, QuizResultModel result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Result Icon and Score
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: result.isPassed ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (result.isPassed ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.score}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  result.grade,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            result.isPassed ? 'تهانينا! 🎉' : 'حاول مرة أخرى 💪',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: result.isPassed ? Colors.green : Colors.red,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            result.isPassed
                ? 'لقد نجحت في الاختبار بتفوق!'
                : 'لم تحصل على الدرجة المطلوبة للنجاح (70%)',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Stars Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Icon(
                index < result.stars ? Icons.star : Icons.star_border,
                size: 32,
                color: Colors.amber,
              );
            }),
          ),
          
          const SizedBox(height: 32),
          
          // Results Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'ملخص النتائج',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultItem(
                      icon: Icons.check_circle,
                      label: 'إجابات صحيحة',
                      value: '${result.correctAnswers}',
                      color: Colors.green,
                    ),
                    _buildResultItem(
                      icon: Icons.cancel,
                      label: 'إجابات خاطئة',
                      value: '${result.totalQuestions - result.correctAnswers}',
                      color: Colors.red,
                    ),
                    _buildResultItem(
                      icon: Icons.star,
                      label: 'النقاط المكتسبة',
                      value: result.isPassed ? '100 XP' : '0 XP',
                      color: Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Rewards (if passed)
          if (result.isPassed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 32,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'المكافآت المكتسبة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '100 نقطة خبرة + 5 جواهر',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Column(
            children: [
              if (result.isPassed)
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'الدرس التالي',
                    onPressed: () => context.go('/home'),
                    icon: Icons.arrow_forward,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'إعادة المحاولة',
                    onPressed: () {
                      setState(() {
                        _isCompleted = false;
                        _result = null;
                        _currentQuestionIndex = 0;
                        _selectedAnswers = List.filled(lesson.quiz.length, -1);
                        _timeRemaining = 300;
                      });
                      _startTimer();
                    },
                    icon: Icons.refresh,
                  ),
                ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'العودة للرئيسية',
                  onPressed: () => context.go('/home'),
                  isOutlined: true,
                  icon: Icons.home,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
