import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/lesson_model.dart';

/// خدمة إدارة المكافآت - المصدر الوحيد لحساب وتوزيع XP والجواهر
class RewardService {
  static const String _completedQuizzesKey = 'completed_quizzes_secure';
  static const String _shareRewardKey = 'share_reward_claimed';
  static const String _lastShareKey = 'last_share_timestamp';
  
  /// الحصول على مكافآت الدرس من JSON فقط
  static RewardInfo getLessonRewards(LessonModel lesson, int quizScore) {
    // استخدام القيم من JSON كما هي
    int baseXP = lesson.xpReward;
    int baseGems = lesson.gemsReward;
    
    // مكافأة إضافية بناءً على الأداء (من JSON أيضاً)
    double multiplier = 1.0;
    if (quizScore >= 95) {
      multiplier = 1.5; // 50% إضافية للأداء الممتاز
    } else if (quizScore >= 85) {
      multiplier = 1.25; // 25% إضافية للأداء الجيد
    } else if (quizScore >= 70) {
      multiplier = 1.0; // المكافأة الأساسية للنجاح
    } else {
      multiplier = 0.0; // لا مكافأة للرسوب
    }
    
    return RewardInfo(
      xp: (baseXP * multiplier).round(),
      gems: (baseGems * multiplier).round(),
      source: 'lesson_completion',
      lessonId: lesson.id,
      score: quizScore,
    );
  }
  
  /// التحقق من إكمال الاختبار مسبقاً
  static Future<bool> isQuizCompleted(String lessonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedQuizzes = await _getSecureCompletedQuizzes();
      
      // إنشاء مفتاح فريد للمستخدم والدرس
      final quizKey = _generateQuizKey(userId, lessonId);
      return completedQuizzes.contains(quizKey);
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
  
  /// التحقق من إمكانية الحصول على مكافأة المشاركة
  static Future<bool> canClaimShareReward(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final claimed = prefs.getBool('${_shareRewardKey}_$userId') ?? false;
      
      if (claimed) {
        // التحقق من آخر مشاركة (يمكن المشاركة مرة واحدة كل 24 ساعة)
        final lastShareStr = prefs.getString('${_lastShareKey}_$userId');
        if (lastShareStr != null) {
          final lastShare = DateTime.parse(lastShareStr);
          final now = DateTime.now();
          final difference = now.difference(lastShare).inHours;
          
          return difference >= 24; // يمكن المشاركة مرة كل 24 ساعة
        }
      }
      
      return !claimed;
    } catch (e) {
      print('خطأ في التحقق من مكافأة المشاركة: $e');
      return false;
    }
  }
  
  /// تسجيل مكافأة المشاركة
  static Future<RewardInfo?> claimShareReward(String userId, bool actuallyShared) async {
    try {
      // التحقق من المشاركة الفعلية
      if (!actuallyShared) {
        return null;
      }
      
      final canClaim = await canClaimShareReward(userId);
      if (!canClaim) {
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_shareRewardKey}_$userId', true);
      await prefs.setString('${_lastShareKey}_$userId', DateTime.now().toIso8601String());
      
      return RewardInfo(
        xp: 0,
        gems: 50,
        source: 'app_share',
        lessonId: null,
        score: null,
      );
    } catch (e) {
      print('خطأ في تسجيل مكافأة المشاركة: $e');
      return null;
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
      await prefs.remove('${_shareRewardKey}_$userId');
      await prefs.remove('${_lastShareKey}_$userId');
      
      // إزالة تفاصيل الاختبارات
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('quiz_') && (key.contains('_score') || key.contains('_timestamp'))) {
          await prefs.remove(key);
        }
      }
      
      print('تم إعادة تعيين جميع المكافآت للمستخدم: $userId');
    } catch (e) {
      print('خطأ في إعادة تعيين المكافآت: $e');
    }
  }
}

/// معلومات المكافأة
class RewardInfo {
  final int xp;
  final int gems;
  final String source;
  final String? lessonId;
  final int? score;
  
  RewardInfo({
    required this.xp,
    required this.gems,
    required this.source,
    this.lessonId,
    this.score,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'gems': gems,
      'source': source,
      'lessonId': lessonId,
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'RewardInfo(xp: $xp, gems: $gems, source: $source, lessonId: $lessonId, score: $score)';
  }
}
