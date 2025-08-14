import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/lesson_model.dart';

/// خدمة إدارة المكافآت - المصدر الوحيد لحساب وتوزيع XP والجواهر
/// يتضمن نظام اضمحلال الخبرة للمحاولات المتكررة بعد النجاح
class RewardService {
  static const String _completedQuizzesKey = 'completed_quizzes_secure';
  static const String _retakeAttemptsKey = 'retake_attempts';
  static const String _lastPassTimestampKey = 'last_pass_timestamp';
  
  /// الحصول على مكافآت الدرس مع نظام تقليل المكافآت للمحاولات المتكررة
  /// نظام اضمحلال الخبرة:
  /// - المحاولة الأولى بعد النجاح: 30% من المكافأة الأساسية
  /// - المحاولة الثانية: 20%
  /// - المحاولة الثالثة: 10%
  /// - المحاولة الرابعة فما فوق: 0%
  /// - إعادة تعيين كل 24 ساعة من آخر نجاح
  static Future<RewardInfo> getLessonRewardsWithRetakeLogic(
    LessonModel lesson, 
    int quizScore, 
    String userId,
    {bool isRetakeAfterPass = false}
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

    double retakeMultiplier = 1.0;
    if (isRetakeAfterPass && quizScore >= 70) {
      retakeMultiplier = await _calculateRetakeMultiplier(lesson.id, userId);
      print('🔄 محاولة إعادة بعد النجاح - مضاعف التقليل: ${(retakeMultiplier * 100).round()}%');
    }
    
    final finalXP = (baseXP * performanceMultiplier * retakeMultiplier).round();
    final finalGems = (baseGems * performanceMultiplier * retakeMultiplier).round();
    
    return RewardInfo(
      xp: finalXP,
      gems: finalGems,
      source: isRetakeAfterPass ? 'lesson_retake' : 'lesson_completion',
      lessonId: lesson.id,
      score: quizScore,
      retakeMultiplier: retakeMultiplier,
      isRetake: isRetakeAfterPass,
    );
  }

  /// الحصول على مكافآت الدرس من JSON فقط (للتوافق مع الكود القديم)
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

