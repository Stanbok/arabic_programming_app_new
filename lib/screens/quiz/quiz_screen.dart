import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../providers/lesson_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_result_model.dart';
import '../../models/lesson_attempt_model.dart';
import '../../services/firebase_service.dart';
import '../../services/reward_service.dart';
import '../../services/statistics_service.dart';
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
  bool _isSubmitting = false;
  QuizResultModel? _result;
  LessonAttemptModel? _attemptResult;
  bool _alreadyCompleted = false;
  int _scoringStartTime = 0;

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
      print('⚠️ تم إكمال هذا الاختبار مسبقاً - يمكن إعادة المحاولة للمراجعة');
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
    if (_isSubmitting) return; // Prevent duplicate submissions
    
    setState(() {
      _isSubmitting = true;
    });
    
    _timer?.cancel();
    _scoringStartTime = DateTime.now().millisecondsSinceEpoch;
    
    final lesson = _getCurrentLesson();
    if (lesson == null) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'guest';

    try {
      // حساب النتائج بشكل متزامن
      int correctAnswers = 0;
      for (int i = 0; i < lesson.quiz.length; i++) {
        if (i < _selectedAnswers.length && _selectedAnswers[i] == lesson.quiz[i].correctAnswerIndex) {
          correctAnswers++;
        }
      }

      final score = RewardService.calculateScore(correctAnswers, lesson.quiz.length);
      final scoringEndTime = DateTime.now().millisecondsSinceEpoch;
      final scoringTimeMs = scoringEndTime - _scoringStartTime;
      
      print('📊 نتائج الاختبار:');
      print('   - النتيجة: $score%');
      print('   - الإجابات الصحيحة: $correctAnswers/${lesson.quiz.length}');
      print('   - وقت الحساب: ${scoringTimeMs}ms');
      
      // التحقق من صحة النتيجة
      if (!RewardService.isValidScore(score, lesson.quiz.length)) {
        print('❌ نتيجة غير صحيحة: $score');
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // تحديد ما إذا كانت هذه أول مرة ينجح فيها المستخدم
      final previousAttempts = await StatisticsService.getAttempts(widget.lessonId, userId);
      final isFirstPass = score >= 70 && !previousAttempts.any((a) => a.isPassed);

      print('🎯 تحليل المحاولة:');
      print('   - المحاولات السابقة: ${previousAttempts.length}');
      print('   - نجح من قبل: ${previousAttempts.any((a) => a.isPassed)}');
      print('   - أول نجاح: $isFirstPass');

      // حساب المكافآت
      int xpAwarded = 0;
      int gemsAwarded = 0;
      
      if (score >= 70) { // نجح في الاختبار
        final rewardInfo = await RewardService.getLessonRewards(lesson, score, userId, isFirstPass);
        xpAwarded = rewardInfo.xp;
        gemsAwarded = rewardInfo.gems;
        
        print('💎 المكافآت المحسوبة:');
        print('   - XP: $xpAwarded');
        print('   - Gems: $gemsAwarded');
        print('   - مضاعف إعادة المحاولة: ${rewardInfo.retakeMultiplier}');
      }

      // تسجيل المحاولة في الإحصائيات
      _attemptResult = await StatisticsService.recordAttempt(
        lessonId: widget.lessonId,
        userId: userId,
        score: score,
        correctAnswers: correctAnswers,
        totalQuestions: lesson.quiz.length,
        answers: _selectedAnswers,
        scoringTimeMs: scoringTimeMs,
        xpAwarded: xpAwarded,
        gemsAwarded: gemsAwarded,
      );

      _result = QuizResultModel(
        lessonId: widget.lessonId,
        score: score,
        correctAnswers: correctAnswers,
        totalQuestions: lesson.quiz.length,
        answers: _selectedAnswers,
        completedAt: DateTime.now(),
      );

      print('✅ تم إنشاء نتيجة الاختبار والمحاولة بنجاح');

      // حفظ النتيجة وإضافة المكافآت للمستخدمين المسجلين
      if (!authProvider.isGuestUser && authProvider.user != null) {
        try {
          // حفظ نتيجة الاختبار
          await FirebaseService.saveQuizResult(authProvider.user!.uid, widget.lessonId, _result!);
          
          // إضافة المكافآت إذا نجح
          if (_result!.isPassed && (xpAwarded > 0 || gemsAwarded > 0)) {
            final rewardInfo = await RewardService.getLessonRewards(lesson, score, userId, isFirstPass);
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            
            final success = await userProvider.addReward(rewardInfo, authProvider.user!.uid);
            
            if (success) {
              print('✅ تم إضافة المكافآت: $rewardInfo');
            } else {
              print('❌ فشل في إضافة المكافآت');
            }
          }

          // تحديث حالة الدرس إذا نجح لأول مرة
          if (isFirstPass) {
            final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
            await lessonProvider.markLessonCompleted(widget.lessonId, userId);
          }
        } catch (e) {
          print('❌ خطأ في حفظ النتيجة: $e');
        }
      }

      setState(() {
        _isCompleted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      print('❌ خطأ في معالجة الاختبار: $e');
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في معالجة الاختبار: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

          if (_isCompleted && _result != null) {
            return _buildResultScreen(lesson, _result!, _attemptResult);
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
                onPressed: _isSubmitting ? null : _previousQuestion,
                isOutlined: true,
                icon: Icons.arrow_back_ios,
              ),
            ),
          
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          
          // Next/Submit Button
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _isSubmitting 
                  ? 'جاري الحساب...' 
                  : (isLastQuestion ? 'إنهاء الاختبار' : 'التالي'),
              onPressed: _isSubmitting 
                  ? null 
                  : (hasAnswered ? (isLastQuestion ? _submitQuiz : _nextQuestion) : null),
              icon: _isSubmitting 
                  ? Icons.hourglass_empty 
                  : (isLastQuestion ? Icons.check : Icons.arrow_forward_ios),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(LessonModel lesson, QuizResultModel result, LessonAttemptModel? attempt) {
    final isRetake = attempt != null && !attempt.isFirstPass;
    final retakeMultiplier = attempt?.xpAwarded != null && attempt!.xpAwarded > 0 
        ? (attempt.xpAwarded / (lesson.xpReward * (result.score >= 95 ? 1.5 : result.score >= 85 ? 1.25 : 1.0)))
        : 0.0;
    
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
                ? (isRetake ? 'أحسنت! مراجعة ممتازة للدرس' : 'لقد نجحت في الاختبار بتفوق!')
                : 'لم تحصل على الدرجة المطلوبة للنجاح (70%)',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          
          // Retake indicator
          if (isRetake && result.isPassed)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'مراجعة - مكافأة مخفضة (${(retakeMultiplier * 100).round()}%)',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
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
                    if (attempt != null && attempt.xpAwarded > 0)
                      _buildResultItem(
                        icon: Icons.star,
                        label: 'XP مكتسب',
                        value: '${attempt.xpAwarded}',
                        color: Colors.amber,
                      ),
                  ],
                ),
                
                if (attempt != null && attempt.scoringTimeMs > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'وقت الحساب: ${attempt.scoringTimeMs}ms',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Rewards (if passed)
          if (result.isPassed && attempt != null && (attempt.xpAwarded > 0 || attempt.gemsAwarded > 0))
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
                    '${attempt.xpAwarded} نقطة خبرة + ${attempt.gemsAwarded} جوهرة',
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
              if (result.isPassed && attempt != null && attempt.isFirstPass)
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
                    text: result.isPassed ? 'إعادة المحاولة للمراجعة' : 'إعادة المحاولة',
                    onPressed: () {
                      // Reset quiz state for retake
                      setState(() {
                        _isCompleted = false;
                        _result = null;
                        _attemptResult = null;
                        _currentQuestionIndex = 0;
                        _selectedAnswers = List.filled(lesson.quiz.length, -1);
                        _timeRemaining = 300;
                        _isSubmitting = false;
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
