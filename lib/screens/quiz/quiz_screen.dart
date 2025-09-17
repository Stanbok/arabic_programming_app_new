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
import '../../models/decay_tracker_model.dart';

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
  bool _showFeedback = false;
  bool _canContinue = false;
  bool _isNavigatingToResult = false;
  Map<String, int>? _actualRewards;

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
      await lessonProvider.loadLesson(widget.lessonId, authProvider.user?.uid ?? 'guest');
      final lesson = lessonProvider.currentLesson;
      
      if (lesson != null && lesson.quiz.isNotEmpty) {
        setState(() {
          _selectedAnswers = List.filled(lesson.quiz.length, null);
          _answeredQuestions = List.filled(lesson.quiz.length, false);
          _questionResults = [];
          
          // تهيئة مدراء التلميحات
          for (int i = 0; i < lesson.quiz.length; i++) {
            _hintManagers[i] = HintManager(lesson.quiz[i].hints ?? []);
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
      _canContinue = true;
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
      
      final questionResult = QuizEngine.evaluateQuestion(
        question, 
        userAnswer,
        timeSpent: timeSpent,
        hintsUsed: _hintManagers[_currentQuestionIndex]?.hintsUsed ?? 0,
      );
      
      // إزالة النتيجة السابقة إن وجدت وإضافة الجديدة
      _questionResults.removeWhere((r) => r.questionId == question.id);
      _questionResults.add(questionResult);
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = QuizEngine.evaluateQuiz(
        widget.lessonId,
        authProvider.user?.uid ?? 'guest',
        lesson.quiz,
        _questionResults,
        totalTimeSpent: Duration(seconds: 300 - _timeRemaining),
      );
      
      setState(() {
        _result = result;
      });
      
      // حفظ النتيجة
      await _saveQuizResult();
      
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

  Future<void> _saveQuizResult() async {
    if (_isNavigatingToResult || _result == null) return;
    _isNavigatingToResult = true;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      
      if (authProvider.user == null) return;

      final lesson = _getCurrentLesson()!;
      final result = _result!;

      // جلب أو إنشاء بيانات الاضمحلال
      var decayTracker = await lessonProvider.getDecayTracker(
        authProvider.user!.uid, 
        widget.lessonId
      );

      _actualRewards = RewardService.calculateTotalRewards(
        lesson, 
        result.percentage, 
        decayTracker: decayTracker
      );
      
      // حفظ نتيجة الكويز أولاً
      await FirebaseService.saveEnhancedQuizResult(
        authProvider.user!.uid,
        widget.lessonId,
        result,
      );
      
      // إضافة XP (مع الاضمحلال)
      if (result.isPassed && _actualRewards!['xp']! > 0) {
        await FirebaseService.addXPAndGems(
          authProvider.user!.uid,
          _actualRewards!['xp']!,
          0,
          'نقاط خبرة - ${lesson.title}',
        );
      }
      
      if (result.isPassed && _actualRewards!['gems']! > 0 && (decayTracker?.retakeCount ?? 0) == 0) {
        await FirebaseService.addXPAndGems(
          authProvider.user!.uid,
          0,
          _actualRewards!['gems']!,
          'جواهر - ${lesson.title} (المرة الأولى)',
        );
      }
      
      if (result.isPassed) {
        await lessonProvider.updateDecayTracker(
          authProvider.user!.uid,
          widget.lessonId,
          decayTracker,
        );
      }
      
      // عرض معلومات المكافآت والاضمحلال للمستخدم
      final decayInfo = RewardService.getDecayInfo(decayTracker);
      _showRewardInfo(_actualRewards!, decayInfo);
      
    } catch (e) {
      print('خطأ في حفظ نتيجة الكويز: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ النتيجة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRewardInfo(Map<String, int> rewards, Map<String, dynamic> decayInfo) {
    if (!decayInfo['isFirstTime'] && decayInfo['decayPercentage'] < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تم تطبيق نظام الاضمحلال: ${decayInfo['decayPercentage']}%'),
              Text('المكافآت: ${rewards['xp']} XP, ${rewards['gems']} جواهر'),
              Text(decayInfo['nextResetInfo']),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange,
        ),
      );
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
      _actualRewards = null;
      
      // إعادة تهيئة مدراء التلميحات
      final lesson = _getCurrentLesson()!;
      for (int i = 0; i < lesson.quiz.length; i++) {
        _hintManagers[i] = HintManager(lesson.quiz[i].hints ?? []);
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

  void _continueToNext() {
    final lesson = _getCurrentLesson();
    if (lesson == null) return;

    final question = lesson.quiz[_currentQuestionIndex];
    
    _showQuestionFeedback(question);
    
    // الانتقال فوري بعد عرض الفيدباك
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_currentQuestionIndex < lesson.quiz.length - 1) {
        _saveCurrentQuestionResult();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 200), // تسريع الانتقال
          curve: Curves.easeInOut,
        );
        setState(() {
          _canContinue = false;
        });
      } else {
        if (!_isCompleted) {
          _completeQuiz();
        }
      }
    });
  }

  void _showQuestionFeedback(QuizQuestionModel question) {
    final userAnswer = _selectedAnswers[_currentQuestionIndex];
    final isCorrect = QuizEngine.isAnswerCorrect(question, userAnswer);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizFeedbackPopup(
        question: question,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        onContinue: () {
          Navigator.of(context).pop();
        },
      ),
    );
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
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lesson.quiz.length,
                      itemBuilder: (context, index) {
                        final question = lesson.quiz[index];
                        return _buildQuestionWidget(question, index);
                      },
                    ),
                  ),
                  
                  // زر المتابعة الذكي
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _canContinue ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canContinue ? _continueToNext : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _canContinue ? 4 : 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentQuestionIndex < lesson.quiz.length - 1 
                                      ? 'متابعة' 
                                      : 'إنهاء الكويز',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentQuestionIndex < lesson.quiz.length - 1 
                                      ? Icons.arrow_forward 
                                      : Icons.check,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (lesson.quiz[_currentQuestionIndex].showHint == true)
                Positioned(
                  top: 100, // تعديل الموضع ليكون أقل تداخلاً
                  right: 16, // نقل لليمين بدلاً من اليسار
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return Container(
                        width: 40, // تصغير الحجم
                        height: 40,
                        decoration: BoxDecoration(
                          color: userProvider.hasHints 
                              ? Colors.amber.withOpacity(0.9)
                              : Colors.grey.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: (_hintManagers[_currentQuestionIndex]?.hasMoreHints ?? false) 
                                ? () {
                                    final hintManager = _hintManagers[_currentQuestionIndex];
                                    if (hintManager != null) {
                                      final hint = hintManager.getNextHint();
                                      if (hint != null) {
                                        _showHint(hint);
                                      }
                                    }
                                  }
                                : null,
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.lightbulb,
                                    color: Colors.white,
                                    size: 20, // تصغير الأيقونة
                                  ),
                                ),
                                if (userProvider.hasHints)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${userProvider.availableHints}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
          onAnswersChanged: _onAnswerSelected,
        );
      
      case QuestionType.reorderCode:
        return ReorderCodeWidget(
          question: question,
          onOrderChanged: _onAnswerSelected,
        );
      
      case QuestionType.findBug:
        return FindBugWidget(
          question: question,
          onAnswerChanged: _onAnswerSelected,
        );
      
      case QuestionType.codeOutput:
        return CodeOutputWidget(
          question: question,
          onAnswerChanged: _onAnswerSelected,
        );
      
      case QuestionType.completeCode:
        return CompleteCodeWidget(
          question: question,
          onAnswerChanged: _onAnswerSelected,
        );
      
      default:
        return const Center(
          child: Text('نوع سؤال غير مدعوم'),
        );
    }
  }

  void _showHint(String hint) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // التحقق من توفر تلميحات مجانية
    if (userProvider.hasHints) {
      // استخدام تلميح مجاني
      final success = await userProvider.useHint();
      if (success) {
        _displayHint(hint);
      }
    } else if (userProvider.canBuyHints) {
      // عرض خيار الشراء
      _showHintPurchaseDialog(hint);
    } else {
      // لا توجد جواهر كافية
      _showInsufficientGemsDialog();
    }
  }
  
  void _displayHint(String hint) {
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
  
  void _showHintPurchaseDialog(String hint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('شراء تلميح'),
        content: const Text('لا توجد تلميحات مجانية متاحة. هل تريد شراء 5 تلميحات مقابل 50 جوهرة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final success = await userProvider.purchaseHints();
              if (success) {
                _displayHint(hint);
              }
            },
            child: const Text('شراء'),
          ),
        ],
      ),
    );
  }
  
  void _showInsufficientGemsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جواهر غير كافية'),
        content: const Text('تحتاج إلى 50 جوهرة لشراء تلميحات إضافية.'),
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
        backgroundColor: Colors.green,
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
                      Icons.celebration,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'مبروك! لقد نجحت',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.percentage.round()}%',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.green,
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
                          icon: Icons.timer,
                          label: 'الوقت المستغرق',
                          value: _formatDuration(Duration(seconds: result.timeSpent)),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (result.isPassed) ...[
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
                            value: '+${_actualRewards?['xp'] ?? 0}',
                            color: Colors.amber,
                          ),
                          _buildRewardItem(
                            icon: Icons.diamond,
                            label: 'الجواهر',
                            value: '+${_actualRewards?['gems'] ?? 0}',
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
                        _actualRewards = null;
                        
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
                    icon: Icons.home,
                  ),
                ),
              ],
            ),
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
