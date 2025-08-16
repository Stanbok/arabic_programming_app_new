import '../models/lesson_model.dart';
import '../models/enhanced_quiz_result.dart';
import '../models/question_type.dart'; // استored import statement

class QuizEngine {
  static const double _passingScore = 70.0;
  
  /// تقييم إجابة سؤال واحد
  static QuestionResult evaluateQuestion(
    QuizQuestionModel question,
    dynamic userAnswer, {
    Duration? timeSpent,
    int hintsUsed = 0,
    int attempts = 1,
  }) {
    bool isCorrect = false;
    
    switch (question.type) {
      case QuestionType.multipleChoice:
        isCorrect = _evaluateMultipleChoice(question, userAnswer);
        break;
      case QuestionType.reorderCode:
        isCorrect = _evaluateReorderCode(question, userAnswer);
        break;
      case QuestionType.findBug:
        isCorrect = _evaluateFindBug(question, userAnswer);
        break;
      case QuestionType.fillInBlank:
        isCorrect = _evaluateFillInBlank(question, userAnswer);
        break;
      case QuestionType.trueFalse:
        isCorrect = _evaluateTrueFalse(question, userAnswer);
        break;
      case QuestionType.matchPairs:
        isCorrect = _evaluateMatchPairs(question, userAnswer);
        break;
      case QuestionType.codeOutput:
        isCorrect = _evaluateCodeOutput(question, userAnswer);
        break;
      case QuestionType.completeCode:
        isCorrect = _evaluateCompleteCode(question, userAnswer);
        break;
    }
    
    return QuestionResult(
      questionId: question.id,
      type: question.type.displayName,
      isCorrect: isCorrect,
      userAnswer: userAnswer,
      correctAnswer: _getCorrectAnswer(question),
      timeSpent: timeSpent ?? const Duration(seconds: 0),
      hintsUsed: hintsUsed,
      attempts: attempts,
    );
  }
  
  /// تقييم اختبار كامل
  static EnhancedQuizResult evaluateQuiz(
    String lessonId,
    String userId,
    List<QuizQuestionModel> questions,
    List<QuestionResult> questionResults, {
    Duration? totalTimeSpent,
    int totalHintsUsed = 0,
  }) {
    final correctAnswers = questionResults.where((result) => result.isCorrect).length;
    final percentage = questions.isNotEmpty ? (correctAnswers / questions.length) * 100 : 0.0;
    final isPerfectScore = correctAnswers == questions.length;
    
    // حساب إحصائيات حسب نوع السؤال
    final questionTypeStats = <String, int>{};
    for (final result in questionResults) {
      if (result.isCorrect) {
        final typeKey = result.type.toString();
        questionTypeStats[typeKey] = (questionTypeStats[typeKey] ?? 0) + 1;
      }
    }
    
    // حساب المكافآت
    final rewards = _calculateRewards(percentage, questions.length, isPerfectScore);
    
    // تحويل questionResults إلى Map
    final questionResultsMap = <String, dynamic>{};
    for (int i = 0; i < questionResults.length; i++) {
      final result = questionResults[i];
      questionResultsMap['question_$i'] = {
        'questionId': result.questionId,
        'type': result.type.toString(),
        'isCorrect': result.isCorrect,
        'userAnswer': result.userAnswer,
        'correctAnswer': result.correctAnswer,
        'timeSpent': result.timeSpent.inSeconds,
        'hintsUsed': result.hintsUsed,
        'attempts': result.attempts,
      };
    }
    
    // تحليل نقاط القوة والضعف
    final analysis = _analyzeQuestionTypes(questionResults);
    
    return EnhancedQuizResult(
      id: '${lessonId}_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      lessonId: lessonId,
      userId: userId,
      score: correctAnswers,
      totalQuestions: questions.length,
      percentage: percentage,
      completedAt: DateTime.now(),
      timeSpent: (totalTimeSpent ?? const Duration(minutes: 5)).inSeconds,
      questionResults: questionResultsMap,
      questionTypeStats: questionTypeStats,
      hintsUsed: totalHintsUsed,
      weakAreas: analysis['weakAreas'] as List<String>,
      strongAreas: analysis['strongAreas'] as List<String>,
      difficultyRating: _calculateDifficultyRating(questions, questionResults),
      isPassed: isPassing(percentage),
    );
  }
  
