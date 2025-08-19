import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../providers/lesson_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_result_model.dart';
import '../../models/enhanced_quiz_result.dart';
import '../../services/firebase_service.dart';
import '../../services/reward_service.dart';
import '../../services/quiz_engine.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/quiz/multiple_choice_widget.dart';
import '../../widgets/quiz/reorder_code_widget.dart';
import '../../widgets/quiz/find_bug_widget.dart';
import '../../widgets/quiz/fill_blank_widget.dart';
import '../../widgets/quiz/true_false_widget.dart';
import '../../widgets/quiz/code_output_widget.dart';
import '../../widgets/quiz/complete_code_widget.dart';
import '../../widgets/floating_hint_button.dart';
import '../../widgets/quiz_feedback_popup.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;

  const QuizScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  List<dynamic> _selectedAnswers = [];
  List<QuestionResult> _questionResults = [];
  List<bool> _answeredQuestions = [];
  Timer? _timer;
  QuizTimer? _quizTimer;
  int _timeRemaining = 300; // 5 minutes
  bool _isCompleted = false;
  EnhancedQuizResult? _result;
  Map<int, HintManager> _hintManagers = {};
  Map<int, DateTime> _questionStartTimes = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadLesson();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quizTimer?.stop();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    
    print('🔍 بدء تحميل الدرس: ${widget.lessonId}');
    
    try {
      await lessonProvider.loadLesson(widget.lessonId);
      final lesson = lessonProvider.currentLesson;
      
      if (lesson != null && lesson.quiz.isNotEmpty) {
        setState(() {
          _selectedAnswers = List.filled(lesson.quiz.length, null);
          _answeredQuestions = List.filled(lesson.quiz.length, false);
          _questionResults = [];
          
          // تهيئة مدراء التلميحات
          for (int i = 0; i < lesson.quiz.length; i++) {
            _hintManagers[i] = HintManager(
              hints: lesson.quiz[i].hints ?? [],
              maxHints: 3,
            );
          }
          
          _questionStartTimes[0] = DateTime.now();
        });
        
        print('✅ تم تحميل الدرس بنجاح: ${lesson.title}');
        print('📝 عدد الأسئلة: ${lesson.quiz.length}');
      } else {
        print('❌ لا توجد أسئلة في هذا الدرس');
        _showErrorAndGoBack('لا توجد أسئلة في هذا الدرس');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      _showErrorAndGoBack('خطأ في تحميل الدرس');
    }
  }

  void _showErrorAndGoBack(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0 && !_isCompleted) {
        setState(() {
          _timeRemaining--;
        });
      } else if (_timeRemaining == 0) {
        _completeQuiz();
      }
    });
  }

  LessonModel? _getCurrentLesson() {
    return Provider.of<LessonProvider>(context, listen: false).currentLesson;
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentQuestionIndex = index;
      if (!_questionStartTimes.containsKey(index)) {
        _questionStartTimes[index] = DateTime.now();
      }
    });
  }

  void _onAnswerSelected(dynamic answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
      _answeredQuestions[_currentQuestionIndex] = true;
    });
  }

  void _nextQuestion() {
    final lesson = _getCurrentLesson();
    if (lesson != null && _currentQuestionIndex < lesson.quiz.length - 1) {
      _saveCurrentQuestionResult();
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0 && !_hasAnsweredPreviousQuestions()) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveCurrentQuestionResult() {
    final lesson = _getCurrentLesson();
    if (lesson == null || _currentQuestionIndex >= lesson.quiz.length) return;
    
    final question = lesson.quiz[_currentQuestionIndex];
    final userAnswer = _selectedAnswers[_currentQuestionIndex];
    
    if (userAnswer != null) {
      final startTime = _questionStartTimes[_currentQuestionIndex] ?? DateTime.now();
      final timeSpent = DateTime.now().difference(startTime);
      
      final isCorrect = QuizEngine.evaluateQuestion(question, userAnswer);
      final hintsUsed = _hintManagers[_currentQuestionIndex]?.usedHintsCount ?? 0;
      
      final result = QuestionResult(
        questionId: question.id,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        timeSpent: timeSpent,
        hintsUsed: hintsUsed,
        difficulty: question.difficulty,
      );
      
      // إزالة النتيجة السابقة إن وجدت وإضافة الجديدة
      _questionResults.removeWhere((r) => r.questionId == question.id);
      _questionResults.add(result);
    }
  }

  bool _hasAnsweredPreviousQuestions() {
    for (int i = 0; i < _currentQuestionIndex; i++) {
      if (!_answeredQuestions[i]) {
        return false;
      }
    }
    return true;
  }

  void _completeQuiz() async {
    if (_isCompleted) return;
    
    _saveCurrentQuestionResult();
    
    final lesson = _getCurrentLesson();
    if (lesson == null) return;
    
    setState(() {
      _isCompleted = true;
    });
    
    _timer?.cancel();
    _quizTimer?.stop();
    
    try {
      final result = await QuizEngine.evaluateQuiz(
        lesson.quiz,
        _selectedAnswers,
        _questionResults,
      );
      
      setState(() {
        _result = result;
      });
      
      // حفظ النتيجة
      await _saveQuizResult(result);
      
    } catch (e) {
      print('خطأ في تقييم الكويز: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ النتيجة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveQuizResult(EnhancedQuizResult result) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (authProvider.isGuestUser) return;
    
    try {
      final firebaseService = FirebaseService();
      
      // حفظ نتيجة الكويز
      await firebaseService.saveQuizResult(
        userId: authProvider.user!.uid,
        lessonId: widget.lessonId,
        result: QuizResultModel(
          lessonId: widget.lessonId,
          score: result.score,
          totalQuestions: result.totalQuestions,
          correctAnswers: result.correctAnswers,
          timeSpent: result.totalTimeSpent,
          completedAt: DateTime.now(),
          xpEarned: result.xpEarned,
          gemsEarned: result.gemsEarned,
          isPassing: result.isPassing,
        ),
      );
      
      // إضافة النقاط والجواهر
      if (result.isPassing) {
        await firebaseService.addXPAndGems(
          userId: authProvider.user!.uid,
          xp: result.xpEarned,
          gems: result.gemsEarned,
        );
        
        // تحديث بيانات المستخدم
        await userProvider.refreshUserData();
      }
      
    } catch (e) {
      print('خطأ في حفظ نتيجة الكويز: $e');
      rethrow;
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers = List.filled(_getCurrentLesson()!.quiz.length, null);
      _answeredQuestions = List.filled(_getCurrentLesson()!.quiz.length, false);
      _questionResults.clear();
      _timeRemaining = 300;
      _isCompleted = false;
      _result = null;
      
      // إعادة تهيئة مدراء التلميحات
      final lesson = _getCurrentLesson()!;
      for (int i = 0; i < lesson.quiz.length; i++) {
        _hintManagers[i] = HintManager(
          hints: lesson.quiz[i].hints ?? [],
          maxHints: 3,
        );
      }
      
      _questionStartTimes.clear();
      _questionStartTimes[0] = DateTime.now();
    });
    
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _startTimer();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProvider>(
      builder: (context, lessonProvider, child) {
        final lesson = lessonProvider.currentLesson;
        
        if (lesson == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (lesson.quiz.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('كويز'),
            ),
            body: const Center(
              child: Text(
                'لا توجد أسئلة في هذا الدرس',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }
        
        if (_isCompleted && _result != null) {
          return _buildResultScreen();
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text('كويز: ${lesson.title}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _timeRemaining <= 60 ? Colors.red : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: _timeRemaining <= 60 ? Colors.white : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_timeRemaining),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _timeRemaining <= 60 ? Colors.white : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // شريط التقدم
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
                              '${((_currentQuestionIndex + 1) / lesson.quiz.length * 100).round()}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_currentQuestionIndex + 1) / lesson.quiz.length,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // الأسئلة
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: lesson.quiz.length,
                      itemBuilder: (context, index) {
                        final question = lesson.quiz[index];
                        return _buildQuestionWidget(question, index);
                      },
                    ),
                  ),
                  
                  // أزرار التنقل
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentQuestionIndex > 0)
                          CustomButton(
                            text: 'السابق',
                            onPressed: _previousQuestion,
                            variant: ButtonVariant.secondary,
                            icon: Icons.arrow_back,
                          )
                        else
                          const SizedBox(width: 100),
                        
                        if (_currentQuestionIndex < lesson.quiz.length - 1)
                          CustomButton(
                            text: 'التالي',
                            onPressed: _answeredQuestions[_currentQuestionIndex] 
                                ? _nextQuestion 
                                : null,
                            icon: Icons.arrow_forward,
                          )
                        else
                          CustomButton(
                            text: 'إنهاء الكويز',
                            onPressed: _answeredQuestions[_currentQuestionIndex] 
                                ? _completeQuiz 
                                : null,
                            icon: Icons.check,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // زر التلميح العائم
              FloatingHintButton(
                isEnabled: _hintManagers[_currentQuestionIndex]?.hasAvailableHints ?? false,
                onHintRequested: () {
                  final hintManager = _hintManagers[_currentQuestionIndex];
                  if (hintManager != null) {
                    final hint = hintManager.getNextHint();
                    if (hint != null) {
                      _showHint(hint);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionWidget(QuizQuestionModel question, int index) {
    final selectedAnswer = _selectedAnswers[index];
    
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question,
          selectedAnswer: selectedAnswer as int?,
          onAnswerSelected: _onAnswerSelected,
        );
      
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          question: question,
          selectedAnswer: selectedAnswer as bool?,
          onAnswerSelected: _onAnswerSelected,
        );
      
      case QuestionType.fillInBlank:
        return FillBlankWidget(
          question: question,
          selectedAnswers: selectedAnswer as List<String>?,
          onAnswersSelected: _onAnswerSelected,
        );
      
      case QuestionType.reorderCode:
        return ReorderCodeWidget(
          question: question,
          selectedOrder: selectedAnswer as List<int>?,
          onOrderSelected: _onAnswerSelected,
        );
      
      case QuestionType.findBug:
        return FindBugWidget(
          question: question,
          selectedAnswer: selectedAnswer as String?,
          onAnswerSelected: _onAnswerSelected,
        );
      
      case QuestionType.codeOutput:
        return CodeOutputWidget(
          question: question,
          selectedAnswer: selectedAnswer as String?,
          onAnswerSelected: _onAnswerSelected,
        );
      
      case QuestionType.completeCode:
        return CompleteCodeWidget(
          question: question,
          selectedAnswer: selectedAnswer as String?,
          onAnswerSelected: _onAnswerSelected,
        );
      
      default:
        return const Center(
          child: Text('نوع سؤال غير مدعوم'),
        );
    }
  }

  void _showHint(String hint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('تلميح'),
          ],
        ),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final result = _result!;
    final lesson = _getCurrentLesson()!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة الكويز'),
        backgroundColor: result.isPassing ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // بطاقة النتيجة الرئيسية
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      result.isPassing ? Icons.celebration : Icons.sentiment_dissatisfied,
                      size: 64,
                      color: result.isPassing ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.isPassing ? 'مبروك! لقد نجحت' : 'للأسف، لم تنجح',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: result.isPassing ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.score}%',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: result.isPassing ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // إحصائيات مفصلة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإحصائيات',
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
                          icon: Icons.timer,
                          label: 'الوقت المستغرق',
                          value: _formatDuration(result.totalTimeSpent),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (result.isPassing) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'المكافآت المكتسبة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRewardItem(
                            icon: Icons.star,
                            label: 'نقاط الخبرة',
                            value: '+${result.xpEarned}',
                            color: Colors.amber,
                          ),
                          _buildRewardItem(
                            icon: Icons.diamond,
                            label: 'الجواهر',
                            value: '+${result.gemsEarned}',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'إعادة المحاولة',
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex = 0;
                        _selectedAnswers = List.filled(lesson.quiz.length, null);
                        _answeredQuestions = List.filled(lesson.quiz.length, false);
                        _questionResults.clear();
                        _timeRemaining = 300;
                        _isCompleted = false;
                        _result = null;
                        
                        // إعادة تشغيل المؤقت
                        _quizTimer = QuizTimer(totalTime: const Duration(minutes: 5));
                        _quizTimer!.start();
                        _questionStartTimes[0] = DateTime.now();
                      });
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _startTimer();
                    },
                    icon: Icons.refresh,
                  ),
                ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: CustomButton(
                  text: 'العودة للدروس',
                  onPressed: () => context.pop(),
                  variant: ButtonVariant.secondary,
                  icon: Icons.home,
                ),
              ),
            ],
          ],
        ),
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

  Widget _buildRewardItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
