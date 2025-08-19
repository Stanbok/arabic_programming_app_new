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
  final PageController _pageController = PageController();
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
      String userId = authProvider.user?.uid ?? 'guest';
      await lessonProvider.loadLesson(widget.lessonId, userId);
      
      final lesson = lessonProvider.currentLesson;
      print('📚 تم تحميل الدرس: ${lesson?.title}');
      print('❓ عدد أسئلة الاختبار: ${lesson?.quiz.length ?? 0}');
      
      if (lesson != null && lesson.quiz.isNotEmpty) {
        setState(() {
          _selectedAnswers = List.filled(lesson.quiz.length, null);
          _answeredQuestions = List.filled(lesson.quiz.length, false);
          _questionResults = [];
          
          // تهيئة مدراء التلميحات
          for (int i = 0; i < lesson.quiz.length; i++) {
            final hints = QuizEngine.generateHints(lesson.quiz[i]);
            _hintManagers[i] = HintManager(hints);
          }
          
          // تهيئة QuizTimer
          _quizTimer = QuizTimer(totalTime: const Duration(minutes: 5));
          _quizTimer!.start();
          
          // تسجيل وقت بداية السؤال الأول
          _questionStartTimes[0] = DateTime.now();
        });
        print('✅ تم تهيئة الإجابات: ${_selectedAnswers.length} سؤال');
      } else {
        print('⚠️ لا توجد أسئلة اختبار في الدرس');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الاختبار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_quizTimer != null && !_quizTimer!.isExpired) {
        setState(() {
          _timeRemaining = _quizTimer!.remaining.inSeconds;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  void _selectAnswer(dynamic answer) {
    // منع التعديل إذا تم الإجابة مسبقاً
    if (_answeredQuestions[_currentQuestionIndex]) return;
    
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
    
    // عرض الفيدباك الفوري
    _showFeedbackPopup(answer);
  }

  void _showFeedbackPopup(dynamic userAnswer) {
    final lesson = _getCurrentLesson();
    if (lesson == null) return;
    
    final question = lesson.quiz[_currentQuestionIndex];
    final isCorrect = QuizEngine.isAnswerCorrect(question, userAnswer);
    
    // حفظ نتيجة السؤال
    _saveCurrentQuestionResult();
    
    // تمييز السؤال كمجاب عليه
    setState(() {
      _answeredQuestions[_currentQuestionIndex] = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizFeedbackPopup(
        question: question,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        onContinue: () {
          Navigator.of(context).pop();
          _handleContinueAfterFeedback();
        },
      ),
    );
  }

  void _handleContinueAfterFeedback() {
    final lesson = _getCurrentLesson();
    if (lesson == null) return;
    
    final isLastQuestion = _currentQuestionIndex == lesson.quiz.length - 1;
    
    if (isLastQuestion) {
      _submitQuiz();
    } else {
      _nextQuestion();
    }
  }

  void _showHint() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isGuestUser) {
      _showGuestHintDialog();
      return;
    }
    
    if (!userProvider.hasHints) {
      _showNoHintsDialog();
      return;
    }
    
    final success = await userProvider.useHint();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في استخدام التلميح'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final hintManager = _hintManagers[_currentQuestionIndex];
    if (hintManager != null && hintManager.hasMoreHints) {
      final hint = hintManager.getNextHint();
      if (hint != null) {
        _showHintDialog(hint);
      }
    }
  }

  void _showHintDialog(String hint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.withOpacity(0.1), Colors.orange.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text('تلميح مفيد'),
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Text(
            hint,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('فهمت، شكراً!'),
          ),
        ],
      ),
    );
  }

  void _showGuestHintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('تسجيل الدخول مطلوب'),
          ],
        ),
        content: const Text(
          'يجب تسجيل الدخول لاستخدام التلميحات والاستفادة من جميع ميزات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showNoHintsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.grey),
            SizedBox(width: 8),
            Text('لا توجد تلميحات متاحة'),
          ],
        ),
        content: const Text(
          'لقد استنفدت جميع التلميحات المتاحة. يمكنك شراء المزيد من التلميحات باستخدام الجواهر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
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
    final startTime = _questionStartTimes[_currentQuestionIndex] ?? DateTime.now();
    final timeSpent = DateTime.now().difference(startTime);
    final hintsUsed = _hintManagers[_currentQuestionIndex]?.hintsUsed ?? 0;
    
    final result = QuizEngine.evaluateQuestion(
      question,
      userAnswer,
      timeSpent: timeSpent,
      hintsUsed: hintsUsed,
    );
    
    final existingIndex = _questionResults.indexWhere((r) => r.questionId == question.id);
    if (existingIndex >= 0) {
      _questionResults[existingIndex] = result;
    } else {
      _questionResults.add(result);
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    _quizTimer?.stop();
    
    final lesson = _getCurrentLesson();
    if (lesson == null) return;

    // حفظ نتيجة السؤال الأخير
    _saveCurrentQuestionResult();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'guest';

    final totalTimeSpent = _quizTimer?.elapsed ?? const Duration(minutes: 5);
    final totalHintsUsed = _hintManagers.values.fold(0, (sum, manager) => sum + manager.hintsUsed);
    
    _result = QuizEngine.evaluateQuiz(
      widget.lessonId,
      userId,
      lesson.quiz,
      _questionResults,
      totalTimeSpent: totalTimeSpent,
      totalHintsUsed: totalHintsUsed,
    );

    print('📊 نتيجة الاختبار: ${_result!.percentage}% (${_result!.score}/${_result!.totalQuestions})');

    // حفظ النتيجة وإضافة المكافآت
    if (!authProvider.isGuestUser && authProvider.user != null) {
      try {
        await lessonProvider.saveEnhancedQuizResult(authProvider.user!.uid, widget.lessonId, _result!);
        
        if (QuizEngine.isPassing(_result!.percentage)) {
          final decayTracker = lessonProvider.getDecayTracker(widget.lessonId);
          final rewards = RewardService.calculateTotalRewards(
            lesson, 
            _result!.percentage,
            decayTracker: decayTracker,
          );
          
          final xpReward = rewards['xp']!;
          final gemsReward = rewards['gems']!;
          
          if (xpReward > 0 || gemsReward > 0) {
            await FirebaseService.addXPAndGems(
              authProvider.user!.uid, 
              xpReward, 
              gemsReward, 
              'إكمال درس: ${lesson.title} (${_result!.percentage.round()}%)'
            );
            
            print('✅ تم إضافة المكافآت: XP=$xpReward, Gems=$gemsReward');
          }
        }
      } catch (e) {
        print('❌ خطأ في حفظ النتيجة: $e');
      }
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الاختبار...'),
                ],
              ),
            );
          }

          final lesson = lessonProvider.currentLesson;
          
          if (lesson == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('لم يتم العثور على الدرس'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            );
          }
          
          if (lesson.quiz.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('لا يوجد اختبار لهذا الدرس'),
                  const SizedBox(height: 8),
                  Text('الدرس: ${lesson.title}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            );
          }

          if (_isCompleted && _result != null) {
            return _buildResultScreen(lesson, _result!);
          }

          return Column(
            children: [
              _buildProgressBar(lesson),
              
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestionIndex = index;
                      _questionStartTimes[index] = DateTime.now();
                    });
                  },
                  itemCount: lesson.quiz.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionContent(lesson.quiz[index], index);
                  },
                ),
              ),
              
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
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نوع السؤال: ${_getQuestionTypeLabel(question.type)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildQuestionWidget(question, questionIndex),
            ],
          ),
        ),
        
        FloatingHintButton(
          onHintRequested: _showHint,
          isEnabled: !_isCompleted,
        ),
      ],
    );
  }

  Widget _buildQuestionWidget(QuizQuestionModel question, int questionIndex) {
    final userAnswer = _selectedAnswers[questionIndex];
    
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question,
          selectedAnswer: userAnswer as int?,
          onAnswerSelected: _selectAnswer,
        );
        
      case QuestionType.reorderCode:
        return ReorderCodeWidget(
          question: question,
          userOrder: userAnswer as List<int>?,
          onOrderChanged: _selectAnswer,
        );
        
      case QuestionType.findBug:
        return FindBugWidget(
          question: question,
          userAnswer: userAnswer as String?,
          onAnswerChanged: _selectAnswer,
        );
        
      case QuestionType.fillInBlank:
        return FillBlankWidget(
          question: question,
          userAnswers: userAnswer as List<String>?,
          onAnswersChanged: _selectAnswer,
        );
        
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          question: question,
          selectedAnswer: userAnswer as bool?,
          onAnswerSelected: _selectAnswer,
        );
        
      case QuestionType.codeOutput:
        return CodeOutputWidget(
          question: question,
          userAnswer: userAnswer as String?,
          onAnswerChanged: _selectAnswer,
        );
        
      case QuestionType.completeCode:
        return CompleteCodeWidget(
          question: question,
          userAnswer: userAnswer as String?,
          onAnswerChanged: _selectAnswer,
        );
    }
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'اختيار من متعدد';
      case QuestionType.reorderCode:
        return 'ترتيب الكود';
      case QuestionType.findBug:
        return 'اكتشف الخطأ';
      case QuestionType.fillInBlank:
        return 'املأ الفراغ';
      case QuestionType.trueFalse:
        return 'صح أو خطأ';
      case QuestionType.codeOutput:
        return 'نتيجة الكود';
      case QuestionType.completeCode:
        return 'أكمل الكود';
    }
  }

  Widget _buildNavigationControls(LessonModel lesson) {
    final isLastQuestion = _currentQuestionIndex == lesson.quiz.length - 1;
    final hasAnswered = _selectedAnswers[_currentQuestionIndex] != null;
    final isAnswered = _answeredQuestions[_currentQuestionIndex];

    // إخفاء أزرار التنقل إذا تم الإجابة على السؤال
    if (isAnswered) {
      return const SizedBox.shrink();
    }

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
          if (_currentQuestionIndex > 0 && !_hasAnsweredPreviousQuestions())
            Expanded(
              child: CustomButton(
                text: 'السابق',
                onPressed: _previousQuestion,
                isOutlined: true,
                icon: Icons.arrow_back_ios,
              ),
            ),
          
          if (_currentQuestionIndex > 0 && !_hasAnsweredPreviousQuestions()) 
            const SizedBox(width: 12),
          
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'تأكيد الإجابة',
              onPressed: hasAnswered ? () => _selectAnswer(_selectedAnswers[_currentQuestionIndex]) : null,
              icon: Icons.check,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnsweredPreviousQuestions() {
    for (int i = 0; i < _currentQuestionIndex; i++) {
      if (_answeredQuestions[i]) return true;
    }
    return false;
  }

  Widget _buildResultScreen(LessonModel lesson, EnhancedQuizResult result) {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final decayTracker = lessonProvider.getDecayTracker(widget.lessonId);
    
    final rewards = QuizEngine.isPassing(result.percentage)
        ? RewardService.calculateTotalRewards(
            lesson, 
            result.percentage,
            decayTracker: decayTracker,
          )
        : {'xp': 0, 'gems': 0};
    
    final xpReward = rewards['xp']!;
    final gemsReward = rewards['gems']!;
    
    final isRetake = decayTracker != null && decayTracker.retakeCount > 0;
    final decayMultiplier = decayTracker?.getDecayMultiplier() ?? 1.0;
    final stars = QuizEngine.calculateStars(result.percentage);
    final grade = QuizEngine.getGrade(result.percentage);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Result Icon and Score
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: QuizEngine.isPassing(result.percentage) ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (QuizEngine.isPassing(result.percentage) ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.percentage.round()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  grade,
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
            QuizEngine.isPassing(result.percentage) ? 'تهانينا! 🎉' : 'حاول مرة أخرى 💪',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: QuizEngine.isPassing(result.percentage) ? Colors.green : Colors.red,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            QuizEngine.isPassing(result.percentage)
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
                index < stars ? Icons.star : Icons.star_border,
                size: 32,
                color: Colors.amber,
              );
            }),
          ),
          
          const SizedBox(height: 32),
          
          _buildDetailedStats(result),
          
          const SizedBox(height: 32),
          
          // Rewards (if passed)
          if (QuizEngine.isPassing(result.percentage))
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
                    '$xpReward نقطة خبرة + $gemsReward جوهرة',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (result.hintsUsed > 0)
                    Text(
                      'استخدمت ${result.hintsUsed} تلميح',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                    ),
                ],
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Decay Information (if retake)
          if (QuizEngine.isPassing(result.percentage) && isRetake)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(height: 8),
                  Text(
                    'إعادة اختبار',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  Text(
                    'المكافآت مقللة إلى ${(decayMultiplier * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[600],
                    ),
                  ),
                  if (gemsReward == 0)
                    Text(
                      'لا جواهر في الإعادات',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                    ),
                ],
              ),
            ),
          
          // Action Buttons
          Column(
            children: [
              if (QuizEngine.isPassing(result.percentage))
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
                        _selectedAnswers = List.filled(lesson.quiz.length, null);
                        _questionResults = [];
                        _currentQuestionIndex = 0;
                        _timeRemaining = 300;
                        
                        // إعادة تعيين مدراء التلميحات
                        for (final manager in _hintManagers.values) {
                          manager.reset();
                        }
                        
                        // إعادة تشغيل المؤقت
                        _quizTimer = QuizTimer(totalTime: const Duration(minutes: 5));
                        _quizTimer!.start();
                        _questionStartTimes[0] = DateTime.now();
                      });
                      _pageController = PageController();
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

  Widget _buildDetailedStats(EnhancedQuizResult result) {
    return Container(
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
                value: '${result.score}',
                color: Colors.green,
              ),
              _buildResultItem(
                icon: Icons.cancel,
                label: 'إجابات خاطئة',
                value: '${result.totalQuestions - result.score}',
                color: Colors.red,
              ),
              _buildResultItem(
                icon: Icons.access_time,
                label: 'الوقت المستغرق',
                value: '${result.timeSpent ~/ 60}:${(result.timeSpent % 60).toString().padLeft(2, '0')}',
                color: Colors.blue,
              ),
            ],
          ),
          
          if (result.hintsUsed > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResultItem(
                  icon: Icons.lightbulb,
                  label: 'تلميحات مستخدمة',
                  value: '${result.hintsUsed}',
                  color: Colors.amber,
                ),
              ],
            ),
          ],
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
  final PageController _pageController = PageController();
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
      String userId = authProvider.user?.uid ?? 'guest';
      await lessonProvider.loadLesson(widget.lessonId, userId);
      
      final lesson = lessonProvider.currentLesson;
      print('📚 تم تحميل الدرس: ${lesson?.title}');
      print('❓ عدد أسئلة الاختبار: ${lesson?.quiz.length ?? 0}');
      
      if (lesson != null && lesson.quiz.isNotEmpty) {
        setState(() {
          _selectedAnswers = List.filled(lesson.quiz.length, null);
          _answeredQuestions = List.filled(lesson.quiz.length, false);
          _questionResults = [];
          
          // تهيئة مدراء التلميحات
          for (int i = 0; i < lesson.quiz.length; i++) {
            final hints = QuizEngine.generateHints(lesson.quiz[i]);
            _hintManagers[i] = HintManager(hints);
          }
          
          // تهيئة QuizTimer
          _quizTimer = QuizTimer(totalTime: const Duration(minutes: 5));
          _quizTimer!.start();
          
          // تسجيل وقت بداية السؤال الأول
          _questionStartTimes[0] = DateTime.now();
        });
        print('✅ تم تهيئة الإجابات: ${_selectedAnswers.length} سؤال');
      } else {
        print('⚠️ لا توجد أسئلة اختبار في الدرس');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الاختبار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_quizTimer != null && !_quizTimer!.isExpired) {
        setState(() {
          _timeRemaining = _quizTimer!.remaining.inSeconds;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  void _selectAnswer(dynamic answer) {
    // منع التعديل إذا تم الإجابة مسبقاً
    if (_answeredQuestions[_currentQuestionIndex]) return;
    
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
    
    // عرض الفيدباك الفوري
    _showFeedbackPopup(answer);
  }

  void _showFeedbackPopup(dynamic userAnswer) {
    final lesson = _getCurrentLesson();
    if (lesson == null) return;
    
    final question = lesson.quiz[_currentQuestionIndex];
    final isCorrect = QuizEngine.isAnswerCorrect(question, userAnswer);
    
    // حفظ نتيجة السؤال
    _saveCurrentQuestionResult();
    
    // تمييز السؤال كمجاب عليه
    setState(() {
      _answeredQuestions[_currentQuestionIndex] = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizFeedbackPopup(
        question: question,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        onContinue: () {
          Navigator.of(context).pop();
          _handleContinueAfterFeedback();
        },
      ),
    );
  }

  void _handleContinueAfterFeedback() {
    final lesson = _getCurrentLesson();
    if (lesson == null) return;
    
    final isLastQuestion = _currentQuestionIndex == lesson.quiz.length - 1;
    
    if (isLastQuestion) {
      _submitQuiz();
    } else {
      _nextQuestion();
    }
  }

  void _showHint() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isGuestUser) {
      _showGuestHintDialog();
      return;
    }
    
    if (!userProvider.hasHints) {
      _showNoHintsDialog();
      return;
    }
    
    final success = await userProvider.useHint();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في استخدام التلميح'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final hintManager = _hintManagers[_currentQuestionIndex];
    if (hintManager != null && hintManager.hasMoreHints) {
      final hint = hintManager.getNextHint();
      if (hint != null) {
        _showHintDialog(hint);
      }
    }
  }

  void _showHintDialog(String hint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.withOpacity(0.1), Colors.orange.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text('تلميح مفيد'),
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Text(
            hint,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('فهمت، شكراً!'),
          ),
        ],
      ),
    );
  }

  void _showGuestHintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('تسجيل الدخول مطلوب'),
          ],
        ),
        content: const Text(
          'يجب تسجيل الدخول لاستخدام التلميحات والاستفادة من جميع ميزات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showNoHintsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.grey),
            SizedBox(width: 8),
            Text('لا توجد تلميحات متاحة'),
          ],
        ),
        content: const Text(
          'لقد استنفدت جميع التلميحات المتاحة. يمكنك شراء المزيد من التلميحات باستخدام الجواهر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
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
    final startTime = _questionStartTimes[_currentQuestionIndex] ?? DateTime.now();
    final timeSpent = DateTime.now().difference(startTime);
    final hintsUsed = _hintManagers[_currentQuestionIndex]?.hintsUsed ?? 0;
    
    final result = QuizEngine.evaluateQuestion(
      question,
      userAnswer,
      timeSpent: timeSpent,
      hintsUsed: hintsUsed,
    );
    
    final existingIndex = _questionResults.indexWhere((r) => r.questionId == question.id);
    if (existingIndex >= 0) {
      _questionResults[existingIndex] = result;
    } else {
      _questionResults.add(result);
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    _quizTimer?.stop();
    
    final lesson = _getCurrentLesson();
    if (lesson == null) return;

    // حفظ نتيجة السؤال الأخير
    _saveCurrentQuestionResult();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'guest';

    final totalTimeSpent = _quizTimer?.elapsed ?? const Duration(minutes: 5);
    final totalHintsUsed = _hintManagers.values.fold(0, (sum, manager) => sum + manager.hintsUsed);
    
    _result = QuizEngine.evaluateQuiz(
      widget.lessonId,
      userId,
      lesson.quiz,
      _questionResults,
      totalTimeSpent: totalTimeSpent,
      totalHintsUsed: totalHintsUsed,
    );

    print('📊 نتيجة الاختبار: ${_result!.percentage}% (${_result!.score}/${_result!.totalQuestions})');

    // حفظ النتيجة وإضافة المكافآت
    if (!authProvider.isGuestUser && authProvider.user != null) {
      try {
        await lessonProvider.saveEnhancedQuizResult(authProvider.user!.uid, widget.lessonId, _result!);
        
        if (QuizEngine.isPassing(_result!.percentage)) {
          final decayTracker = lessonProvider.getDecayTracker(widget.lessonId);
          final rewards = RewardService.calculateTotalRewards(
            lesson, 
            _result!.percentage,
            decayTracker: decayTracker,
          );
          
          final xpReward = rewards['xp']!;
          final gemsReward = rewards['gems']!;
          
          if (xpReward > 0 || gemsReward > 0) {
            await FirebaseService.addXPAndGems(
              authProvider.user!.uid, 
              xpReward, 
              gemsReward, 
              'إكمال درس: ${lesson.title} (${_result!.percentage.round()}%)'
            );
            
            print('✅ تم إضافة المكافآت: XP=$xpReward, Gems=$gemsReward');
          }
        }
      } catch (e) {
        print('❌ خطأ في حفظ النتيجة: $e');
      }
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الاختبار...'),
                ],
              ),
            );
          }

          final lesson = lessonProvider.currentLesson;
          
          if (lesson == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('لم يتم العثور على الدرس'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            );
          }
          
          if (lesson.quiz.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('لا يوجد اختبار لهذا الدرس'),
                  const SizedBox(height: 8),
                  Text('الدرس: ${lesson.title}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            );
          }

          if (_isCompleted && _result != null) {
            return _buildResultScreen(lesson, _result!);
          }

          return Column(
            children: [
              _buildProgressBar(lesson),
              
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestionIndex = index;
                      _questionStartTimes[index] = DateTime.now();
                    });
                  },
                  itemCount: lesson.quiz.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionContent(lesson.quiz[index], index);
                  },
                ),
              ),
              
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
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نوع السؤال: ${_getQuestionTypeLabel(question.type)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildQuestionWidget(question, questionIndex),
            ],
          ),
        ),
        
        FloatingHintButton(
          onHintRequested: _showHint,
          isEnabled: !_isCompleted,
        ),
      ],
    );
  }

  Widget _buildQuestionWidget(QuizQuestionModel question, int questionIndex) {
    final userAnswer = _selectedAnswers[questionIndex];
    
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question,
          selectedAnswer: userAnswer as int?,
          onAnswerSelected: _selectAnswer,
        );
        
      case QuestionType.reorderCode:
        return ReorderCodeWidget(
          question: question,
          userOrder: userAnswer as List<int>?,
          onOrderChanged: _selectAnswer,
        );
        
      case QuestionType.findBug:
        return FindBugWidget(
          question: question,
          userAnswer: userAnswer as String?,
          onAnswerChanged: _selectAnswer,
        );
        
      case QuestionType.fillInBlank:
        return FillBlankWidget(
          question: question,
          userAnswers: userAnswer as List<String>?,
          onAnswersChanged: _selectAnswer,
        );
        
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          question: question,
          selectedAnswer: userAnswer as bool?,
          onAnswerSelected: _selectAnswer,
        );
        
      case QuestionType.codeOutput:
        return CodeOutputWidget(
          question: question,
          userAnswer: userAnswer as String?,
          onAnswerChanged: _selectAnswer,
        );
        
      case QuestionType.completeCode:
        return CompleteCodeWidget(
          question: question,
          userAnswer: userAnswer as String?,
          onAnswerChanged: _selectAnswer,
        );
    }
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'اختيار من متعدد';
      case QuestionType.reorderCode:
        return 'ترتيب الكود';
      case QuestionType.findBug:
        return 'اكتشف الخطأ';
      case QuestionType.fillInBlank:
        return 'املأ الفراغ';
      case QuestionType.trueFalse:
        return 'صح أو خطأ';
      case QuestionType.codeOutput:
        return 'نتيجة الكود';
      case QuestionType.completeCode:
        return 'أكمل الكود';
    }
  }

  Widget _buildNavigationControls(LessonModel lesson) {
    final isLastQuestion = _currentQuestionIndex == lesson.quiz.length - 1;
    final hasAnswered = _selectedAnswers[_currentQuestionIndex] != null;
    final isAnswered = _answeredQuestions[_currentQuestionIndex];

    // إخفاء أزرار التنقل إذا تم الإجابة على السؤال
    if (isAnswered) {
      return const SizedBox.shrink();
    }

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
          if (_currentQuestionIndex > 0 && !_hasAnsweredPreviousQuestions())
            Expanded(
              child: CustomButton(
                text: 'السابق',
                onPressed: _previousQuestion,
                isOutlined: true,
                icon: Icons.arrow_back_ios,
              ),
            ),
          
          if (_currentQuestionIndex > 0 && !_hasAnsweredPreviousQuestions()) 
            const SizedBox(width: 12),
          
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'تأكيد الإجابة',
              onPressed: hasAnswered ? () => _selectAnswer(_selectedAnswers[_currentQuestionIndex]) : null,
              icon: Icons.check,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnsweredPreviousQuestions() {
    for (int i = 0; i < _currentQuestionIndex; i++) {
      if (_answeredQuestions[i]) return true;
    }
    return false;
  }

  Widget _buildResultScreen(LessonModel lesson, EnhancedQuizResult result) {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final decayTracker = lessonProvider.getDecayTracker(widget.lessonId);
    
    final rewards = QuizEngine.isPassing(result.percentage)
        ? RewardService.calculateTotalRewards(
            lesson, 
            result.percentage,
            decayTracker: decayTracker,
          )
        : {'xp': 0, 'gems': 0};
    
    final xpReward = rewards['xp']!;
    final gemsReward = rewards['gems']!;
    
    final isRetake = decayTracker != null && decayTracker.retakeCount > 0;
    final decayMultiplier = decayTracker?.getDecayMultiplier() ?? 1.0;
    final stars = QuizEngine.calculateStars(result.percentage);
    final grade = QuizEngine.getGrade(result.percentage);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Result Icon and Score
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: QuizEngine.isPassing(result.percentage) ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (QuizEngine.isPassing(result.percentage) ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.percentage.round()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  grade,
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
            QuizEngine.isPassing(result.percentage) ? 'تهانينا! 🎉' : 'حاول مرة أخرى 💪',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: QuizEngine.isPassing(result.percentage) ? Colors.green : Colors.red,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            QuizEngine.isPassing(result.percentage)
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
                index < stars ? Icons.star : Icons.star_border,
                size: 32,
                color: Colors.amber,
              );
            }),
          ),
          
          const SizedBox(height: 32),
          
          _buildDetailedStats(result),
          
          const SizedBox(height: 32),
          
          // Rewards (if passed)
          if (QuizEngine.isPassing(result.percentage))
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
                    '$xpReward نقطة خبرة + $gemsReward جوهرة',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (result.hintsUsed > 0)
                    Text(
                      'استخدمت ${result.hintsUsed} تلميح',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                    ),
                ],
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Decay Information (if retake)
          if (QuizEngine.isPassing(result.percentage) && isRetake)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(height: 8),
                  Text(
                    'إعادة اختبار',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  Text(
                    'المكافآت مقللة إلى ${(decayMultiplier * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[600],
                    ),
                  ),
                  if (gemsReward == 0)
                    Text(
                      'لا جواهر في الإعادات',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                    ),
                ],
              ),
            ),
          
          // Action Buttons
          Column(
            children: [
              if (QuizEngine.isPassing(result.percentage))
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
                        _selectedAnswers = List.filled(lesson.quiz.length, null);
                        _questionResults = [];
                        _currentQuestionIndex = 0;
                        _timeRemaining = 300;
                        
                        // إعادة تعيين مدراء التلميحات
                        for (final manager in _hintManagers.values) {
                          manager.reset();
                        }
                        
                        // إعادة تشغيل المؤقت
                        _quizTimer = QuizTimer(totalTime: const Duration(minutes: 5));
                        _quizTimer!.start();
                        _questionStartTimes[0] = DateTime.now();
                      });
                      _pageController = PageController();
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

  Widget _buildDetailedStats(EnhancedQuizResult result) {
    return Container(
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
                value: '${result.score}',
                color: Colors.green,
              ),
              _buildResultItem(
                icon: Icons.cancel,
                label: 'إجابات خاطئة',
                value: '${result.totalQuestions - result.score}',
                color: Colors.red,
              ),
              _buildResultItem(
                icon: Icons.access_time,
                label: 'الوقت المستغرق',
                value: '${result.timeSpent ~/ 60}:${(result.timeSpent % 60).toString().padLeft(2, '0')}',
                color: Colors.blue,
              ),
            ],
          ),
          
          if (result.hintsUsed > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResultItem(
                  icon: Icons.lightbulb,
                  label: 'تلميحات مستخدمة',
                  value: '${result.hintsUsed}',
                  color: Colors.amber,
                ),
              ],
            ),
          ],
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