  /// تقييم الاختيار من متعدد
  static bool _evaluateMultipleChoice(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! int) return false;
    return userAnswer == question.correctAnswerIndex;
  }
  
  /// تقييم ترتيب الكود
  static bool _evaluateReorderCode(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! List<int>) return false;
    if (question.correctOrder == null) return false;
    
    if (userAnswer.length != question.correctOrder!.length) return false;
    
    for (int i = 0; i < userAnswer.length; i++) {
      if (userAnswer[i] != question.correctOrder![i]) return false;
    }
    
    return true;
  }
  
  /// تقييم البحث عن الخطأ
  static bool _evaluateFindBug(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! String) return false;
    if (question.correctCode == null) return false;
    
    return _normalizeCode(userAnswer) == _normalizeCode(question.correctCode!);
  }
  
  /// تقييم ملء الفراغات
  static bool _evaluateFillInBlank(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! List<String>) return false;
    if (question.correctAnswers == null) return false;
    
    if (userAnswer.length != question.correctAnswers!.length) return false;
    
    for (int i = 0; i < userAnswer.length; i++) {
      final userAns = userAnswer[i].toLowerCase().trim();
      final correctAns = question.correctAnswers![i].toLowerCase().trim();
      
      if (userAns != correctAns) {
        // تحقق من الإجابات البديلة المحتملة
        if (!_isAlternativeAnswer(userAns, correctAns)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// تقييم صح/خطأ
  static bool _evaluateTrueFalse(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! bool) return false;
    return userAnswer == question.correctBoolean;
  }
  
  /// تقييم توصيل الأزواج
  static bool _evaluateMatchPairs(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! Map<String, String>) return false;
    if (question.pairs == null) return false;
    
    if (userAnswer.length != question.pairs!.length) return false;
    
    for (final entry in question.pairs!.entries) {
      if (userAnswer[entry.key] != entry.value) return false;
    }
    
    return true;
  }
  
  /// تقييم نتيجة الكود
  static bool _evaluateCodeOutput(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! String) return false;
    if (question.expectedOutput == null) return false;
    
    return _normalizeOutput(userAnswer) == _normalizeOutput(question.expectedOutput!);
  }
  
  /// تقييم إكمال الكود
  static bool _evaluateCompleteCode(QuizQuestionModel question, dynamic userAnswer) {
    if (userAnswer is! String) return false;
    if (question.correctCode == null) return false;
    
    return _normalizeCode(userAnswer) == _normalizeCode(question.correctCode!);
  }
  
  /// الحصول على الإجابة الصحيحة
  static dynamic _getCorrectAnswer(QuizQuestionModel question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return question.correctAnswerIndex;
      case QuestionType.reorderCode:
        return question.correctOrder;
      case QuestionType.findBug:
      case QuestionType.completeCode:
        return question.correctCode;
      case QuestionType.fillInBlank:
        return question.correctAnswers;
      case QuestionType.trueFalse:
        return question.correctBoolean;
      case QuestionType.matchPairs:
        return question.pairs;
      case QuestionType.codeOutput:
        return question.expectedOutput;
    }
  }
  
  /// تطبيع الكود للمقارنة
  static String _normalizeCode(String code) {
    return code
        .replaceAll(RegExp(r'\s+'), ' ') // استبدال المسافات المتعددة بمسافة واحدة
        .replaceAll(RegExp(r'^\s+|\s+$'), '') // إزالة المسافات من البداية والنهاية
        .toLowerCase();
  }
  
  /// تطبيع النتيجة للمقارنة
  static String _normalizeOutput(String output) {
    return output
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^\s+|\s+$'), '')
        .toLowerCase();
  }
  
  /// التحقق من الإجابات البديلة
  static bool _isAlternativeAnswer(String userAnswer, String correctAnswer) {
    // قائمة بالإجابات البديلة المقبولة
    final alternatives = <String, List<String>>{
      'print': ['طباعة', 'اطبع'],
      'input': ['إدخال', 'مدخل'],
      'string': ['نص', 'سلسلة نصية'],
      'integer': ['عدد صحيح', 'رقم صحيح'],
      'float': ['عدد عشري', 'رقم عشري'],
      'list': ['قائمة', 'مصفوفة'],
      'dictionary': ['قاموس', 'معجم'],
      'function': ['دالة', 'وظيفة'],
      'variable': ['متغير', 'متحول'],
      'loop': ['حلقة', 'تكرار'],
      'condition': ['شرط', 'حالة'],
    };
    
    for (final entry in alternatives.entries) {
      if (entry.key == correctAnswer && entry.value.contains(userAnswer)) {
        return true;
      }
      if (entry.value.contains(correctAnswer) && entry.key == userAnswer) {
        return true;
      }
    }
    
    return false;
  }
  
  /// حساب المكافآت
  static Map<String, int> _calculateRewards(double percentage, int totalQuestions, bool isPerfectScore) {
    int baseXP = totalQuestions * 10; // 10 XP لكل سؤال
    int baseGems = totalQuestions ~/ 2; // جوهرة لكل سؤالين
    
    if (percentage < _passingScore) {
      // لا مكافآت للرسوب
      return {'xp': 0, 'gems': 0};
    }
    
    // مكافآت إضافية حسب الدرجة
    double multiplier = 1.0;
    if (isPerfectScore) {
      multiplier = 1.5; // مكافأة 50% إضافية للدرجة الكاملة
      baseGems += 2; // جواهر إضافية للدرجة الكاملة
    } else if (percentage >= 90) {
      multiplier = 1.3; // مكافأة 30% إضافية للدرجات العالية
      baseGems += 1;
    } else if (percentage >= 80) {
      multiplier = 1.1; // مكافأة 10% إضافية للدرجات الجيدة
    }
    
    return {
      'xp': (baseXP * multiplier).round(),
      'gems': baseGems,
    };
  }
  
  /// التحقق من النجاح
  static bool isPassing(double percentage) {
    return percentage >= _passingScore;
  }
  
  /// حساب عدد النجوم
  static int calculateStars(double percentage) {
    if (percentage >= 95) return 3;
    if (percentage >= 80) return 2;
    if (percentage >= _passingScore) return 1;
    return 0;
  }
  
  /// حساب الدرجة النصية
  static String getGrade(double percentage) {
    if (percentage >= 95) return 'ممتاز+';
    if (percentage >= 90) return 'ممتاز';
    if (percentage >= 85) return 'جيد جداً+';
    if (percentage >= 80) return 'جيد جداً';
    if (percentage >= 75) return 'جيد+';
    if (percentage >= _passingScore) return 'جيد';
    if (percentage >= 60) return 'مقبول';
    if (percentage >= 50) return 'ضعيف';
    return 'راسب';
  }
  
  /// إنشاء تلميحات ذكية
  static List<String> generateHints(QuizQuestionModel question) {
    final hints = <String>[];
    
    // إضافة التلميحات المخصصة إذا كانت متوفرة
    if (question.hints != null && question.hints!.isNotEmpty) {
      hints.addAll(question.hints!);
    }
    
    switch (question.type) {
      case QuestionType.multipleChoice:
        hints.add('اقرأ السؤال بعناية واستبعد الخيارات الخاطئة أولاً');
        break;
      case QuestionType.reorderCode:
        hints.add('فكر في التسلسل المنطقي لتنفيذ الكود');
        hints.add('ابدأ بالتعريفات والمتغيرات أولاً');
        break;
      case QuestionType.findBug:
        hints.add('ابحث عن الأخطاء الإملائية في أسماء المتغيرات والدوال');
        hints.add('تحقق من علامات الترقيم والأقواس');
        break;
      case QuestionType.fillInBlank:
        hints.add('فكر في السياق العام للجملة');
        hints.add('استخدم المصطلحات التقنية المناسبة');
        break;
      case QuestionType.trueFalse:
        hints.add('ابحث عن الكلمات المطلقة مثل "دائماً" أو "أبداً"');
        break;
      case QuestionType.matchPairs:
        hints.add('ابدأ بالمطابقات التي تعرفها بثقة');
        hints.add('استخدم عملية الاستبعاد للخيارات المتبقية');
        break;
      case QuestionType.codeOutput:
        hints.add('تتبع تنفيذ الكود خطوة بخطوة');
        hints.add('انتبه لقيم المتغيرات في كل خطوة');
        break;
      case QuestionType.completeCode:
        hints.add('فكر في الهدف من الكود والنتيجة المطلوبة');
        hints.add('استخدم الصيغة الصحيحة للغة Python');
        break;
    }
    
    return hints;
  }
  
  /// تحليل أداء المستخدم
  static Map<String, dynamic> analyzePerformance(List<EnhancedQuizResult> quizHistory) {
    if (quizHistory.isEmpty) {
      return {
        'averageScore': 0.0,
        'totalQuizzes': 0,
        'strongAreas': <String>[],
        'weakAreas': <String>[],
        'improvement': 0.0,
        'streakCount': 0,
      };
    }
    
    // حساب المتوسط العام
    final averageScore = quizHistory.map((quiz) => quiz.percentage).reduce((a, b) => a + b) / quizHistory.length;
    
    // تحليل الأداء حسب نوع السؤال
    final typePerformance = <String, List<double>>{};
    
    for (final quiz in quizHistory) {
      for (final entry in quiz.questionResults.entries) {
        final questionData = entry.value as Map<String, dynamic>;
        final typeString = questionData['type'] as String;
        final isCorrect = questionData['isCorrect'] as bool;
        
        typePerformance.putIfAbsent(typeString, () => []);
        typePerformance[typeString]!.add(isCorrect ? 100.0 : 0.0);
      }
    }
    
    // تحديد نقاط القوة والضعف
    final strongAreas = <String>[];
    final weakAreas = <String>[];
    
    typePerformance.forEach((type, scores) {
      final average = scores.reduce((a, b) => a + b) / scores.length;
      if (average >= 80) {
        strongAreas.add(type);
      } else if (average < 60) {
        weakAreas.add(type);
      }
    });
    
    // حساب التحسن
    double improvement = 0.0;
    if (quizHistory.length >= 6) {
      // أخذ آخر 3 نتائج
      final recentResults = quizHistory.sublist(quizHistory.length - 3);
      final recent = recentResults.map((q) => q.percentage).reduce((a, b) => a + b) / 3;
      
      // أخذ النتائج الأقدم
      final olderResults = quizHistory.sublist(0, quizHistory.length - 3);
      final older = olderResults.map((q) => q.percentage).reduce((a, b) => a + b) / olderResults.length;
      
      improvement = recent - older;
    }
    
    // حساب سلسلة النجاح
    int streakCount = 0;
    for (int i = quizHistory.length - 1; i >= 0; i--) {
      if (quizHistory[i].percentage >= _passingScore) {
        streakCount++;
      } else {
        break;
      }
    }
    
    return {
      'averageScore': averageScore,
      'totalQuizzes': quizHistory.length,
      'strongAreas': strongAreas,
      'weakAreas': weakAreas,
      'improvement': improvement,
      'streakCount': streakCount,
    };
  }
  
  static Map<String, dynamic> _analyzeQuestionTypes(List<QuestionResult> questionResults) {
    final typeStats = <String, List<bool>>{};
    
    for (final result in questionResults) {
      typeStats.putIfAbsent(result.type.toString(), () => []);
      typeStats[result.type.toString()]!.add(result.isCorrect);
    }
    
    final strongAreas = <String>[];
    final weakAreas = <String>[];
    
    typeStats.forEach((type, results) {
      final correctCount = results.where((correct) => correct).length;
      final percentage = correctCount / results.length * 100;
      
      if (percentage >= 80) {
        strongAreas.add(type);
      } else if (percentage < 60) {
        weakAreas.add(type);
      }
    });
    
    return {
      'strongAreas': strongAreas,
      'weakAreas': weakAreas,
    };
  }
  
  static double _calculateDifficultyRating(List<QuizQuestionModel> questions, List<QuestionResult> results) {
    if (questions.isEmpty || results.isEmpty) return 1.0;
    
    final correctCount = results.where((r) => r.isCorrect).length;
    final successRate = correctCount / results.length;
    
    // كلما قل معدل النجاح، زادت الصعوبة
    return (1.0 - successRate) * 5.0; // تقييم من 0 إلى 5
  }
}

