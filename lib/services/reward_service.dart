import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/lesson_model.dart';
import '../services/statistics_service.dart';

/// خدمة إدارة المكافآت - المصدر الوحيد لحساب وتوزيع XP والجواهر
/// تم إزالة ميزة المشاركة بالكامل
class RewardService {
  static const String _completedQuizzesKey = 'completed_quizzes_secure';
  
  /// الحصول على مكافآت الدرس من JSON مع دعم نظام إعادة المحاولة
  static Future<RewardInfo> getLessonRewards(
    LessonModel lesson, 
    int quizScore, 
    String userId,
    bool isFirstPass,
  ) async {
    // استخدام القيم من JSON كما هي
    int baseXP = lesson.xpReward;
    int baseGems = lesson.gemsReward;
    
    // مكافأة إضافية بناءً على الأداء (من JSON أيضاً)
    double performanceMultiplier = 1.0;
    if (quizScore >= 95) {
      performanceMultiplier = 1.5; // 50% إضافية للأداء الممتاز
    } else if (quizScore >= 85) {
      performanceMultiplier = 1.25; // 25% إضافية للأداء الجيد
    } else if (quizScore >= 70) {
      performanceMultiplier = 1.0; // المكافأة الأساسية للنجاح
    } else {
      performanceMultiplier = 0.0; // لا مكافأة للرسوب
    }

    // تطبيق نظام تقليل المكافآت لإعادة المحاولة بعد النجاح
    double retakeMultiplier = 1.0;
    if (!isFirstPass && quizScore >= 70) {
      retakeMultiplier = await StatisticsService.calculateRetakeMultiplier(lesson.id, userId);
    }

    final finalXP = (baseXP * performanceMultiplier * retakeMultiplier).round();
    final finalGems = (baseGems * performanceMultiplier * retakeMultiplier).round();
    
    return RewardInfo(
      xp: finalXP,
      gems: finalGems,
      source: isFirstPass ? 'lesson_completion' : 'lesson_retake',
      lessonId: lesson.id,
      score: quizScore,
      isFirstPass: isFirstPass,
      retakeMultiplier: retakeMultiplier,
    );
  }
  
  /// التحقق من إكمال الاختبار مسبقاً
  static Future<bool> isQuizCompleted(String lessonId, String userId) async {
    try {
      final attempts = await StatisticsService.getAttempts(lessonId, userId);
      return attempts.any((attempt) => attempt.isPassed);
    } catch (e) {
      print('خطأ في التحقق من إكمال الاختبار: $e');
      return false;
    }
  }
  
  /// تسجيل إكمال الاختبار بشكل آمن
  static Future<void> markQuizCompleted(String lessonId, String userId, int score) async {
    try {
      final quizKey = _generateQuizKey(userId, lessonId);
      final completedQuizzes = await _getSecureCompletedQuizzes();
      
      if (!completedQuizzes.contains(quizKey)) {
        completedQuizzes.add(quizKey);
        await _saveSecureCompletedQuizzes(completedQuizzes);
        
        // حفظ تفاصيل إضافية للتحقق
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('quiz_${quizKey}_score', score.toString());
        await prefs.setString('quiz_${quizKey}_timestamp', DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('خطأ في تسجيل إكمال الاختبار: $e');
    }
  }
  
  /// إنشاء مفتاح آمن للاختبار
  static String _generateQuizKey(String userId, String lessonId) {
    final input = '$userId:$lessonId:${DateTime.now().toIso8601String().substring(0, 10)}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // استخدام أول 16 حرف فقط
  }
  
  /// الحصول على قائمة الاختبارات المكتملة بشكل آمن
  static Future<List<String>> _getSecureCompletedQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = prefs.getString(_completedQuizzesKey);
      
      if (encryptedData == null) {
        return [];
      }
      
      // فك التشفير البسيط (يمكن تحسينه لاحقاً)
      final decodedData = utf8.decode(base64.decode(encryptedData));
      final List<dynamic> jsonList = json.decode(decodedData);
      
      return jsonList.cast<String>();
    } catch (e) {
      print('خطأ في قراءة الاختبارات المكتملة: $e');
      return [];
    }
  }
  
  /// حفظ قائمة الاختبارات المكتملة بشكل آمن
  static Future<void> _saveSecureCompletedQuizzes(List<String> completedQuizzes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تشفير بسيط (يمكن تحسينه لاحقاً)
      final jsonData = json.encode(completedQuizzes);
      final encodedData = base64.encode(utf8.encode(jsonData));
      
      await prefs.setString(_completedQuizzesKey, encodedData);
    } catch (e) {
      print('خطأ في حفظ الاختبارات المكتملة: $e');
    }
  }
  
  /// التحقق من صحة النتيجة
  static bool isValidScore(int score, int totalQuestions) {
    return score >= 0 && score <= 100 && totalQuestions > 0;
  }
  
  /// حساب النتيجة بناءً على الإجابات الصحيحة
  static int calculateScore(int correctAnswers, int totalQuestions) {
    if (totalQuestions <= 0) return 0;
    return ((correctAnswers / totalQuestions) * 100).round();
  }
  
  /// إعادة تعيين جميع المكافآت (للاختبار فقط)
  static Future<void> resetAllRewards(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // إزالة جميع البيانات المتعلقة بالمكافآت
      await prefs.remove(_completedQuizzesKey);
      
      // إزالة تفاصيل الاختبارات
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('quiz_') && (key.contains('_score') || key.contains('_timestamp'))) {
          await prefs.remove(key);
        }
      }
      
      // إعادة تعيين الإحصائيات
      await StatisticsService.resetAllStatistics(userId);
      
      print('تم إعادة تعيين جميع المكافآت للمستخدم: $userId');
    } catch (e) {
      print('خطأ في إعادة تعيين المكافآت: $e');
    }
  }
}

/// معلومات المكافأة المحدثة
class RewardInfo {
  final int xp;
  final int gems;
  final String source;
  final String? lessonId;
  final int? score;
  final bool isFirstPass;
  final double retakeMultiplier;
  
  RewardInfo({
    required this.xp,
    required this.gems,
    required this.source,
    this.lessonId,
    this.score,
    this.isFirstPass = true,
    this.retakeMultiplier = 1.0,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'gems': gems,
      'source': source,
      'lessonId': lessonId,
      'score': score,
      'isFirstPass': isFirstPass,
      'retakeMultiplier': retakeMultiplier,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'RewardInfo(xp: $xp, gems: $gems, source: $source, lessonId: $lessonId, score: $score, isFirstPass: $isFirstPass, retakeMultiplier: $retakeMultiplier)';
  }
}
