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
import '../../services/reward_service.dart';
import '../../widgets/custom_button.dart';
import '../../models/progress_model.dart';

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
  bool _alreadyCompleted = false;
  
  bool _isSavingResults = false;
  bool _resultsCalculated = false;
  int? _scoringTimeMs;
  DateTime? _scoringStartTime;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyCompleted();
    _loadLesson();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// التحقق من إكمال الاختبار مسبقاً
  Future<void> _checkIfAlreadyCompleted() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'guest';
    
    _alreadyCompleted = await RewardService.isQuizCompleted(widget.lessonId, userId);
    
    if (_alreadyCompleted) {
      print('⚠️ تم إكمال هذا الاختبار مسبقاً');
    }
  }

  Future<void> _loadLesson() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    
    print('🔍 بدء تحميل الدرس: ${widget.lessonId}');
    
    try {
      // تحميل الدرس للمستخدمين المسجلين والضيوف
      String userId = authProvider.user?.uid ?? 'guest';
      await lessonProvider.loadLesson(widget.lessonId, userId);
      
      final lesson = lessonProvider.currentLesson;
      print('📚 تم تحميل الدرس: ${lesson?.title}');
      print('❓ عدد أسئلة الاختبار: ${lesson?.quiz.length ?? 0}');
      
      if (lesson != null && lesson.quiz.isNotEmpty) {
        setState(() {
          _selectedAnswers = List.filled(lesson.quiz.length, -1);
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'guest';

    _scoringStartTime = DateTime.now();

    final isRetakeAfterPass = await RewardService.isRetakeAfterPass(widget.lessonId, userId);
    final retakeStats = await RewardService.getRetakeStats(widget.lessonId, userId);

    // التحقق من عدم إكمال الاختبار مسبقاً (للمحاولات الأولى فقط)
    if (!isRetakeAfterPass && await RewardService.isQuizCompleted(widget.lessonId, userId)) {
      setState(() {
        _isCompleted = true;
        _result = QuizResultModel(
          lessonId: widget.lessonId,
          score: 0,
          correctAnswers: 0,
          totalQuestions: lesson.quiz.length,
          answers: _selectedAnswers,
          completedAt: DateTime.now(),
        );
        _resultsCalculated = true;
        _scoringTimeMs = DateTime.now().difference(_scoringStartTime!).inMilliseconds;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إكمال هذا الاختبار مسبقاً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    int correctAnswers = 0;
    for (int i = 0; i < lesson.quiz.length; i++) {
      if (i < _selectedAnswers.length && _selectedAnswers[i] == lesson.quiz[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final score = RewardService.calculateScore(correctAnswers, lesson.quiz.length);
    
    // التحقق من صحة النتيجة
    if (!RewardService.isValidScore(score, lesson.quiz.length)) {
      print('❌ نتيجة غير صحيحة: $score');
      return;
    }

    _result = QuizResultModel(
      lessonId: widget.lessonId,
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: lesson.quiz.length,
      answers: _selectedAnswers,
      completedAt: DateTime.now(),
    );

    _scoringTimeMs = DateTime.now().difference(_scoringStartTime!).inMilliseconds;
    print('⏱️ وقت حساب النتائج: ${_scoringTimeMs}ms');
    print('📊 نتيجة الاختبار: $score% (${correctAnswers}/${lesson.quiz.length})');
    
    if (isRetakeAfterPass) {
      print('🔄 محاولة إعادة بعد النجاح - المكافأة التالية: ${retakeStats.nextRewardPercentage}');
    }

    setState(() {
      _isCompleted = true;
      _resultsCalculated = true;
    });

    _saveResultsInBackground(authProvider, lessonProvider, userId, lesson, isRetakeAfterPass);
  }

  Future<void> _saveResultsInBackground(
    AuthProvider authProvider,
    LessonProvider lessonProvider,
    String userId,
    LessonModel lesson,
    bool isRetakeAfterPass, // إضافة معامل إعادة المحاولة
  ) async {
    if (_result == null) return;

    setState(() {
      _isSavingResults = true;
    });

    try {
      // حفظ النتيجة وإضافة المكافآت
      if (!authProvider.isGuestUser && authProvider.user != null) {
        final futures = <Future>[];

        // حفظ نتيجة الاختبار
        futures.add(
          FirebaseService.saveQuizResult(authProvider.user!.uid, widget.lessonId, _result!)
            .timeout(const Duration(seconds: 5))
        );
        
        if (!isRetakeAfterPass) {
          futures.add(
            RewardService.markQuizCompleted(widget.lessonId, userId, _result!.score)
              .timeout(const Duration(seconds: 3))
          );
        }
        
        // تحديث حالة الدرس
        futures.add(
          lessonProvider.updateLessonStateAfterCompletion(
            widget.lessonId, 
            authProvider.user!.uid, 
            _result!.isPassed
          ).timeout(const Duration(seconds: 3))
        );

        // انتظار جميع العمليات الأساسية
        await Future.wait(futures, eagerError: false);
        
        // إضافة المكافآت إذا نجح
        if (_result!.isPassed) {
          final rewardInfo = await RewardService.getLessonRewardsWithRetakeLogic(
            lesson, 
            _result!.score, 
            userId,
            isRetakeAfterPass: isRetakeAfterPass
          );
          
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          
          final success = await userProvider.addReward(rewardInfo, authProvider.user!.uid)
            .timeout(const Duration(seconds: 5), onTimeout: () => false);
          
          if (success) {
            print('✅ تم إضافة المكافآت: $rewardInfo');
          } else {
            print('❌ فشل في إضافة المكافآت');
          }

          if (!isRetakeAfterPass) {
            await RewardService.recordFirstPassTime(widget.lessonId, userId);
          } else {
            await RewardService.recordRetakeAttempt(widget.lessonId, userId);
          }
          
          try {
            final nextLesson = await lessonProvider.unlockNextLesson(
              widget.lessonId, 
              userProvider.user?.completedLessons ?? []
            ).timeout(const Duration(seconds: 3));
            
            if (nextLesson != null) {
              print('🔓 تم فتح الدرس التالي: ${nextLesson.title}');
            }
          } catch (e) {
            print('⚠️ فشل في فتح الدرس التالي: $e');
          }
        }
      } else {
        // للضيوف - تسجيل الإكمال محلياً فقط
        if (!isRetakeAfterPass) {
          await RewardService.markQuizCompleted(widget.lessonId, userId, _result!.score)
            .timeout(const Duration(seconds: 3));
        }
        
        await lessonProvider.updateLessonStateAfterCompletion(
          widget.lessonId, 
          userId, 
          _result!.isPassed
        ).timeout(const Duration(seconds: 3));

        if (_result!.isPassed) {
          if (!isRetakeAfterPass) {
            await RewardService.recordFirstPassTime(widget.lessonId, userId);
          } else {
            await RewardService.recordRetakeAttempt(widget.lessonId, userId);
          }
        }
      }

      print('✅ تم حفظ جميع النتائج بنجاح');
    } catch (e) {
      print('❌ خطأ في حفظ النتيجة: $e');
      // عرض رسالة خطأ للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حساب النتيجة بنجاح، لكن حدث خطأ في الحفظ: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingResults = false;
        });
      }
    }
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
          
          // التحقق من وجود الدرس
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
          
          // التحقق من وجود أسئلة الاختبار
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

          // عرض تحذير إذا تم إكمال الاختبار مسبقاً
          if (_alreadyCompleted && !_isCompleted) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('تم إكمال هذا الاختبار مسبقاً'),
                  const SizedBox(height: 8),
                  const Text('لا يمكن إعادة الاختبار للحصول على مكافآت إضافية'),
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
                onPressed: _resultsCalculated ? null : _previousQuestion,
                isOutlined: true,
                icon: Icons.arrow_back_ios,
              ),
            ),
          
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          
          // Next/Submit Button
          Expanded(
            flex: 2,
            child: _resultsCalculated 
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'تم حساب النتائج',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_scoringTimeMs != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${_scoringTimeMs}ms)',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : CustomButton(
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
    return FutureBuilder<RetakeStats>(
      future: RewardService.getRetakeStats(widget.lessonId, Provider.of<AuthProvider>(context, listen: false).user?.uid ?? 'guest'),
      builder: (context, retakeSnapshot) {
        final retakeStats = retakeSnapshot.data;
        final rewardInfo = result.isPassed ? RewardService.getLessonRewards(lesson, result.score) : null;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_isSavingResults)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('جاري حفظ النتائج...'),
                    ],
                  ),
                ),

              if (retakeStats != null && retakeStats.hasPassedBefore)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: retakeStats.willGetNoReward 
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: retakeStats.willGetNoReward 
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.3)
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            color: retakeStats.willGetNoReward ? Colors.orange : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'محاولة إعادة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: retakeStats.willGetNoReward ? Colors.orange[700] : Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        retakeStats.statusMessage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (retakeStats.retakeAttempts > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'المحاولة رقم ${retakeStats.retakeAttempts + 1} بعد النجاح',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

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
              
              if (_scoringTimeMs != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'تم حساب النتائج في ${_scoringTimeMs}ms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
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
                        if (rewardInfo != null)
                          _buildResultItem(
                            icon: Icons.star,
                            label: 'XP مكتسب',
                            value: '${rewardInfo.xp}',
                            color: Colors.amber,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Rewards (if passed)
              if (result.isPassed && rewardInfo != null)
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
                        '${rewardInfo.xp} نقطة خبرة + ${rewardInfo.gems} جوهرة',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (retakeStats != null && retakeStats.hasPassedBefore && retakeStats.nextRewardMultiplier < 1.0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'مكافأة مقللة (${retakeStats.nextRewardPercentage}) - محاولة إعادة',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[600],
                              fontStyle: FontStyle.italic,
                            ),
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
                    Consumer<LessonProvider>(
                      builder: (context, lessonProvider, child) {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        final nextLesson = lessonProvider.getNextAvailableLesson(
                          userProvider.user?.completedLessons ?? []
                        );
                        
                        return SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: nextLesson != null ? 'الدرس التالي' : 'العودة للرئيسية',
                            onPressed: () {
                              if (nextLesson != null) {
                                context.go('/lesson/${nextLesson.id}');
                              } else {
                                context.go('/home');
                              }
                            },
                            icon: nextLesson != null ? Icons.arrow_forward : Icons.home,
                          ),
                        );
                      },
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'إعادة المحاولة',
                        onPressed: () {
                          // إعادة تعيين الاختبار للمحاولة مرة أخرى
                          setState(() {
                            _isCompleted = false;
                            _result = null;
                            _resultsCalculated = false;
                            _isSavingResults = false;
                            _scoringTimeMs = null;
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
      },
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