/// نتيجة سؤال واحد
class QuestionResult {
  final String questionId;
  final String type;
  final bool isCorrect;
  final dynamic userAnswer;
  final dynamic correctAnswer;
  final Duration timeSpent;
  final int hintsUsed;
  final int attempts;

  QuestionResult({
    required this.questionId,
    required this.type,
    required this.isCorrect,
    required this.userAnswer,
    required this.correctAnswer,
    required this.timeSpent,
    required this.hintsUsed,
    required this.attempts,
  });
}

/// فئة مساعدة لإدارة الوقت في الاختبارات
class QuizTimer {
  final Duration totalTime;
  late DateTime _startTime;
  bool _isRunning = false;
  
  QuizTimer({required this.totalTime});
  
  void start() {
    _startTime = DateTime.now();
    _isRunning = true;
  }
  
  void stop() {
    _isRunning = false;
  }
  
  Duration get elapsed {
    if (!_isRunning) return Duration.zero;
    return DateTime.now().difference(_startTime);
  }
  
  Duration get remaining {
    if (!_isRunning) return totalTime;
    final elapsed = DateTime.now().difference(_startTime);
    final remaining = totalTime - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  bool get isExpired {
    return remaining == Duration.zero;
  }
  
  double get progressPercentage {
    if (totalTime.inSeconds == 0) return 1.0;
    return elapsed.inSeconds / totalTime.inSeconds;
  }
}

/// فئة مساعدة لإدارة التلميحات
class HintManager {
  final List<String> _hints;
  int _currentHintIndex = 0;
  int _hintsUsed = 0;
  
  HintManager(this._hints);
  
  String? getNextHint() {
    if (_currentHintIndex >= _hints.length) return null;
    
    final hint = _hints[_currentHintIndex];
    _currentHintIndex++;
    _hintsUsed++;
    
    return hint;
  }
  
  bool get hasMoreHints => _currentHintIndex < _hints.length;
  int get hintsUsed => _hintsUsed;
  int get totalHints => _hints.length;
  
  void reset() {
    _currentHintIndex = 0;
    _hintsUsed = 0;
  }
}
