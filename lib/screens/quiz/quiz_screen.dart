import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_result_model.dart';
import '../../services/reward_service.dart';
import '../../services/statistics_service.dart';
import '../../widgets/custom_button.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;

  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<int> _selectedAnswers = [];
  bool _isSubmitting = false;
  bool _showResults = false;
  QuizResultModel? _quizResult;
  int _scoringStartTime = 0;
  bool _hasStartedQuiz = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await lessonProvider.loadLesson(
      widget.lessonId, 
      authProvider.user?.uid ?? 'guest'
    );
    
    final lesson = lessonProvider.currentLesson;
    if (lesson != null) {
      setState(() {
        _selectedAnswers = List.filled(lesson.quiz.length, -1);
        _hasStartedQuiz = true;
      });
    }
  }

  void _selectAnswer(int answerIndex) {
    if (_showResults) return;
    
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final lesson = lessonProvider.currentLesson;
    
    if (lesson == null) return;
    
    if (_currentQuestionIndex < lesson.quiz.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  bool _canFinishQuiz() {
    return _selectedAnswers.every((answer) => answer != -1);
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting || !_canFinishQuiz()) return;

    setState(() {
      _isSubmitting = true;
      _scoringStartTime = DateTime.now().millisecondsSinceEpoch;
    });

    try {
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final lesson = lessonProvider.currentLesson;
      final userId = authProvider.user?.uid ?? 'guest';
      
      if (lesson == null) {
        throw Exception('الدرس غير متوفر');
      }

      // حساب النتيجة فوراً
      int correctAnswers = 0;
      for (int i = 0; i < lesson.quiz.length; i++) {
        if (_selectedAnswers[i] == lesson.quiz[i].correctAnswer) {
          correctAnswers++;
        }
      }

      final score = ((correctAnswers / lesson.quiz.length) * 100).round();
      final isPassed = score >= 70;
      final scoringTimeMs = DateTime.now().millisecondsSinceEpoch - _scoringStartTime;

      // حساب المكافآت
      final rewards = await RewardService.calculateQuizRewards(
        lesson: lesson,
        score: score,
        isPassed: isPassed,
        userId: userId,
      );

      final xpAwarded = rewards['xp'] ?? 0;
      final gemsAwarded = rewards['gems'] ?? 0;

      // إنشاء نتيجة الاختبار
      _quizResult = QuizResultModel(
        lessonId: lesson.id,
        userId: userId,
        score: score,
        correctAnswers: correctAnswers,
        totalQuestions: lesson.quiz.length,
        answers: _selectedAnswers,
        completedAt: DateTime.now(),
        isPassed: isPassed,
        xpEarned: xpAwarded,
        gemsEarned: gemsAwarded,
      );

      // تسجيل المحاولة في الإحصائيات
      await StatisticsService.recordAttempt(
        lessonId: lesson.id,
        userId: userId,
        score: score,
        correctAnswers: correctAnswers,
        totalQuestions: lesson.quiz.length,
        answers: _selectedAnswers,
        scoringTimeMs: scoringTimeMs,
        xpAwarded: xpAwarded,
        gemsAwarded: gemsAwarded,
      );

      // تحديث بيانات المستخدم إذا نجح
      if (isPassed && !authProvider.isGuestUser) {
        await userProvider.addXP(xpAwarded);
        await userProvider.addGems(gemsAwarded);
        
        // حفظ النتيجة وتسجيل الإكمال
        await lessonProvider.saveQuizResult(userId, lesson.id, _quizResult!);
      }

      // عرض النتائج
      setState(() {
        _showResults = true;
        _isSubmitting = false;
      });

      // طباعة تفاصيل الأداء
      print('⏱️ وقت حساب النتيجة: ${scoringTimeMs}ms');
      print('📊 النتيجة: $score% ($correctAnswers/${lesson.quiz.length})');
      print('🎯 حالة النجاح: ${isPassed ? 'نجح' : 'فشل'}');
      print('💎 المكافآت: ${xpAwarded} XP, ${gemsAwarded} جوهرة');

    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الاختبار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers = List.filled(_selectedAnswers.length, -1);
      _showResults = false;
      _quizResult = null;
      _isSubmitting = false;
    });
  }

  void _goToNextLesson() {
    // العثور على الدرس التالي وفتحه
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final currentLesson = lessonProvider.currentLesson;
    
    if (currentLesson != null) {
      // البحث عن الدرس التالي
      final nextLesson = lessonProvider.lessons
          .where((l) => l.unit == currentLesson.unit && l.order == currentLesson.order + 1)
          .firstOrNull;
      
      if (nextLesson != null) {
        context.pushReplacement('/lesson/${nextLesson.id}');
      } else {
        // إذا لم يوجد درس تالي، العودة للصفحة الرئيسية
        context.go('/');
      }
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProvider>(
      builder: (context, lessonProvider, child) {
        final lesson = lessonProvider.currentLesson;
        
        if (lessonProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الاختبار...'),
                ],
              ),
            ),
          );
        }

        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('خطأ')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('لم يتم العثور على الاختبار'),
                ],
              ),
            ),
          );
        }

        if (_showResults && _quizResult != null) {
          return _buildResultsScreen();
        }

        return _buildQuizScreen(lesson);
      },
    );
  }

  Widget _buildQuizScreen(LessonModel lesson) {
    final question = lesson.quiz[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / lesson.quiz.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار: ${lesson.title}'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'السؤال ${_currentQuestionIndex + 1} من ${lesson.quiz.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      question.question,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Answer Options
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedAnswers[_currentQuestionIndex] == index;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectAnswer(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Colors.white,
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
                                        : Colors.grey,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
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
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: CustomButton(
                      text: 'السابق',
                      onPressed: _previousQuestion,
                      backgroundColor: Colors.grey[200],
                      textColor: Colors.black87,
                    ),
                  ),
                
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                
                Expanded(
                  flex: 2,
                  child: _currentQuestionIndex < lesson.quiz.length - 1
                      ? CustomButton(
                          text: 'التالي',
                          onPressed: _selectedAnswers[_currentQuestionIndex] != -1 
                              ? _nextQuestion 
                              : null,
                        )
                      : CustomButton(
                          text: _isSubmitting ? 'جاري الإرسال...' : 'إنهاء الاختبار',
                          onPressed: _canFinishQuiz() && !_isSubmitting ? _submitQuiz : null,
                          isLoading: _isSubmitting,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final result = _quizResult!;
    final isPassed = result.isPassed;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتائج الاختبار'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Result Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPassed 
                      ? [Colors.green, Colors.green.withOpacity(0.8)]
                      : [Colors.red, Colors.red.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    isPassed ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPassed ? 'مبروك! لقد نجحت' : 'لم تنجح هذه المرة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.score}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${result.correctAnswers} من ${result.totalQuestions} إجابات صحيحة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rewards Section (if passed)
            if (isPassed && (result.xpEarned > 0 || result.gemsEarned > 0))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎉 المكافآت المكتسبة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (result.xpEarned > 0)
                          Column(
                            children: [
                              const Icon(Icons.star, color: Colors.blue, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                '${result.xpEarned} XP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        if (result.gemsEarned > 0)
                          Column(
                            children: [
                              const Icon(Icons.diamond, color: Colors.amber, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                '${result.gemsEarned} جوهرة',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                if (isPassed)
                  CustomButton(
                    text: 'الدرس التالي',
                    onPressed: _goToNextLesson,
                    icon: Icons.arrow_forward,
                  ),
                
                const SizedBox(height: 12),
                
                CustomButton(
                  text: isPassed ? 'إعادة المحاولة للمراجعة' : 'إعادة المحاولة',
                  onPressed: _retakeQuiz,
                  backgroundColor: Colors.grey[200],
                  textColor: Colors.black87,
                  icon: Icons.refresh,
                ),
                
                const SizedBox(height: 12),
                
                CustomButton(
                  text: 'العودة للصفحة الرئيسية',
                  onPressed: () => context.go('/'),
                  backgroundColor: Colors.white,
                  textColor: Theme.of(context).colorScheme.primary,
                  icon: Icons.home,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
