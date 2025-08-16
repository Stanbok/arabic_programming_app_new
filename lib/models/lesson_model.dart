import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int unit; // تغيير من level إلى unit
  final int order;
  final int xpReward;
  final int gemsReward;
  final bool isPublished;
  final List<SlideModel> slides;
  final List<QuizQuestionModel> quiz;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.unit, // تغيير من level إلى unit
    required this.order,
    this.xpReward = 50,
    this.gemsReward = 2,
    this.isPublished = true,
    this.slides = const [],
    this.quiz = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'unit': unit, // تغيير من level إلى unit
      'order': order,
      'xpReward': xpReward,
      'gemsReward': gemsReward,
      'isPublished': isPublished,
      'slides': slides.map((slide) => slide.toMap()).toList(),
      'quiz': quiz.map((question) => question.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      unit: map['unit'] ?? map['level'] ?? 1, // دعم كل من unit و level للتوافق مع البيانات القديمة
      order: map['order'] ?? 0,
      xpReward: map['xpReward'] ?? 50,
      gemsReward: map['gemsReward'] ?? 2,
      isPublished: map['isPublished'] ?? true,
      slides: (map['slides'] as List<dynamic>?)
          ?.map((slide) => SlideModel.fromMap(slide))
          .toList() ?? [],
      quiz: (map['quiz'] as List<dynamic>?)
          ?.map((question) => QuizQuestionModel.fromMap(question))
          .toList() ?? [],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    } else if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    } else {
      return DateTime.now();
    }
  }
}

class SlideModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? codeExample;
  final int order;

  SlideModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.codeExample,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'codeExample': codeExample,
      'order': order,
    };
  }

  factory SlideModel.fromMap(Map<String, dynamic> map) {
    return SlideModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      codeExample: map['codeExample'],
      order: map['order'] ?? 0,
    );
  }
}

class QuizQuestionModel {
  final String id;
  final QuestionType type;
  final String question;
  final List<String>? options; // للاختيار من متعدد
  final int? correctAnswerIndex; // للاختيار من متعدد
  final String? explanation;
  final List<String>? codeBlocks; // لترتيب الكود
  final List<int>? correctOrder; // الترتيب الصحيح للكود
  final String? codeWithBug; // الكود الذي يحتوي على خطأ
  final String? correctCode; // الكود الصحيح
  final String? fillInBlankText; // النص مع الفراغات
  final List<String>? correctAnswers; // الإجابات الصحيحة للفراغات
  final bool? correctBoolean; // للأسئلة صح/خطأ
  final Map<String, String>? pairs; // للتوصيل بين الأزواج
  final String? expectedOutput; // النتيجة المتوقعة للكود
  final String? codeTemplate; // قالب الكود للإكمال
  final int difficulty; // مستوى الصعوبة 1-5
  final List<String>? hints; // تلميحات للمساعدة

  QuizQuestionModel({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    this.correctAnswerIndex,
    this.explanation,
    this.codeBlocks,
    this.correctOrder,
    this.codeWithBug,
    this.correctCode,
    this.fillInBlankText,
    this.correctAnswers,
    this.correctBoolean,
    this.pairs,
    this.expectedOutput,
    this.codeTemplate,
    this.difficulty = 1,
    this.hints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'codeBlocks': codeBlocks,
      'correctOrder': correctOrder,
      'codeWithBug': codeWithBug,
      'correctCode': correctCode,
      'fillInBlankText': fillInBlankText,
      'correctAnswers': correctAnswers,
      'correctBoolean': correctBoolean,
      'pairs': pairs,
      'expectedOutput': expectedOutput,
      'codeTemplate': codeTemplate,
      'difficulty': difficulty,
      'hints': hints,
    };
  }

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      id: map['id'] ?? '',
      type: _parseQuestionType(map['type']),
      question: map['question'] ?? '',
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswerIndex: map['correctAnswerIndex'],
      explanation: map['explanation'],
      codeBlocks: map['codeBlocks'] != null ? List<String>.from(map['codeBlocks']) : null,
      correctOrder: map['correctOrder'] != null ? List<int>.from(map['correctOrder']) : null,
      codeWithBug: map['codeWithBug'],
      correctCode: map['correctCode'],
      fillInBlankText: map['fillInBlankText'],
      correctAnswers: map['correctAnswers'] != null ? List<String>.from(map['correctAnswers']) : null,
      correctBoolean: map['correctBoolean'],
      pairs: map['pairs'] != null ? Map<String, String>.from(map['pairs']) : null,
      expectedOutput: map['expectedOutput'],
      codeTemplate: map['codeTemplate'],
      difficulty: map['difficulty'] ?? 1,
      hints: map['hints'] != null ? List<String>.from(map['hints']) : null,
    );
  }

  static QuestionType _parseQuestionType(dynamic type) {
    if (type == null) return QuestionType.multipleChoice;
    
    switch (type.toString()) {
      case 'QuestionType.multipleChoice':
        return QuestionType.multipleChoice;
      case 'QuestionType.reorderCode':
        return QuestionType.reorderCode;
      case 'QuestionType.findBug':
        return QuestionType.findBug;
      case 'QuestionType.fillInBlank':
        return QuestionType.fillInBlank;
      case 'QuestionType.trueFalse':
        return QuestionType.trueFalse;
      case 'QuestionType.matchPairs':
        return QuestionType.matchPairs;
      case 'QuestionType.codeOutput':
        return QuestionType.codeOutput;
      case 'QuestionType.completeCode':
        return QuestionType.completeCode;
      default:
        return QuestionType.multipleChoice;
    }
  }
}