  /// حساب مضاعف تقليل المكافآت للمحاولات المتكررة (نظام اضمحلال الخبرة)
  static Future<double> _calculateRetakeMultiplier(String lessonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final retakeKey = '${_retakeAttemptsKey}_${userId}_$lessonId';
      final lastPassKey = '${_lastPassTimestampKey}_${userId}_$lessonId';
      
      // الحصول على آخر وقت نجاح
      final lastPassStr = prefs.getString(lastPassKey);
      if (lastPassStr == null) {
        // لا يوجد نجاح سابق، هذه المحاولة الأولى
        return 1.0;
      }
      
      final lastPassTime = DateTime.parse(lastPassStr);
      final now = DateTime.now();
      final hoursSinceLastPass = now.difference(lastPassTime).inHours;
      
      // إعادة تعيين العداد إذا مر أكثر من 24 ساعة (نظام اضمحلال الخبرة)
      if (hoursSinceLastPass >= 24) {
        await prefs.remove(retakeKey);
        print('🔄 تم إعادة تعيين عداد المحاولات بعد 24 ساعة (اضمحلال الخبرة)');
        return 0.3; // البداية من 30% بعد إعادة التعيين
      }
      
      // الحصول على عدد المحاولات الحالي
      final currentAttempts = prefs.getInt(retakeKey) ?? 0;
      
      // حساب المضاعف بناءً على عدد المحاولات (نظام اضمحلال الخبرة)
      switch (currentAttempts) {
        case 0:
          return 0.3; // 30% للمحاولة الأولى بعد النجاح
        case 1:
          return 0.2; // 20% للمحاولة الثانية
        case 2:
          return 0.1; // 10% للمحاولة الثالثة
        default:
          return 0.0; // 0% للمحاولة الرابعة فما فوق (اضمحلال كامل)
      }
    } catch (e) {
      print('❌ خطأ في حساب مضاعف إعادة المحاولة: $e');
      return 1.0; // إرجاع المضاعف الكامل في حالة الخطأ
    }
  }

  /// تسجيل محاولة إعادة بعد النجاح
  static Future<void> recordRetakeAttempt(String lessonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final retakeKey = '${_retakeAttemptsKey}_${userId}_$lessonId';
      
      final currentAttempts = prefs.getInt(retakeKey) ?? 0;
      await prefs.setInt(retakeKey, currentAttempts + 1);
      
      print('📊 تم تسجيل محاولة إعادة رقم ${currentAttempts + 1} للدرس $lessonId');
    } catch (e) {
      print('❌ خطأ في تسجيل محاولة الإعادة: $e');
    }
  }

  /// تسجيل وقت النجاح الأول
  static Future<void> recordFirstPassTime(String lessonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPassKey = '${_lastPassTimestampKey}_${userId}_$lessonId';
      
      // تسجيل الوقت فقط إذا لم يكن موجوداً من قبل (النجاح الأول)
      if (!prefs.containsKey(lastPassKey)) {
        await prefs.setString(lastPassKey, DateTime.now().toIso8601String());
        print('✅ تم تسجيل وقت النجاح الأول للدرس $lessonId');
      }
    } catch (e) {
      print('❌ خطأ في تسجيل وقت النجاح: $e');
    }
  }

  /// التحقق من كون هذه محاولة إعادة بعد النجاح
  static Future<bool> isRetakeAfterPass(String lessonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPassKey = '${_lastPassTimestampKey}_${userId}_$lessonId';
      
      return prefs.containsKey(lastPassKey);
    } catch (e) {
      print('❌ خطأ في التحقق من حالة الإعادة: $e');
      return false;
    }
  }

  /// الحصول على إحصائيات إعادة المحاولة
  static Future<RetakeStats> getRetakeStats(String lessonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final retakeKey = '${_retakeAttemptsKey}_${userId}_$lessonId';
      final lastPassKey = '${_lastPassTimestampKey}_${userId}_$lessonId';
      
      final retakeAttempts = prefs.getInt(retakeKey) ?? 0;
      final lastPassStr = prefs.getString(lastPassKey);
      
      DateTime? lastPassTime;
      int? hoursUntilReset;
      
      if (lastPassStr != null) {
        lastPassTime = DateTime.parse(lastPassStr);
        final hoursSinceLastPass = DateTime.now().difference(lastPassTime).inHours;
        hoursUntilReset = hoursSinceLastPass >= 24 ? 0 : (24 - hoursSinceLastPass);
      }
      
      // حساب المضاعف التالي
      double nextMultiplier = 1.0;
      if (lastPassTime != null) {
        if (hoursUntilReset == 0) {
          nextMultiplier = 0.3; // إعادة تعيين
        } else {
          switch (retakeAttempts) {
            case 0:
              nextMultiplier = 0.3;
              break;
            case 1:
              nextMultiplier = 0.2;
              break;
            case 2:
              nextMultiplier = 0.1;
              break;
            default:
              nextMultiplier = 0.0;
          }
        }
      }
      
      return RetakeStats(
        retakeAttempts: retakeAttempts,
        lastPassTime: lastPassTime,
        hoursUntilReset: hoursUntilReset,
        nextRewardMultiplier: nextMultiplier,
        hasPassedBefore: lastPassTime != null,
      );
    } catch (e) {
      print('❌ خطأ في الحصول على إحصائيات الإعادة: $e');
      return RetakeStats(
        retakeAttempts: 0,
        lastPassTime: null,
        hoursUntilReset: null,
        nextRewardMultiplier: 1.0,
        hasPassedBefore: false,
      );
    }
  }
  
  /// التحقق من إكمال الاختبار مسبقاً
  static Future<bool> isQuizCompleted(String lessonId, String userId) async {
    try {
      return await isRetakeAfterPass(lessonId, userId);
    } catch (e) {
      print('خطأ في التحقق من إكمال الاختبار: $e');
      return false;
    }
  }
  
  /// تسجيل إكمال الاختبار بشكل آمن
  static Future<void> markQuizCompleted(String lessonId, String userId, int score) async {
    try {
      final isRetakeAfterPass = await RewardService.isRetakeAfterPass(lessonId, userId);
      
      if (!isRetakeAfterPass) {
        // تسجيل وقت النجاح الأول
        await recordFirstPassTime(lessonId, userId);
        print('✅ تم تسجيل إكمال الاختبار للمرة الأولى: $lessonId');
      } else {
        print('🔄 محاولة إعادة - لا يتم تسجيل إكمال جديد');
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
      
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('quiz_') && (key.contains('_score') || key.contains('_timestamp'))) {
          await prefs.remove(key);
        }
        if (key.contains(_retakeAttemptsKey) || key.contains(_lastPassTimestampKey)) {
          await prefs.remove(key);
        }
        if (key.contains('share_reward') || 
            key.contains('last_share') || 
            key.contains('completed_quizzes_old') ||
            key.contains('_level_') ||
            key.startsWith('old_') ||
            key.contains('legacy_') ||
            key.contains('deprecated_')) {
          await prefs.remove(key);
        }
      }
      
      print('تم إعادة تعيين جميع المكافآت وتنظيف البيانات القديمة للمستخدم: $userId');
    } catch (e) {
      print('خطأ في إعادة تعيين المكافآت: $e');
    }
  }

  /// تنظيف شامل للبيانات القديمة والمتداخلة
  static Future<void> cleanupLegacyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int cleanedCount = 0;
      
      for (String key in keys) {
        // تنظيف البيانات المتعلقة بالمشاركة
        if (key.contains('share') || 
            key.contains('sharing') ||
            key.contains('shared')) {
          await prefs.remove(key);
          cleanedCount++;
          continue;
        }
        
        // تنظيف البيانات القديمة
        if (key.contains('_level_') ||
            key.startsWith('old_') ||
            key.contains('legacy_') ||
            key.contains('deprecated_') ||
            key.endsWith('_old') ||
            key.contains('backup_')) {
          await prefs.remove(key);
          cleanedCount++;
          continue;
        }
        
        // تنظيف البيانات المكررة
        if (key.contains('duplicate_') ||
            key.contains('_copy') ||
            key.contains('temp_')) {
          await prefs.remove(key);
          cleanedCount++;
          continue;
        }
      }
      
      print('✅ تم تنظيف $cleanedCount مفتاح من البيانات القديمة والمتداخلة');
    } catch (e) {
      print('❌ خطأ في تنظيف البيانات القديمة: $e');
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
  final double? retakeMultiplier;
  final bool? isRetake;
  
  RewardInfo({
    required this.xp,
    required this.gems,
    required this.source,
    this.lessonId,
    this.score,
    this.retakeMultiplier,
    this.isRetake,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'gems': gems,
      'source': source,
      'lessonId': lessonId,
      'score': score,
      'retakeMultiplier': retakeMultiplier,
      'isRetake': isRetake,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'RewardInfo(xp: $xp, gems: $gems, source: $source, lessonId: $lessonId, score: $score, retakeMultiplier: $retakeMultiplier, isRetake: $isRetake)';
  }
}

/// إحصائيات إعادة المحاولة
class RetakeStats {
  final int retakeAttempts;
  final DateTime? lastPassTime;
  final int? hoursUntilReset;
  final double nextRewardMultiplier;
  final bool hasPassedBefore;

  RetakeStats({
    required this.retakeAttempts,
    required this.lastPassTime,
    required this.hoursUntilReset,
    required this.nextRewardMultiplier,
    required this.hasPassedBefore,
  });

  String get nextRewardPercentage => '${(nextRewardMultiplier * 100).round()}%';
  
  bool get canGetFullReward => nextRewardMultiplier >= 1.0;
  bool get willGetReducedReward => nextRewardMultiplier > 0.0 && nextRewardMultiplier < 1.0;
  bool get willGetNoReward => nextRewardMultiplier == 0.0;
  
  String get statusMessage {
    if (!hasPassedBefore) {
      return 'المحاولة الأولى - مكافأة كاملة';
    } else if (hoursUntilReset != null && hoursUntilReset! > 0) {
      if (willGetNoReward) {
        return 'لا توجد مكافأة - انتظر ${hoursUntilReset}h لإعادة التعيين';
      } else {
        return 'مكافأة مقللة ${nextRewardPercentage} - إعادة تعيين خلال ${hoursUntilReset}h';
      }
    } else {
      return 'تم إعادة التعيين - مكافأة ${nextRewardPercentage}';
    }
  }
}
