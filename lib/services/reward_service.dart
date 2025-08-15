import '../models/lesson_model.dart';
import '../models/decay_tracker_model.dart';

class RewardService {
  // حساب مكافآت XP بناءً على الأداء مع الاضمحلال
  static int calculateXPReward(LessonModel lesson, double scorePercentage, {DecayTrackerModel? decayTracker}) {
    int baseXP = lesson.xpReward;
    
    // فحص النجاح أولاً
    if (scorePercentage < 70) {
      return 0; // لا مكافآت للرسوب
    }
    
    double decayMultiplier = 1.0;
    if (decayTracker != null) {
      decayMultiplier = decayTracker.getDecayMultiplier();
    }
    
    // حساب المكافأة الأساسية مع الاضمحلال
    int finalXP = (baseXP * decayMultiplier).round();
    
    // تطبيق مكافآت الأداء على النتيجة النهائية
    if (scorePercentage >= 95) {
      finalXP = (finalXP * 1.5).round(); // مكافأة ممتازة
    } else if (scorePercentage >= 85) {
      finalXP = (finalXP * 1.25).round(); // مكافأة جيدة جداً
    }
    // النجاح العادي (70-84%) يحصل على المكافأة الأساسية مع الاضمحلال
    
    return finalXP;
  }

  // حساب مكافآت الجواهر بناءً على الأداء مع الاضمحلال
  static int calculateGemsReward(LessonModel lesson, double scorePercentage, {DecayTrackerModel? decayTracker}) {
    int baseGems = lesson.gemsReward;
    
    // لا جواهر في الإعادات (إذا كان retakeCount > 0)
    if (decayTracker != null && decayTracker.retakeCount > 0) {
      return 0;
    }
    
    // حساب المكافأة الأساسية بناءً على الأداء (للمرة الأولى فقط)
    if (scorePercentage >= 95) {
      return (baseGems * 1.5).round(); // مكافأة ممتازة
    } else if (scorePercentage >= 85) {
      return (baseGems * 1.25).round(); // مكافأة جيدة جداً
    } else if (scorePercentage >= 70) {
      return baseGems; // مكافأة أساسية للنجاح
    } else {
      return 0; // لا مكافآت للرسوب
    }
  }

  // حساب المكافآت الإجمالية مع نظام الاضمحلال
  static Map<String, int> calculateTotalRewards(LessonModel lesson, double scorePercentage, {DecayTrackerModel? decayTracker}) {
    return {
      'xp': calculateXPReward(lesson, scorePercentage, decayTracker: decayTracker),
      'gems': calculateGemsReward(lesson, scorePercentage, decayTracker: decayTracker),
    };
  }

  // تحديد مستوى الأداء
  static String getPerformanceLevel(double scorePercentage) {
    if (scorePercentage >= 95) {
      return 'ممتاز';
    } else if (scorePercentage >= 85) {
      return 'جيد جداً';
    } else if (scorePercentage >= 70) {
      return 'جيد';
    } else {
      return 'يحتاج تحسين';
    }
  }

  // تحديد عدد النجوم بناءً على الأداء
  static int getStarsCount(double scorePercentage) {
    if (scorePercentage >= 95) {
      return 3;
    } else if (scorePercentage >= 85) {
      return 2;
    } else if (scorePercentage >= 70) {
      return 1;
    } else {
      return 0;
    }
  }

  // الحصول على معلومات الاضمحلال للعرض
  static Map<String, dynamic> getDecayInfo(DecayTrackerModel? decayTracker) {
    if (decayTracker == null) {
      return {
        'isFirstTime': true,
        'decayMultiplier': 1.0,
        'decayPercentage': 100,
        'retakeCount': 0,
        'canGetGems': true,
        'nextResetInfo': 'بعد إكمال الدرس لأول مرة',
      };
    }
    
    final decayMultiplier = decayTracker.getDecayMultiplier();
    final now = DateTime.now();
    final daysSinceLastRetake = now.difference(decayTracker.lastRetakeDate).inDays;
    
    String nextResetInfo;
    if (daysSinceLastRetake >= 1) {
      nextResetInfo = 'سيتم إعادة التأهيل إلى 30% في المحاولة التالية';
    } else {
      final hoursUntilReset = 24 - now.hour;
      nextResetInfo = 'إعادة التأهيل إلى 30% خلال $hoursUntilReset ساعة';
    }
    
    return {
      'isFirstTime': decayTracker.retakeCount == 0,
      'decayMultiplier': decayMultiplier,
      'decayPercentage': (decayMultiplier * 100).round(),
      'retakeCount': decayTracker.retakeCount,
      'canGetGems': decayTracker.retakeCount == 0,
      'daysSinceLastRetake': daysSinceLastRetake,
      'nextResetInfo': nextResetInfo,
    };
  }
}