enum QuestionType {
  multipleChoice,    // اختيار من متعدد
  reorderCode,       // ترتيب الكود
  findBug,           // اكتشف الخطأ
  fillInBlank,       // املأ الفراغ
  trueFalse,         // صح أو خطأ
  matchPairs,        // توصيل الأزواج
  codeOutput,        // ما هي نتيجة هذا الكود
  completeCode,      // أكمل الكود
}

class EnhancedQuizResult {
  final String lessonId;
  final String userId;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final int xpEarned;
  final int gemsEarned;
  final Duration timeSpent;
  final Map<QuestionType, int> questionTypeStats; // إحصائيات حسب نوع السؤال
  final List<QuestionResult> questionResults;
  final DateTime completedAt;
  final int hintsUsed;
  final bool isPerfectScore;

  EnhancedQuizResult({
    required this.lessonId,
    required this.userId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.xpEarned,
    required this.gemsEarned,
    required this.timeSpent,
    required this.questionTypeStats,
    required this.questionResults,
    required this.completedAt,
    this.hintsUsed = 0,
    this.isPerfectScore = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'userId': userId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'percentage': percentage,
      'xpEarned': xpEarned,
      'gemsEarned': gemsEarned,
      'timeSpent': timeSpent.inSeconds,
      'questionTypeStats': questionTypeStats.map((key, value) => MapEntry(key.toString(), value)),
      'questionResults': questionResults.map((result) => result.toMap()).toList(),
      'completedAt': Timestamp.fromDate(completedAt),
      'hintsUsed': hintsUsed,
      'isPerfectScore': isPerfectScore,
    };
  }

  factory EnhancedQuizResult.fromMap(Map<String, dynamic> map) {
    return EnhancedQuizResult(
      lessonId: map['lessonId'] ?? '',
      userId: map['userId'] ?? '',
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      xpEarned: map['xpEarned'] ?? 0,
      gemsEarned: map['gemsEarned'] ?? 0,
      timeSpent: Duration(seconds: map['timeSpent'] ?? 0),
      questionTypeStats: _parseQuestionTypeStats(map['questionTypeStats']),
      questionResults: (map['questionResults'] as List<dynamic>?)
          ?.map((result) => QuestionResult.fromMap(result))
          .toList() ?? [],
      completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hintsUsed: map['hintsUsed'] ?? 0,
      isPerfectScore: map['isPerfectScore'] ?? false,
    );
  }

  static Map<QuestionType, int> _parseQuestionTypeStats(dynamic stats) {
    if (stats == null) return {};
    
    Map<QuestionType, int> result = {};
    (stats as Map<String, dynamic>).forEach((key, value) {
      QuestionType? type = QuizQuestionModel._parseQuestionType(key);
      result[type] = value as int;
    });
    return result;
  }
}

class QuestionResult {
  final String questionId;
  final QuestionType type;
  final bool isCorrect;
  final dynamic userAnswer; // يمكن أن يكون String, int, List, etc
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
    this.hintsUsed = 0,
    this.attempts = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'type': type.toString(),
      'isCorrect': isCorrect,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'timeSpent': timeSpent.inSeconds,
      'hintsUsed': hintsUsed,
      'attempts': attempts,
    };
  }

  factory QuestionResult.fromMap(Map<String, dynamic> map) {
    return QuestionResult(
      questionId: map['questionId'] ?? '',
      type: QuizQuestionModel._parseQuestionType(map['type']),
      isCorrect: map['isCorrect'] ?? false,
      userAnswer: map['userAnswer'],
      correctAnswer: map['correctAnswer'],
      timeSpent: Duration(seconds: map['timeSpent'] ?? 0),
      hintsUsed: map['hintsUsed'] ?? 0,
      attempts: map['attempts'] ?? 1,
    );
  }
}
